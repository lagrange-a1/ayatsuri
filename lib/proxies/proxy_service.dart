/*
 * Data model + request layer over the Mihomo external controller
 * `proxies`/`group` endpoints.
 *
 * Node names are free-form text, so regions are matched by `country_map`.
 */

import '../endpoints.dart';
import 'country_map.dart';

class ProxyItem {
  const ProxyItem({
    required this.name,
    required this.type,
    this.alive = false,
    this.latency,
  });
  final String name;
  final String type;
  final bool alive;
  final double? latency;
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
    final entries = (data['proxies'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    for (final entry in entries.entries) {
      final n = entry.value as Map<String, dynamic>;
      map[entry.key] = ProxyItem(
        name: entry.key,
        type: n['type'] as String? ?? 'Unknown',
        alive: n['alive'] as bool? ?? false,
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
      list.add(GroupItem(
        name: n['name'] as String? ?? '',
        type: n['type'] as String? ?? '',
        all: (n['all'] as List<dynamic>?)
                ?.cast<String>()
                .where((e) => e.isNotEmpty)
                .toList() ??
            <String>[],
        now: n['now'] as String?,
      ));
    }
    _groups = list;
  }

  /// Set a specific node inside a policy group.
  Future<void> select(String groupName, String proxyName) =>
      _api.selectProxy(groupName, proxyName: proxyName);

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
