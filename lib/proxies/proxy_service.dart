/*
 * Data model + request layer over the Mihomo external controller
 * `proxies`/`group` endpoints.
 *
 * Node names are free-form text, so regions are matched by `country_map`.
 */

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:ayatsuri/l10n/app_localizations.dart';

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

  /// Latency (ms) of the last probe; `null` if never probed, `0` if the
  /// probe reported blocked, `-1` ([kDelayTimeout]) if the probe timed out.
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
  /// Only `Selector` accepts that call; `URLTest`/`Fallback` use `fixed`
  /// + `DELETE` to clear and `LoadBalance` has no `now` to pin.
  bool get isSelector => type == 'Selector';
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

  /// Config-order rank for groups, derived from the built-in aggregate
  /// group's member list (see [_loadGroups]). Null when unavailable.
  Map<String, int>? _groupRank;
  bool loading = false;
  String? error;

  Map<String, ProxyItem> get proxies => _proxies ?? <String, ProxyItem>{};
  bool get loaded => _proxies != null;

  /// Selector groups in config order.
  ///
  /// The controller's group list itself comes from a map and its order
  /// rotates between calls, so it cannot be trusted as config order.
  /// The aggregate group, however, lists every proxy and group in
  /// config order in its member list, so groups are ranked by their
  /// first appearance there. Groups missing from that list keep their
  /// relative controller order after the ranked ones. Without an
  /// aggregate group the controller order is used as-is.
  List<GroupItem> get selectors {
    final list = (_groups ?? []).where((group) => group.isSelector).toList();
    final rank = _groupRank;
    if (rank == null) return list;
    final indexed = list.indexed.toList()
      ..sort((a, b) {
        final ra = rank[a.$2.name] ?? 1 << 30;
        final rb = rank[b.$2.name] ?? 1 << 30;
        if (ra != rb) return ra - rb;
        return a.$1 - b.$1;
      });
    return indexed.map((e) => e.$2).toList();
  }

  /// Fetch both proxy and group state.
  ///
  /// Transient connection failures are retried (~0.5s interval); if the
  /// retry budget is exhausted with no data, the load is surfaced as an
  /// offline error so callers can distinguish "controller unreachable"
  /// from a genuinely empty proxy set.
  Future<void> load() async {
    loading = true;
    error = null;
    _fatalError = null;
    try {
      await Future.wait([_loadProxies(), _loadGroups()]);
    } on DioException catch (e) {
      if (!isTransientDioError(e)) _fatalError = e.toString();
    } catch (e) {
      _fatalError = e.toString();
    }
    error = _fatalError;
    loading = false;
  }

  String? _fatalError;

  Future<void> _loadProxies() async {
    final response = await retryTransient<Response?>(() => _api.getProxies());
    if (response == null) {
      // No response after retries: controller unreachable (offline), not
      // an empty proxy set. Surface this so the globe can show offline.
      _fatalError ??= 'Proxy service unreachable: no response (offline?)';
      return;
    }
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
        // The controller has no top-level `delay`; latency lives in
        // `history[].delay` — take the last entry's value.
        delay: _lastHistoryDelay(n),
      );
    }
    _proxies = map;
  }

  Future<void> _loadGroups() async {
    final response = await retryTransient<Response?>(() => _api.getGroups());
    if (response == null) {
      _fatalError ??= 'Proxy service unreachable: no response (offline?)';
      return;
    }
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
    // Rank groups by first appearance in the aggregate group's member
    // list, which the controller builds in config order.
    _groupRank = null;
    for (final group in list) {
      if (group.name != 'GLOBAL') continue;
      final rank = <String, int>{};
      for (var i = 0; i < group.all.length; i++) {
        rank.putIfAbsent(group.all[i], () => i);
      }
      _groupRank = rank;
      break;
    }
  }

  /// Set a specific node inside a policy group.
  Future<void> select(String groupName, String proxyName) =>
      _api.selectProxy(groupName, proxyName: proxyName);

  static int? _lastHistoryDelay(Map<String, dynamic> n) {
    final history = n['history'] as List<dynamic>?;
    if (history != null && history.isNotEmpty) {
      final last = history.last;
      if (last is Map) {
        return (last['delay'] as num?)?.toInt();
      }
      return null;
    }
    // Legacy fallback for payloads that still carry a top-level delay.
    return (n['delay'] as num?)?.toInt();
  }

  /// Probe the delay of one proxy and persist the result. Returns whether a
  /// delay was recorded.
  Future<bool> _probeOne(
    String name, {
    required String url,
    required int timeout,
  }) async {
    try {
      final response = await _api.testProxyDelay(
        name,
        url: url,
        timeout: timeout,
      );
      final data = (response.data as Map<String, dynamic>);
      final delay = (data['delay'] as num?)?.toInt();
      if (delay == null) return false;
      await _updateDelay(name, delay);
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 504) {
        // Probe timed out at the kernel.
        await _updateDelay(name, kDelayTimeout);
        return true;
      }
      if (status == 503) {
        // Probe ran but the node is unreachable/blocked.
        await _updateDelay(name, 0);
        return true;
      }
      // No HTTP response (controller unreachable/offline) or an
      // authoritative error (400/401/404): leave the delay untouched so
      // offline is not masqueraded as a node timeout.
      return false;
    }
  }

  /// Probe the delay of several proxies and persist the result.
  ///
  /// The `GET /proxies/:name/delay` endpoint reports the probe result in `delay`
  /// (ms, higher is worse, `0` means blocked/unreachable).
  ///
  /// Returns the candidates whose latency changed so the caller can decide
  /// whether to redisplay the card.
  Future<List<ProxyCandidate>> probe(
    List<ProxyCandidate> candidates, {
    String url = kDefaultProbeUrl,
    int timeout = kProbeTimeoutMs,
  }) async {
    final out = <ProxyCandidate>[];
    for (final candidate in candidates) {
      if (await _probeOne(candidate.proxy.name, url: url, timeout: timeout)) {
        out.add(candidate);
      }
    }
    return out;
  }

  /// Probe a single proxy by name and persist its delay.
  Future<void> probeByName(
    String name, {
    String url = kDefaultProbeUrl,
    int timeout = kProbeTimeoutMs,
  }) async {
    await _probeOne(name, url: url, timeout: timeout);
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

/// Resolve which country the kernel is effectively using, following `now`
/// links through nested groups (e.g. `PROXY -> AUTO-FAST -> 🇦🇪 node`).
///
/// A group's `now` may name another group rather than a proxy, and policy
/// groups (Selector) in the list order may trail automatic URLTest pools
/// whose `now` is merely their current fastest node — so this prefers
/// Selector-typed chains and only falls back to automatic pools when no
/// Selector chain resolves to a country. Cycles resolve to null.
String? kernelCountryAlpha2(List<GroupItem> groups) {
  final byName = <String, GroupItem>{for (final g in groups) g.name: g};
  for (final selectorPass in [true, false]) {
    for (final group in groups) {
      if ((group.type == 'Selector') != selectorPass) continue;
      var name = group.now;
      final seen = <String>{};
      while (name != null && seen.add(name)) {
        final next = byName[name];
        if (next == null) {
          final alpha2 = nameToFrontAlpha2(name);
          if (alpha2 != null) return alpha2;
          break;
        }
        name = next.now;
      }
    }
  }
  return null;
}

/// Used by `testProxyDelay` as default probe URL.
const kDefaultProbeUrl = 'https://www.gstatic.com/generate_204';

/// Probe timeout (ms), matching the Clash Verge Rev / mihomo default.
/// `ProxyItem.delay` is [kDelayTimeout] when a probe dies with this.
const kProbeTimeoutMs = 5000;

/// Sentinel delay for a probe that timed out (shown red bold as TIMEOUT).
const kDelayTimeout = -1;

/// Probe-result color coding (`ms`): green under 500, amber 500–5000, red
/// over 5000; `red` when the probe was blocked, `grey` when never probed.
Color delayColor(int? delay) {
  if (delay == null) return Colors.grey;
  if (delay == kDelayTimeout) return Colors.red;
  if (delay == 0) return Colors.red;
  return delay < 500
      ? Colors.green
      : delay < 5000
      ? Colors.amber
      : Colors.red;
}

/// Probe result label: `—` for unprobed, localized `blocked` for 0-delay,
/// `N ms` for the reported latency.
String delayLabel(AppLocalizations l10n, int? delay) {
  if (delay == null) return '—';
  if (delay == kDelayTimeout) return l10n.timeout;
  if (delay == 0) return l10n.blocked;
  return l10n.delayMs(delay);
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
