import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// How a [DioException] should be interpreted by callers.
///
/// Replaces the old collapse-everything-to-`null`/timeout behaviour: HTTP
/// status codes (400/401/403/404/503/504) stay distinguishable from plain
/// connection failures and from delay-probe timeouts.
enum MihomoErrorKind {
  /// Connection-level failure (DNS, refused, reset) with no HTTP response.
  connection,

  /// `receiveTimeout` / `connectionTimeout` etc. — no bytes in time.
  timeout,

  /// 400 — bad request (bad `timeout`/`expected`, bad body, …).
  badRequest,

  /// 401/403 — missing or wrong `secret`.
  auth,

  /// 404 — unknown proxy/group/provider/key.
  notFound,

  /// 503 — delay probe answered but the node is unreachable (`delay == 0`).
  unavailable,

  /// 504 — delay probe timed out inside the kernel.
  gatewayTimeout,

  /// Caller cancelled the request.
  cancelled,

  /// Certificate problems — never transient.
  badCertificate,

  /// Anything else (other 5xx, parse/transform errors, …).
  other,
}

/// Classifies [e] into a [MihomoErrorKind] without collapsing statuses.
MihomoErrorKind classifyDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.receiveTimeout:
      return MihomoErrorKind.timeout;
    case DioExceptionType.cancel:
      return MihomoErrorKind.cancelled;
    case DioExceptionType.badCertificate:
      return MihomoErrorKind.badCertificate;
    case DioExceptionType.connectionError:
      return MihomoErrorKind.connection;
    case DioExceptionType.badResponse:
      switch (e.response?.statusCode) {
        case 400:
          return MihomoErrorKind.badRequest;
        case 401:
        case 403:
          return MihomoErrorKind.auth;
        case 404:
          return MihomoErrorKind.notFound;
        case 503:
          return MihomoErrorKind.unavailable;
        case 504:
          return MihomoErrorKind.gatewayTimeout;
        default:
          return MihomoErrorKind.other;
      }
    case DioExceptionType.unknown:
      // Dio surfaces DNS/connection failures here on some versions when
      // there is no HTTP response; with a response those are real errors.
      return e.response == null
          ? MihomoErrorKind.connection
          : MihomoErrorKind.other;
  }
}

/// Whether [e] looks like a transient connection failure worth retrying
/// (timeouts, connection refused/reset, DNS) instead of an authoritative
/// error. Auth/bad-request/not-found and delay-probe 503/504 statuses are
/// authoritative and are never retried as "transient".
bool isTransientDioError(DioException e) {
  switch (classifyDioError(e)) {
    case MihomoErrorKind.connection:
    case MihomoErrorKind.timeout:
      return true;
    case MihomoErrorKind.badRequest:
    case MihomoErrorKind.auth:
    case MihomoErrorKind.notFound:
    case MihomoErrorKind.unavailable:
    case MihomoErrorKind.gatewayTimeout:
    case MihomoErrorKind.cancelled:
    case MihomoErrorKind.badCertificate:
    case MihomoErrorKind.other:
      return false;
  }
}

/// Runs [fn], retrying transient connection failures every [interval]
/// (default 0.5s) up to [attempts] times.
///
/// Non-transient [DioException]s are rethrown immediately. When transient
/// failures are *exhausted* the last [DioException] is rethrown as well —
/// it is never collapsed to `null`, so "controller down" stays
/// distinguishable from an empty response (audit E18). The nullable
/// return type is kept for source compatibility with existing callers
/// (`ProxySelection.load`, the info page), which already handle thrown
/// [DioException]s; see also [retryTransientOrThrow] (same behaviour,
/// non-nullable return).
Future<T?> retryTransient<T>(
  Future<T> Function() fn, {
  int attempts = 6,
  Duration interval = const Duration(milliseconds: 500),
}) => retryTransientOrThrow<T>(fn, attempts: attempts, interval: interval);

