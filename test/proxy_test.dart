/*
 * Unit tests for `ProxySelection` (delay probing / candidate tables), behind a
 * fake controller so no live Mihomo instance is required.
 */

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayatsuri/endpoints.dart';
import 'package:ayatsuri/proxies/country_map.dart';
import 'package:ayatsuri/proxies/proxy_service.dart';

class FakeMihomoAPI extends MihomoAPI {
  Map<String, Map<String, dynamic>> mockProxies =
      <String, Map<String, dynamic>>{
        'HK 2': {'name': 'HK 2', 'type': 'Direct', 'alive': true, 'delay': 150},
        'CN 1': {'name': 'CN 1', 'type': 'Direct', 'alive': true, 'delay': 400},
        'US 3': {'name': 'US 3', 'type': 'Direct', 'alive': true},
      };

  List<Map<String, dynamic>> mockGroups = <Map<String, dynamic>>[
    {
      'name': 'go',
      'type': 'Selector',
      'all': ['HK 2', 'CN 1', 'US 3'],
      'now': 'HK 2',
    },
  ];

  @override
  Future<Response> getProxies() => Future<Response>.value(
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(),
      data: <String, dynamic>{'proxies': mockProxies},
    ),
  );

  @override
  Future<Response> getGroups() => Future<Response>.value(
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(),
      data: <String, dynamic>{'proxies': mockGroups},
    ),
  );

  @override
  Future<Response> testProxyDelay(
    String name, {
    String url = kDefaultProbeUrl,
    int timeout = 5000,
    String? expected,
  }) {
    final item = mockProxies[name] ?? <String, dynamic>{};
    final mockDelay = item['delay'] as int?;
    return Future<Response>.value(
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(),
        data: mockDelay != null
            ? <String, dynamic>{'delay': mockDelay}
            : <String, dynamic>{},
      ),
    );
  }

  @override
  Future<Response> selectProxy(String name, {required String proxyName}) {
    mockGroups[0]['now'] = proxyName;
    return Future<Response>.value(
      Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(),
        data: <String, dynamic>{},
      ),
    );
  }

  @override
  Future<Response> getProxy(String name) => Future<Response>.value(
    Response<Map<String, dynamic>>(
      requestOptions: RequestOptions(),
      data: mockProxies[name] ?? {},
    ),
  );
}

void main() async {
  // Mock unit test: load dotenv before FakeMihomoAPI constructs MihomoAPI.
  await dotenv.load();
  late FakeMihomoAPI fake;
  late ProxySelection selection;

  setUp(() {
    fake = FakeMihomoAPI();
    selection = ProxySelection(api: fake);
  });

  test('load proxies and groups', () async {
    await selection.load();
    expect(selection.proxies.length, 3);
    expect(selection.selectors.length, 1);
    expect(selection.selectors[0].all, ['HK 2', 'CN 1', 'US 3']);
    expect(selection.proxies['HK 2']!.delay, 150);
    expect(selection.proxies['CN 1']!.delay, 400);
    expect(selection.proxies['US 3']!.delay, isNull);
  });

  test('candidatesForMapId groups proxies by country', () async {
    await selection.load();
    // Candidates are picked by name match within each selector group.
    final ids = <String>{};
    for (final group in selection.selectors) {
      for (final name in group.all) {
        final alpha2 = nameToFrontAlpha2(name);
        if (alpha2 != null) ids.add(alpha2);
      }
    }
    expect(ids, {'HK', 'CN', 'US'});
    expect(selection.candidatesForMapId('HK'), hasLength(1));
    expect(selection.candidatesForMapId('CN'), hasLength(1));
    expect(selection.candidatesForMapId('US'), hasLength(1));
    expect(selection.candidatesForMapId('XX'), isEmpty);
  });

  test('probeByName updates probe delay', () async {
    await selection.load();
    // US 3 has no probe key, so the delay is not set.
    final updated = await fake.testProxyDelay('US 3');
    expect(updated.data['delay'], isNull);
    await selection.probeByName('US 3');
    expect(selection.proxies['US 3']!.delay, isNull);
  });

  test('probe() probes the whole candidate set', () async {
    await selection.load();
    final candidates = selection.candidatesForMapId('HK');
    expect(candidates.length, 1);
    expect(await selection.probe(candidates), hasLength(1));
    // the mock reports its own 150(ms) value, not the generic 100.
    expect(selection.proxies['HK 2']!.delay, 150);
  });

  test('probe with no delay returns nothing', () async {
    await selection.load();
    // The fake keeps its own delay; a probe reporting no value does not
    // touch the cache.
    fake.mockProxies['HK 2']!.remove('delay');
    final candidates = selection.candidatesForMapId('HK');
    expect(candidates, hasLength(1));
    final result = await selection.probe(candidates);
    expect(result, isEmpty);
    expect(selection.proxies['HK 2']!.delay, 150);
  });

  test('proxy selection updates group.now', () async {
    await selection.load();
    await selection.select('go', 'CN 1');
    await selection.load();
    expect(selection.selectors[0].now, 'CN 1');
    final updated = selection.candidatesForMapId('CN');
    expect(updated.first.isNow, isTrue);
  });

  test('delay labels', () {
    expect(delayLabel(null), '—');
    expect(delayLabel(0), 'blocked');
    expect(delayLabel(42), '42 ms');
  });

  test('delay colors follow the thresholds', () {
    expect(delayColor(null), Colors.grey);
    expect(delayColor(0), Colors.red);
    expect(delayColor(50), Colors.green);
    expect(delayColor(99), Colors.green);
    expect(delayColor(100), Colors.amber);
    expect(delayColor(299), Colors.amber);
    expect(delayColor(300), Colors.red);
    expect(delayColor(1000), Colors.red);
  });

  test('delay colors are consistent per state', () {
    expect(delayColor(150), delayColor(150));
    expect(delayColor(150), isNot(delayColor(999)));
    expect(delayColor(0), isNot(delayColor(50)));
  });
}
