import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MihomoAPI {
  late final Dio _dio;
  late final String baseUrl;

  MihomoAPI() {
    final host = dotenv.env['host'] ?? 'localhost';
    final port = dotenv.env['port'] ?? '9091';
    final secret = dotenv.env['secret'] ?? '***';
    baseUrl = 'http://$host:$port';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $secret'},
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  // ── Version ──────────────────────────────────────────────────────────

  /// `GET /version`
  Future<Response> getVersion() => _dio.get('/version');

  // ── Proxies ──────────────────────────────────────────────────────────

  /// `GET /proxies`
  Future<Response> getProxies() => _dio.get('/proxies');

  /// `GET /proxies/<name>`
  Future<Response> getProxy(String name) => _dio.get('/proxies/$name');

  /// `PUT /proxies/<name>` — select a proxy within a policy group.
  Future<Response> selectProxy(String name, {required String proxyName}) =>
      _dio.put('/proxies/$name', data: {'name': proxyName});

  /// `DELETE /proxies/<name>` — clear fixed selection (except Selector type).
  Future<Response> clearProxySelection(String name) =>
      _dio.delete('/proxies/$name');

  /// `GET /proxies/<name>/delay`
  Future<Response> testProxyDelay(
    String name, {
    required String url,
    int timeout = 5000,
    String? expected,
  }) {
    final params = <String, dynamic>{'url': url, 'timeout': timeout};
    if (expected != null) params['expected'] = expected;
    return _dio.get('/proxies/$name/delay', queryParameters: params);
  }

  // ── Policy Groups ────────────────────────────────────────────────────

  /// `GET /group`
  Future<Response> getGroups() => _dio.get('/group');

  /// `GET /group/<name>`
  Future<Response> getGroup(String name) => _dio.get('/group/$name');

  /// `GET /group/<name>/delay`
  Future<Response> testGroupDelay(
    String name, {
    required String url,
    int timeout = 5000,
    String? expected,
  }) {
    final params = <String, dynamic>{'url': url, 'timeout': timeout};
    if (expected != null) params['expected'] = expected;
    return _dio.get('/group/$name/delay', queryParameters: params);
  }

  // ── Running Configuration ────────────────────────────────────────────

  /// `GET /configs`
  Future<Response> getConfigs() => _dio.get('/configs');

  /// `PUT /configs` — reload basic configuration.
  Future<Response> reloadConfigs({bool force = false}) =>
      _dio.put('/configs', queryParameters: {'force': force});

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
      _dio.delete('/connections/$id');

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
      _dio.get('/providers/proxies/$name');

  /// `PUT /providers/proxies/<name>`
  Future<Response> updateProxyProvider(String name) =>
      _dio.put('/providers/proxies/$name');

  /// `GET /providers/proxies/<name>/healthcheck`
  Future<Response> healthCheckProxyProvider(String name) =>
      _dio.get('/providers/proxies/$name/healthcheck');

  /// `GET /providers/proxies/<name>/proxies/<proxy_name>`
  Future<Response> getProxyFromProvider(
    String providerName,
    String proxyName,
  ) => _dio.get('/providers/proxies/$providerName/proxies/$proxyName');

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
      '/providers/proxies/$providerName/proxies/$proxyName/healthcheck',
      queryParameters: params,
    );
  }

  // ── Rule Providers ───────────────────────────────────────────────────

  /// `GET /providers/rules`
  Future<Response> getRuleProviders() => _dio.get('/providers/rules');

  /// `PUT /providers/rules/<name>`
  Future<Response> updateRuleProvider(String name) =>
      _dio.put('/providers/rules/$name');

  // ── Traffic / Memory / Logs ──────────────────────────────────────────

  /// `GET /traffic` — real-time traffic, pushed once per second.
  Future<Response> getTraffic() => _dio.get('/traffic');

  /// `GET /memory` — real-time memory usage, pushed once per second.
  Future<Response> getMemory() => _dio.get('/memory');

  /// `GET /logs` — real-time logs.
  Future<Response> getLogs({
    String level = 'info',
    String format = 'standard',
  }) => _dio.get('/logs', queryParameters: {'level': level, 'format': format});

  // ── DNS ──────────────────────────────────────────────────────────────

  /// `GET /dns/query`
  Future<Response> queryDNS({required String name, required String type}) =>
      _dio.get('/dns/query', queryParameters: {'name': name, 'type': type});

  // ── Storage ──────────────────────────────────────────────────────────

  /// `GET /storage/<key>`
  Future<Response> getStorage(String key) => _dio.get('/storage/$key');

  /// `PUT /storage/<key>` — write a JSON value (max 1 MB).
  Future<Response> setStorage(String key, Map<String, dynamic> value) =>
      _dio.put('/storage/$key', data: value);

  /// `DELETE /storage/<key>`
  Future<Response> deleteStorage(String key) => _dio.delete('/storage/$key');

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

  /// `PUT /debug/gc`
  Future<Response> garbageCollect() => _dio.put('/debug/gc');

  /// `GET /debug/pprof`
  Future<Response> getPprof() => _dio.get('/debug/pprof');
}