/// Like [retryTransient] but with a non-nullable return type. Classify the
/// caught error with [classifyDioError] to distinguish timeout / auth / 503 /
/// 504 / connection failures.
Future<T> retryTransientOrThrow<T>(
  Future<T> Function() fn, {
  int attempts = 6,
  Duration interval = const Duration(milliseconds: 500),
}) async {
  DioException? lastError;
  for (var i = 0; i < attempts; i++) {
    try {
      return await fn();
    } on DioException catch (e) {
      if (!isTransientDioError(e)) rethrow;
      lastError = e;
      if (i == attempts - 1) break;
      await Future.delayed(interval);
    }
  }
  // Attempts exhausted on transient failures: surface the real error.
  throw lastError!;
}

/// Encodes one URL path segment (proxy/group/provider/storage names are
/// free-form and may contain spaces, emoji or `/`).
String encodePathSegment(String segment) => Uri.encodeComponent(segment);

/// Resolves the effective controller secret.
///
/// Priority: explicit [token] (settings UI) > `--dart-define=MIHOMO_SECRET>`
/// > `.env` `secret` (development fallback only — `.env` is no longer
/// bundled in release assets). The placeholder `'***'` (shipped in the
/// example `.env`) is treated as empty, so it is never sent as a real
/// Bearer token. Returns `''` when no secret is configured; callers must
/// then omit the `Authorization` header entirely.
String resolveMihomoSecret({
  String? token,
  String? dartDefineSecret,
  String? dotenvSecret,
}) {
  for (final candidate in [token, dartDefineSecret, dotenvSecret]) {
    final value = candidate?.trim() ?? '';
    if (value.isNotEmpty && value != '***') return value;
  }
  return '';
}

/// Headers for a request: only sends `Authorization` when [secret] is a
/// real (non-placeholder, non-empty) secret.
Map<String, String> buildAuthHeaders(String secret) {
  final value = secret.trim();
  if (value.isEmpty || value == '***') return const <String, String>{};
  return {'Authorization': 'Bearer $value'};
}

/// Dart-define keys (release configuration; `.env` is dev-only).
const _dartHost = String.fromEnvironment('MIHOMO_HOST');
const _dartPort = String.fromEnvironment('MIHOMO_PORT');
const _dartSecret = String.fromEnvironment('MIHOMO_SECRET');

class MihomoAPI {
  late Dio _dio;
  late String baseUrl;

  MihomoAPI({String? baseUrl, String? secret, Dio? dio}) {
    if (dio != null) {
      _dio = dio;
      _dioInitialized = true;
    }
    _init(baseUrl, secret);
  }

  /// Shared Dio instance (mutated on [reconfigure] so connections are
  /// reused). Visible for testing/inspection only.
  Dio get dio => _dio;

  /// Re-point at a new controller (settings changed) without recreating
  /// the instance, so pages holding this API pick up the new endpoint.
  /// Empty values fall back to `--dart-define` values, then the `.env`
  /// host/port/secret (development only).
  void reconfigure({String? baseUrl, String? secret}) {
    _init(baseUrl, secret);
  }

