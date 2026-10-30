/*
 * Data model + request layer over the Mihomo external controller
 * `proxies`/`group` endpoints.
 *
 * Node names are free-form text, so regions are matched by `country_map`.
 */

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../endpoints.dart';
import 'country_map.dart';

class ProxyItem {
  const ProxyItem({
    required this.name,
    required this.type,
    this.alive = false,
    this.latency,
    this.delay,
  });
  final String name;
  final String type;
  final bool alive;
  final double? latency;

  /// Latency (ms) of the last block probe; `null` if never probed, `0` if the
  /// probe is blocked.
  final int? delay;
}

class GroupItem {
  const GroupItem({
    required this.name,
    required this.type,
    required this.all,
    this.now,
  });

  final String name;
  final String type;
  final List<String> all;
  final String? now;

  /// A group whose selected node can be set with `PUT /proxies/<group>`.
  bool get isSelector =>
      ['Selector', 'URLTest', 'Fallback', 'LoadBalance'].contains(type);
}

class ProxyCandidate {
  const ProxyCandidate({required this.group, required this.proxy});

  final GroupItem group;
  final ProxyItem proxy;
  bool get isNow => group.now == proxy.name;
}

class ProxySelection {
  ProxySelection({MihomoAPI? api}) : _api = api ?? MihomoAPI();

  final MihomoAPI _api;

  Map<String, ProxyItem>? _proxies;
  List<GroupItem>? _groups;
  bool loading = false;
  String? error;

  Map<String, ProxyItem> get proxies => _proxies ?? <String, ProxyItem>{};
  List<GroupItem> get selectors =>
      (_groups ?? []).where((group) => group.isSelector).toList();

  /// Fetch both proxy and group state.
  Future<void> load() async {
    loading = true;
    error = null;
    try {
      await Future.wait([_loadProxies(), _loadGroups()]);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
    }
  }

  Future<void> _loadProxies() async {
    final response = await _api.getProxies();
    final map = <String, ProxyItem>{};
    final data = response.data as Map<String, dynamic>;
    // `GET /proxies` returns `{ "proxies": { "<name>": { ... } } }`
    final entries =
        (data['proxies'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    for (final entry in entries.entries) {
      final n = entry.value as Map<String, dynamic>;
      map[entry.key] = ProxyItem(
        name: entry.key,
        type: n['type'] as String? ?? 'Unknown',
        alive: n['alive'] as bool? ?? false,
        // The controller reports the last probe result (ms) per proxy.
        delay: (n['delay'] as num?)?.toInt(),
      );
    }
    _proxies = map;
  }

  Future<void> _loadGroups() async {
    final response = await _api.getGroups();
    final list = <GroupItem>[];
    final data = response.data as Map<String, dynamic>;
    final proxies = (data['proxies'] as List<dynamic>?) ?? <dynamic>[];
    for (final item in proxies) {
      final n = item as Map<String, dynamic>;
      list.add(
        GroupItem(
          name: n['name'] as String? ?? '',
          type: n['type'] as String? ?? '',
          all:
              (n['all'] as List<dynamic>?)
                  ?.cast<String>()
                  .where((e) => e.isNotEmpty)
                  .toList() ??
              <String>[],
          now: n['now'] as String?,
        ),
      );
    }
    _groups = list;
  }

  /// Set a specific node inside a policy group.
  Future<void> select(String groupName, String proxyName) =>
      _api.selectProxy(groupName, proxyName: proxyName);

  /// Probe the delay of several proxies in parallel and persist the result.
  ///
  /// The `GET /proxies/:name/delay` endpoint reports the probe result in `delay`
  /// (ms, higher is worse, `0` means blocked/unreachable).
  ///
  /// Returns the candidates whose latency changed so the caller can decide
  /// whether to redisplay the card.
  Future<List<ProxyCandidate>> probe(
    List<ProxyCandidate> candidates, {
    String url = kDefaultProbeUrl,
    int timeout = 5000,
  }) async {
    final out = <ProxyCandidate>[];
    for (final candidate in candidates) {
      try {
        final response = await _api.testProxyDelay(
          candidate.proxy.name,
          url: url,
          timeout: timeout,
        );
        final data = (response.data as Map<String, dynamic>);
        final delay = (data['delay'] as num?)?.toInt();
        if (delay == null) continue;
        await _updateDelay(candidate.proxy.name, delay);
        out.add(candidate);
      } on DioException {
        continue;
      }
    }
    return out;
  }

  /// Probe a single proxy by name and persist its delay.
  Future<void> probeByName(
    String name, {
    String url = kDefaultProbeUrl,
    int timeout = 5000,
  }) async {
    try {
      final response = await _api.testProxyDelay(
        name,
        url: url,
        timeout: timeout,
      );
      final data = (response.data as Map<String, dynamic>);
      final delay = (data['delay'] as num?)?.toInt();
      if (delay == null) return;
      await _updateDelay(name, delay);
    } on DioException catch (e) {
      error = e.toString();
    }
  }

  Future<void> _updateDelay(String name, int delay) async {
    final item = _proxies?[name];
    if (item == null) return;
    _proxies![name] = ProxyItem(
      name: item.name,
      type: item.type,
      alive: item.alive,
      latency: item.latency,
      delay: delay,
    );
  }

  /// Candidates for a map ID (country code).
  ///
  /// Group whose own name matches the country come first, then the rest.
  List<ProxyCandidate> candidatesForMapId(String mapId) {
    final alpha2 = countryAlpha2FromMapId(mapId) ?? mapId.toUpperCase();
    final pattern = patternFor(alpha2);
    final out = <ProxyCandidate>[];

    for (final group in selectors) {
      for (final name in group.all) {
        final proxy = proxies[name];
        if (proxy == null) continue;
        if (!isProxyInCountry(name, pattern)) continue;
        out.add(ProxyCandidate(group: group, proxy: proxy));
      }
    }

    return out;
  }
}

/// Used by `testProxyDelay` as default probe URL.
const kDefaultProbeUrl = 'https://www.gstatic.com/generate_204';

/// Probe-result color coding (`ms`): green under 100, amber 100–300, red over
/// 300; `red` when the probe was blocked, `grey` when never probed.
Color delayColor(int? delay) {
  if (delay == null) return Colors.grey;
  if (delay == 0) return Colors.red;
  return delay < 100
      ? Colors.green
      : delay < 300
      ? Colors.amber
      : Colors.red;
}

/// Probe result label: `—` for unprobed, `blocked` for 0-delay, `N ms` for the
/// reported latency.
String delayLabel(int? delay) {
  if (delay == null) return '—';
  if (delay == 0) return 'blocked';
  return '$delay ms';
}

CountryPattern patternFor(String alpha2) {
  return kCountries[alpha2] ??
      CountryPattern(
        alpha2: '',
        alpha3: '',
        flag: '',
        name: '—',
        patterns: [alpha2],
      );
}
