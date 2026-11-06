/*
 * Unit tests for `lib/endpoints.dart` audit fixes:
 *  - E3: default secret no longer sends '***' (empty secret = no Bearer)
 *  - E4: path segments are Uri.encodeComponent'd
 *  - E9: PUT /configs sends a {path, payload} body
 *  - E14: streaming endpoints have snapshot semantics distinct from the
 *    30s one-shot default (trailing stream APIs, short snapshot timeout)
 *  - E18: errors are classified, not collapsed to timeout/null
 *  - pub: secret priority token > --dart-define > .env (dev fallback)
 */

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayatsuri/endpoints.dart';
import 'package:ayatsuri/info/mihomo_info.dart';

class CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

DioException dioError(DioExceptionType type, {int? statusCode}) {
  return DioException(
    requestOptions: RequestOptions(path: '/x'),
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: statusCode,
          ),
  );
}

void main() {
  // `.env` is no longer bundled as a pubspec asset, so asset-based
  // `dotenv.load()` fails; load the same dev values from memory.
  dotenv.loadFromString(envString: 'host=localhost\nport=9091\nsecret=***\n');

  test('secret priority: token > dart-define > .env, placeholder ignored', () {
    expect(
      resolveMihomoSecret(
        token: 'tok',
        dartDefineSecret: 'dd',
        dotenvSecret: 'env',
      ),
      'tok',
    );
    expect(
      resolveMihomoSecret(dartDefineSecret: 'dd', dotenvSecret: 'env'),
      'dd',
    );
    expect(resolveMihomoSecret(dotenvSecret: 'env'), 'env');
    expect(resolveMihomoSecret(dotenvSecret: '***'), isEmpty);
    expect(resolveMihomoSecret(), isEmpty);
    expect(resolveMihomoSecret(token: '***', dotenvSecret: 'env'), 'env');
  });

  test('empty/placeholder secret sends no Authorization header', () {
    expect(buildAuthHeaders(''), isEmpty);
    expect(buildAuthHeaders('***'), isEmpty);
    expect(buildAuthHeaders('s3cret'), {'Authorization': 'Bearer s3cret'});
  });

  test('MihomoAPI with empty secret omits Bearer (E3)', () {
    final adapter = CapturingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final api = MihomoAPI(secret: '', dio: dio);
    expect(api.dio.options.headers, isNot(contains('Authorization')));
    // The shipped .env contains secret=***; it must also be omitted.
    final api2 = MihomoAPI(dio: Dio()..httpClientAdapter = CapturingAdapter());
    expect(api2.dio.options.headers, isNot(contains('Authorization')));
  });

  test('path segments are encoded (E4)', () async {
    expect(encodePathSegment('a/b c🇺🇸'), 'a%2Fb%20c%F0%9F%87%BA%F0%9F%87%B8');
    final adapter = CapturingAdapter();
    final api = MihomoAPI(dio: Dio()..httpClientAdapter = adapter);
    await api.getProxy('HK 2/x');
    expect(adapter.lastOptions!.path, '/proxies/HK%202%2Fx');
    await api.getGroup('EU|1');
    expect(adapter.lastOptions!.path, '/group/EU%7C1');
    await api.getStorage('a/b');
    expect(adapter.lastOptions!.path, '/storage/a%2Fb');
  });

  test('PUT /configs sends {path, payload} body (E9)', () async {
    final adapter = CapturingAdapter();
    final api = MihomoAPI(dio: Dio()..httpClientAdapter = adapter);
    await api.reloadConfigs(force: true, path: '/etc/mihomo.yaml');
    expect(adapter.lastOptions!.method, 'PUT');
    expect(adapter.lastOptions!.path, '/configs');
    expect(adapter.lastOptions!.data, {
      'path': '/etc/mihomo.yaml',
      'payload': '',
    });
    expect(adapter.lastOptions!.queryParameters['force'], isTrue);
  });

  test(
    'streaming snapshot uses a short explicit timeout, not 30s (E14)',
    () async {
      final adapter = CapturingAdapter();
      final api = MihomoAPI(dio: Dio()..httpClientAdapter = adapter);
      await api.getTraffic();
      expect(adapter.lastOptions!.receiveTimeout, const Duration(seconds: 5));
      // Live stream path uses ResponseType.stream with no timeout.
      expect(api.streamTraffic, isNotNull);
      expect(api.streamMemory, isNotNull);
      expect(api.streamLogs, isNotNull);
    },
  );

  test('errors are classified, not collapsed (E18)', () {
    expect(
      classifyDioError(dioError(DioExceptionType.receiveTimeout)),
      MihomoErrorKind.timeout,
    );
    expect(
      classifyDioError(dioError(DioExceptionType.badResponse, statusCode: 401)),
      MihomoErrorKind.auth,
    );
    expect(
      classifyDioError(dioError(DioExceptionType.badResponse, statusCode: 404)),
      MihomoErrorKind.notFound,
    );
    expect(
      classifyDioError(dioError(DioExceptionType.badResponse, statusCode: 503)),
      MihomoErrorKind.unavailable,
    );
    expect(
      classifyDioError(dioError(DioExceptionType.badResponse, statusCode: 504)),
      MihomoErrorKind.gatewayTimeout,
    );
    expect(
      classifyDioError(dioError(DioExceptionType.unknown)),
      MihomoErrorKind.connection,
    );
    expect(
      isTransientDioError(dioError(DioExceptionType.receiveTimeout)),
      true,
    );
    expect(
      isTransientDioError(
        dioError(DioExceptionType.badResponse, statusCode: 401),
      ),
      false,
    );
    expect(
      isTransientDioError(
        dioError(DioExceptionType.badResponse, statusCode: 503),
      ),
      false,
    );
    expect(isTransientDioError(dioError(DioExceptionType.unknown)), true);
    expect(
      isTransientDioError(dioError(DioExceptionType.unknown, statusCode: 500)),
      false,
    );
  });

  test(
    'retryTransient rethrows after exhaustion instead of null (E18)',
    () async {
      var calls = 0;
      await expectLater(
        retryTransient(
          () async {
            calls++;
            throw dioError(DioExceptionType.connectionError);
          },
          attempts: 3,
          interval: Duration.zero,
        ),
        throwsA(isA<DioException>()),
      );
      expect(calls, 3);

      calls = 0;
      await expectLater(
        retryTransient(
          () async {
            calls++;
            throw dioError(DioExceptionType.badResponse, statusCode: 401);
          },
          attempts: 3,
          interval: Duration.zero,
        ),
        throwsA(isA<DioException>()),
      );
      expect(calls, 1, reason: 'non-transient errors are not retried');
    },
  );

  test('stream body factories parse truncated captures', () {
    final traffic = TrafficInfo.fromStreamBody(
      '{"up":10,"down":20,"upTotal":100,"downTotal":200}\n'
      '{"up":30,"down":40,"upTotal":130,"downTotal":240}\n'
      '{"up":99', // truncated mid-line: skipped
    );
    expect(traffic.sampleCount, 2);
    expect(traffic.up, 30);
    expect(traffic.maxUp, 30);

    final memory = MemoryInfo.fromStreamBody('{"inuse":7,"oslimit":9}\n');
    expect(memory.inuse, 7);
    expect(memory.sampleCount, 1);

    final logs = LogsInfo.fromStreamBody(
      '{"type":"info","payload":"hi"}\n{"type":"error","payload":"boom"}\n',
    );
    expect(logs.sampleCount, 2);
    expect(logs.errorCount, 1);
  });
}