  void _init(String? url, String? token) {
    // flutter_dotenv is load-once and async. `.env` is a dev-only,
    // optional fallback and is no longer a bundled pubspec asset, so on a
    // normal `flutter run` there may be no .env at all — `main()` loads
    // it with `isOptional: true`, and when dotenv was never initialized
    // (e.g. a test forgets `loadFromString`) we simply fall back to an
    // empty env (dart-define / explicit args / localhost:9091 defaults).
    // Do NOT assert `dotenv.isInitialized` here: that crashes debug runs
    // whenever .env is absent, which is the common case.
    final env = dotenv.isInitialized ? dotenv.env : const <String, String>{};
    final trimmed = url?.trim();
    final host = _dartHost.isNotEmpty
        ? _dartHost
        : (env['host']?.trim().isNotEmpty == true ? env['host']! : 'localhost');
    final port = _dartPort.isNotEmpty
        ? _dartPort
        : (env['port']?.trim().isNotEmpty == true ? env['port']! : '9091');
    baseUrl = (trimmed != null && trimmed.isNotEmpty)
        ? trimmed.replaceAll(RegExp(r'/+$'), '')
        : 'http://$host:$port';
    final secret = resolveMihomoSecret(
      token: token,
      dartDefineSecret: _dartSecret,
      dotenvSecret: env['secret'],
    );

    if (!(_dioInitialized)) {
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      _dioInitialized = true;
    }
    _dio.options
      ..baseUrl = baseUrl
      ..headers = buildAuthHeaders(secret)
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 30);
  }

  bool _dioInitialized = false;

  // ── Version ──────────────────────────────────────────────────────────

  /// `GET /version`
  Future<Response> getVersion() => _dio.get('/version');

  // ── Proxies ──────────────────────────────────────────────────────────

  /// `GET /proxies`
  Future<Response> getProxies() => _dio.get('/proxies');

  /// `GET /proxies/<name>`
  Future<Response> getProxy(String name) =>
      _dio.get('/proxies/${encodePathSegment(name)}');

  /// `PUT /proxies/<name>` — select a proxy within a policy group.
  Future<Response> selectProxy(String name, {required String proxyName}) => _dio
      .put('/proxies/${encodePathSegment(name)}', data: {'name': proxyName});

  /// `DELETE /proxies/<name>` — clear fixed selection (except Selector type).
  Future<Response> clearProxySelection(String name) =>
      _dio.delete('/proxies/${encodePathSegment(name)}');

  /// `GET /<prefix>/<name>/delay` — probe the delay of a proxy or group.
  Future<Response> _delay(
    String prefix,
    String name, {
    required String url,
    required int timeout,
    String? expected,
  }) {
    final params = <String, dynamic>{'url': url, 'timeout': timeout};
    if (expected != null) params['expected'] = expected;
    return _dio.get(
      '$prefix/${encodePathSegment(name)}/delay',
      queryParameters: params,
    );
  }

  /// `GET /proxies/<name>/delay`
  Future<Response> testProxyDelay(
    String name, {
    required String url,
    int timeout = 5000,
    String? expected,
  }) =>
      _delay('/proxies', name, url: url, timeout: timeout, expected: expected);

  // ── Policy Groups ────────────────────────────────────────────────────

  /// `GET /group`
  Future<Response> getGroups() => _dio.get('/group');

  /// `GET /group/<name>`
  Future<Response> getGroup(String name) =>
      _dio.get('/group/${encodePathSegment(name)}');

  /// `GET /group/<name>/delay`
  Future<Response> testGroupDelay(
    String name, {
    required String url,
    int timeout = 5000,
    String? expected,
  }) => _delay('/group', name, url: url, timeout: timeout, expected: expected);

  // ── Running Configuration ────────────────────────────────────────────

  /// `GET /configs`
  Future<Response> getConfigs() => _dio.get('/configs');

  /// `PUT /configs` — reload basic configuration.
  ///
  /// The kernel decodes a `{path, payload}` JSON body
  /// (`hub/route/configs.go:updateConfigs`); an empty body is a 400.
  /// `path`/`payload` default to the documented `""` reload values.
  Future<Response> reloadConfigs({
    bool force = false,
    String path = '',
    String payload = '',
  }) => _dio.put(
    '/configs',
    queryParameters: {'force': force},
    data: {'path': path, 'payload': payload},
  );

  /// `PATCH /configs` — update a single configuration field.
  Future<Response> updateConfig(Map<String, dynamic> config) =>
      _dio.patch('/configs', data: config);

  /// `POST /configs/geo` — update the GEO database.
  Future<Response> updateGeoDatabase({
    required String path,
    required String payload,
  }) => _dio.post('/configs/geo', data: {'path': path, 'payload': payload});

  // ── Cache ────────────────────────────────────────────────────────────

  /// `POST /cache/fakeip/flush`
  Future<Response> flushFakeIPCache() => _dio.post('/cache/fakeip/flush');

  /// `POST /cache/dns/flush`
  Future<Response> flushDNSCache() => _dio.post('/cache/dns/flush');

  // ── Connections ──────────────────────────────────────────────────────

  /// `GET /connections`
  Future<Response> getConnections({int interval = 1000}) =>
      _dio.get('/connections', queryParameters: {'interval': interval});

  /// `DELETE /connections` — close all connections.
  Future<Response> closeAllConnections() => _dio.delete('/connections');

  /// `DELETE /connections/<id>` — close a specific connection.
  Future<Response> closeConnection(String id) =>
      _dio.delete('/connections/${encodePathSegment(id)}');

  // ── Rules ────────────────────────────────────────────────────────────

  /// `GET /rules`
  Future<Response> getRules() => _dio.get('/rules');

  /// `PATCH /rules/disable` — disable rules by index.
  Future<Response> disableRules(Map<String, bool> ruleStates) =>
      _dio.patch('/rules/disable', data: ruleStates);

  // ── Proxy Providers ──────────────────────────────────────────────────

  /// `GET /providers/proxies`
  Future<Response> getProxyProviders() => _dio.get('/providers/proxies');

  /// `GET /providers/proxies/<name>`
  Future<Response> getProxyProvider(String name) =>
      _dio.get('/providers/proxies/${encodePathSegment(name)}');

  /// `PUT /providers/proxies/<name>`
  Future<Response> updateProxyProvider(String name) =>
      _dio.put('/providers/proxies/${encodePathSegment(name)}');

  /// `GET /providers/proxies/<name>/healthcheck`
  Future<Response> healthCheckProxyProvider(String name) =>
      _dio.get('/providers/proxies/${encodePathSegment(name)}/healthcheck');

  /// `GET /providers/proxies/<name>/proxies/<proxy_name>`
  Future<Response> getProxyFromProvider(
    String providerName,
    String proxyName,
  ) => _dio.get(
    '/providers/proxies/${encodePathSegment(providerName)}/proxies/${encodePathSegment(proxyName)}',
  );

  /// `GET /providers/proxies/<name>/proxies/<proxy_name>/healthcheck`
  Future<Response> healthCheckProxyFromProvider(
    String providerName,
    String proxyName, {
    String? url,
    int timeout = 5000,
  }) {
    final params = <String, dynamic>{'timeout': timeout};
    if (url != null) params['url'] = url;
    return _dio.get(
      '/providers/proxies/${encodePathSegment(providerName)}/proxies/${encodePathSegment(proxyName)}/healthcheck',
      queryParameters: params,
    );
  }

  // ── Rule Providers ───────────────────────────────────────────────────

  /// `GET /providers/rules`
  Future<Response> getRuleProviders() => _dio.get('/providers/rules');

  /// `PUT /providers/rules/<name>`
  Future<Response> updateRuleProvider(String name) =>
      _dio.put('/providers/rules/${encodePathSegment(name)}');

  // ── Traffic / Memory / Logs (streaming) ─────────────────────────────
  //
  // `/traffic`, `/memory` and `/logs` are *streaming* endpoints in mihomo:
  // the kernel pushes one JSON object per line (per second / per log
  // event) over a chunked, never-ending response. There is no total
  // timeout — Dio's `receiveTimeout` is only an inactivity timeout, so a
  // one-shot `GET` here does not "time out after 30s", it hangs until
  // the caller gives up and then yields at best one truncated chunk.
  //
  // Prefer the `stream*` methods below (real `ResponseType.stream`
  // consumption, no receive timeout) for live data. The one-shot methods
  // are kept only as explicitly-bounded *snapshots* for callers that
  // must not hold a stream open: they use a short inactivity timeout
  // and the truncated body must be parsed with
  // `parseJsonLines` (see `lib/info/mihomo_info.dart`), never cast to
  // a single `Map`. Snapshot failures surface as real [DioException]s
  // (see [classifyDioError]) — they are not silently `null`.

  /// Options for a one-shot streaming-endpoint snapshot.
  Options _snapshotOptions() => Options(
    responseType: ResponseType.plain,
    receiveTimeout: const Duration(seconds: 5),
  );

  /// `GET /traffic` — one-shot snapshot only; see the streaming note
  /// above. Use [streamTraffic] for live ticks.
  Future<Response> getTraffic() =>
      _dio.get('/traffic', options: _snapshotOptions());

  /// `GET /memory` — one-shot snapshot only; see [getTraffic].
  Future<Response> getMemory() =>
      _dio.get('/memory', options: _snapshotOptions());

  /// `GET /logs` — one-shot snapshot only; see [getTraffic].
  Future<Response> getLogs({
    String level = 'info',
    String format = 'standard',
  }) => _dio.get(
    '/logs',
    queryParameters: {'level': level, 'format': format},
    options: _snapshotOptions(),
  );

  /// Live `GET /traffic` stream: one map per pushed tick.
  Stream<Map<String, dynamic>> streamTraffic() => _streamJsonLines('/traffic');

  /// Live `GET /memory` stream: one map per pushed tick.
  Stream<Map<String, dynamic>> streamMemory() => _streamJsonLines('/memory');

  /// Live `GET /logs` stream: one map per log line.
  Stream<Map<String, dynamic>> streamLogs({
    String level = 'info',
    String format = 'standard',
  }) => _streamJsonLines(
    '/logs',
    queryParameters: {'level': level, 'format': format},
  );

  Stream<Map<String, dynamic>> _streamJsonLines(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async* {
    final response = await _dio.get<ResponseBody>(
      path,
      queryParameters: queryParameters,
      options: Options(
        responseType: ResponseType.stream,
        // Streaming responses never complete; no inactivity timeout.
        receiveTimeout: Duration.zero,
      ),
    );
    yield* utf8.decoder
        .bind(response.data!.stream)
        .transform(const LineSplitter())
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final decoded = jsonDecode(line);
          if (decoded is Map) return decoded.cast<String, dynamic>();
          throw const FormatException('stream line is not a JSON object');
        });
  }

  // ── DNS ──────────────────────────────────────────────────────────────

  /// `GET /dns/query`
  Future<Response> queryDNS({required String name, required String type}) =>
      _dio.get('/dns/query', queryParameters: {'name': name, 'type': type});

  // ── Storage ──────────────────────────────────────────────────────────

  /// `GET /storage/<key>`
  Future<Response> getStorage(String key) =>
      _dio.get('/storage/${encodePathSegment(key)}');

  /// `PUT /storage/<key>` — write a JSON value (max 1 MB).
  Future<Response> setStorage(String key, Map<String, dynamic> value) =>
      _dio.put('/storage/${encodePathSegment(key)}', data: value);

  /// `DELETE /storage/<key>`
  Future<Response> deleteStorage(String key) =>
      _dio.delete('/storage/${encodePathSegment(key)}');

  // ── Restart / Upgrade ────────────────────────────────────────────────

  /// `POST /restart`
  Future<Response> restart({String path = '', String payload = ''}) =>
      _dio.post('/restart', data: {'path': path, 'payload': payload});

  /// `POST /upgrade`
  Future<Response> upgrade({
    String channel = '',
    bool force = false,
    String path = '',
    String payload = '',
  }) => _dio.post(
    '/upgrade',
    queryParameters: {'channel': channel, 'force': force},
    data: {'path': path, 'payload': payload},
  );

  /// `POST /upgrade/ui`
  Future<Response> upgradeUI() => _dio.post('/upgrade/ui');

  /// `POST /upgrade/geo`
  Future<Response> upgradeGeo({String path = '', String payload = ''}) =>
      _dio.post('/upgrade/geo', data: {'path': path, 'payload': payload});

  // ── DEBUG ────────────────────────────────────────────────────────────

  /// `PUT /debug/gc` (requires `debug` log level on the controller).
  Future<Response> garbageCollect() => _dio.put('/debug/gc');

  /// `GET /debug/pprof` — raw pprof profile (not JSON; requires `debug`
  /// log level). Consume `response.data` as bytes/text, not a Map.
  Future<Response> getPprof() => _dio.get('/debug/pprof');
}
