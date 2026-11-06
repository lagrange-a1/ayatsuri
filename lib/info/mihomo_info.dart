/// Pure-Dart summarizers for the nine Mihomo controller info endpoints.
///
/// These models turn the raw JSON returned by `GET /version`, `/configs`,
/// `/proxies`, `/group`, `/rules`, `/connections`, `/traffic`, `/memory`
/// and `/logs` into small, typed, dashboard-ready summaries: counts,
/// key fields, top entries, and Mihomo-specific breakdowns (group `now`
/// chains, proxy/rule type breakdowns, connection protocol/network mixes).
///
/// Everything here is pure Dart with no widget or networking code, so the
/// summaries are unit-testable with synthetic fixtures. Every `fromJson`
/// tolerates missing or mistyped fields (treating them as empty/zero)
/// because controller responses vary across Mihomo versions and because
/// the streaming endpoints (`/traffic`, `/memory`, `/logs`) can be
/// truncated mid-line.
library;

import 'dart:convert';

// ── Small pure helpers ────────────────────────────────────────────────────

String _string(Object? v) => v is String ? v : v?.toString() ?? '';

int _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _bool(Object? v) => v is bool ? v : v == true;

Map<String, dynamic> _map(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return const <String, dynamic>{};
}

List<dynamic> _list(Object? v) => v is List ? v : const <dynamic>[];

List<Map<String, dynamic>> _mapList(Object? v) =>
    _list(v).map(_map).toList(growable: false);

List<String> _stringList(Object? v) =>
    _list(v).map(_string).toList(growable: false);

/// Counts occurrences of [key] across [items]; missing keys count as `''`.
Map<String, int> countBy(List<Map<String, dynamic>> items, String key) {
  final counts = <String, int>{};
  for (final item in items) {
    final value = _string(item[key]);
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

/// Counts occurrences produced by [valueOf] across [items].
Map<String, int> countByValue<T>(
  List<T> items,
  String Function(T item) valueOf,
) {
  final counts = <String, int>{};
  for (final item in items) {
    final value = valueOf(item);
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

/// Entries of [counts] sorted by count descending, then key ascending so
/// ties are deterministic (important for stable tests and UI ordering).
List<MapEntry<String, int>> sortedCounts(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return entries;
}

/// The top-[n] entries of [counts] in [sortedCounts] order.
List<MapEntry<String, int>> topEntries(Map<String, int> counts, int n) {
  final sorted = sortedCounts(counts);
  return n < sorted.length ? sorted.sublist(0, n) : sorted;
}

/// Formats a byte count compactly (`1383` -> `1.4 KB`).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB', 'PB'];
  var value = bytes.toDouble();
  var unit = -1;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
}

/// Formats a per-second rate compactly, e.g. `104278` -> `101.8 KB/s`.
String formatRate(int bytesPerSecond) => '${formatBytes(bytesPerSecond)}/s';

/// Splits a captured streaming body (one JSON object per line) into maps.
/// Blank or unparseable lines are skipped, so a truncated final line from
/// a timed-out `curl` capture does not break parsing.
List<Map<String, dynamic>> parseJsonLines(String body) {
  final out = <Map<String, dynamic>>[];
  for (final line in body.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) out.add(_map(decoded));
    } catch (_) {
      // Skip malformed/truncated lines.
    }
  }
  return out;
}

// ── /version ──────────────────────────────────────────────────────────────

/// Summary of `GET /version`, e.g. `{"meta":true,"version":"1.19.33"}`.
class VersionInfo {
  const VersionInfo({
    this.version = '',
    this.meta = false,
    this.raw = const {},
  });

  factory VersionInfo.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return VersionInfo(
      version: _string(data['version']),
      meta: _bool(data['meta']),
      raw: data,
    );
  }

  final String version;
  final bool meta;
  final Map<String, dynamic> raw;
}

// ── /configs ──────────────────────────────────────────────────────────────

/// Summary of `GET /configs` (the running configuration).
class ConfigsInfo {
  const ConfigsInfo({
    this.mode = '',
    this.logLevel = '',
    this.allowLan = false,
    this.ipv6 = false,
    this.sniffing = false,
    this.tcpConcurrent = false,
    this.unifiedDelay = false,
    this.geodataMode = false,
    this.geoAutoUpdate = false,
    this.findProcessMode = '',
    this.bindAddress = '',
    this.interfaceName = '',
    this.ports = const <String, int>{},
    this.tunEnabled = false,
    this.tunDevice = '',
    this.tunStack = '',
    this.tunMtu = 0,
    this.tunAutoRoute = false,
    this.raw = const {},
  });

  factory ConfigsInfo.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    final tun = _map(data['tun']);
    final ports = <String, int>{};
    for (final key in const [
      'port',
      'socks-port',
      'mixed-port',
      'redir-port',
      'tproxy-port',
    ]) {
      ports[key] = _int(data[key]);
    }
    return ConfigsInfo(
      mode: _string(data['mode']),
      logLevel: _string(data['log-level']),
      allowLan: _bool(data['allow-lan']),
      ipv6: _bool(data['ipv6']),
      sniffing: _bool(data['sniffing']),
      tcpConcurrent: _bool(data['tcp-concurrent']),
      unifiedDelay: _bool(data['unified-delay']),
      geodataMode: _bool(data['geodata-mode']),
      geoAutoUpdate: _bool(data['geo-auto-update']),
      findProcessMode: _string(data['find-process-mode']),
      bindAddress: _string(data['bind-address']),
      interfaceName: _string(data['interface-name']),
      ports: ports,
      tunEnabled: _bool(tun['enable']),
      tunDevice: _string(tun['device']),
      tunStack: _string(tun['stack']),
      tunMtu: _int(tun['mtu']),
      tunAutoRoute: _bool(tun['auto-route']),
      raw: data,
    );
  }

  /// Listening ports that are actually configured (`> 0`).
  Map<String, int> get activePorts => Map<String, int>.fromEntries(
    ports.entries.where((entry) => entry.value > 0),
  );

  final String mode;
  final String logLevel;
  final bool allowLan;
  final bool ipv6;
  final bool sniffing;
  final bool tcpConcurrent;
  final bool unifiedDelay;
  final bool geodataMode;
  final bool geoAutoUpdate;
  final String findProcessMode;
  final String bindAddress;
  final String interfaceName;
  final Map<String, int> ports;
  final bool tunEnabled;
  final String tunDevice;
  final String tunStack;
  final int tunMtu;
  final bool tunAutoRoute;
  final Map<String, dynamic> raw;
}

// ── /proxies ──────────────────────────────────────────────────────────────

/// Summary of `GET /proxies` (`{"proxies": {name: {...}}}`).
class ProxiesInfo {
  const ProxiesInfo({
    this.total = 0,
    this.aliveCount = 0,
    this.typeCounts = const <String, int>{},
    this.probedCount = 0,
    this.minDelay = 0,
    this.maxDelay = 0,
    this.averageDelay = 0,
    this.aliveNames = const <String>[],
    this.names = const <String>[],
    this.entries = const <ProxyEntry>[],
  });

  factory ProxiesInfo.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    final proxies = _map(data['proxies']);
    final entries = <ProxyEntry>[];
    final typeCounts = <String, int>{};
    var alive = 0;
    var probed = 0;
    var delaySum = 0;
    var minDelay = 0;
    var maxDelay = 0;
    final aliveNames = <String>[];

    proxies.forEach((name, raw) {
      final item = _map(raw);
      final entry = ProxyEntry.fromJson(name, item);
      entries.add(entry);
      typeCounts[entry.type] = (typeCounts[entry.type] ?? 0) + 1;
      if (entry.alive) {
        alive++;
        aliveNames.add(name);
      }
      if (entry.lastDelay != null && entry.lastDelay! > 0) {
        probed++;
        delaySum += entry.lastDelay!;
        if (probed == 1 || entry.lastDelay! < minDelay) {
          minDelay = entry.lastDelay!;
        }
        if (entry.lastDelay! > maxDelay) maxDelay = entry.lastDelay!;
      }
    });

    entries.sort((a, b) => a.name.compareTo(b.name));
    aliveNames.sort();
    return ProxiesInfo(
      total: proxies.length,
      aliveCount: alive,
      typeCounts: typeCounts,
      probedCount: probed,
      minDelay: probed == 0 ? 0 : minDelay,
      maxDelay: maxDelay,
      averageDelay: probed == 0 ? 0 : delaySum ~/ probed,
      aliveNames: aliveNames,
      names: entries.map((e) => e.name).toList(growable: false),
      entries: entries,
    );
  }

  /// Dead (`alive == false`) proxy count.
  int get deadCount => total - aliveCount;

  /// Proxy types sorted by count descending (deterministic on ties).
  List<MapEntry<String, int>> get sortedTypes => sortedCounts(typeCounts);

  /// Top-[n] proxy types by count.
  List<MapEntry<String, int>> topTypes(int n) => topEntries(typeCounts, n);

  final int total;
  final int aliveCount;
  final Map<String, int> typeCounts;

  /// Proxies with a positive last-probe delay in their history.
  final int probedCount;
  final int minDelay;
  final int maxDelay;
  final int averageDelay;
  final List<String> aliveNames;
  final List<String> names;
  final List<ProxyEntry> entries;
}

/// One entry of `/proxies` (also the shape of `/group` members).
class ProxyEntry {
  const ProxyEntry({
    this.name = '',
    this.type = '',
    this.alive = false,
    this.udp = false,
    this.providerName = '',
    this.now = '',
    this.allCount = 0,
    this.lastDelay,
    this.historyCount = 0,
  });

  factory ProxyEntry.fromJson(String name, Map<String, dynamic> json) {
    var lastDelay = 0;
    var seen = false;
    for (final item in _mapList(json['history'])) {
      final delay = _int(item['delay']);
      if (delay > 0) {
        lastDelay = delay;
        seen = true;
      }
    }
    return ProxyEntry(
      name: _string(json['name']).isEmpty ? name : _string(json['name']),
      type: _string(json['type']),
      alive: _bool(json['alive']),
      udp: _bool(json['udp']),
      providerName: _string(json['provider-name']),
      now: _string(json['now']),
      allCount: _list(json['all']).length,
      lastDelay: seen ? lastDelay : null,
      historyCount: _list(json['history']).length,
    );
  }

  final String name;
  final String type;
  final bool alive;
  final bool udp;
  final String providerName;

  /// For policy groups: the currently selected member (`now`).
  final String now;
  final int allCount;
  final int? lastDelay;
  final int historyCount;
}

// ── /group ────────────────────────────────────────────────────────────────

/// Summary of `GET /group` (`{"proxies": [...]}` policy groups).
class GroupsInfo {
  const GroupsInfo({
    this.total = 0,
    this.typeCounts = const <String, int>{},
    this.entries = const <GroupEntry>[],
  });

  factory GroupsInfo.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    final entries = _mapList(
      data['proxies'],
    ).map((item) => GroupEntry.fromJson(item)).toList(growable: false);
    return GroupsInfo(
      total: entries.length,
      typeCounts: countByValue(entries, (e) => e.type),
      entries: entries,
    );
  }

  /// Groups sorted by name for stable display.
  List<GroupEntry> get sortedEntries {
    final copy = entries.toList()..sort((a, b) => a.name.compareTo(b.name));
    return copy;
  }

  /// Resolves the `group -> now -> ...` chain for [name]: each step
  /// follows the current group's `now` until a name that is not itself a
  /// group (a leaf proxy) or the chain cycles. [proxyNames] optionally
  /// supplies the leaf set so a `now` naming a plain proxy ends the chain
  /// even if a group shares the name.
  List<String> chainFor(String name, {Set<String>? proxyNames}) =>
      resolveNowChain(name, {
        for (final e in entries) e.name: e,
      }, proxyNames: proxyNames);

  final int total;
  final Map<String, int> typeCounts;
  final List<GroupEntry> entries;
}

/// Follows `now` links from [name] through [groupsByName].
///
/// Returns `[name, now, now-of-now, ...]` stopping at a leaf (a `now`
/// that is not a group, or is in [proxyNames]), an empty `now`, or just
/// before a repeat (cycle-safe).
List<String> resolveNowChain(
  String name,
  Map<String, GroupEntry> groupsByName, {
  Set<String>? proxyNames,
}) {
  final chain = <String>[name];
  final seen = <String>{name};
  var current = name;
  while (true) {
    final group = groupsByName[current];
    if (group == null) break;
    final next = group.now;
    if (next.isEmpty) break;
    if (seen.contains(next)) break;
    chain.add(next);
    seen.add(next);
    if (proxyNames != null && proxyNames.contains(next)) break;
    if (!groupsByName.containsKey(next)) break;
    current = next;
  }
  return chain;
}

/// One policy group from `/group`.
class GroupEntry {
  const GroupEntry({
    this.name = '',
    this.type = '',
    this.now = '',
    this.alive = false,
    this.hidden = false,
    this.testUrl = '',
    this.emptyFallback = '',
    this.all = const <String>[],
    this.lastDelay,
  });

  factory GroupEntry.fromJson(Map<String, dynamic> json) {
    var lastDelay = 0;
    var seen = false;
    for (final item in _mapList(json['history'])) {
      final delay = _int(item['delay']);
      if (delay > 0) {
        lastDelay = delay;
        seen = true;
      }
    }
    return GroupEntry(
      name: _string(json['name']),
      type: _string(json['type']),
      now: _string(json['now']),
      alive: _bool(json['alive']),
      hidden: _bool(json['hidden']),
      testUrl: _string(json['testUrl']),
      emptyFallback: _string(json['emptyFallback']),
      all: _stringList(json['all']),
      lastDelay: seen ? lastDelay : null,
    );
  }

  int get allCount => all.length;

  final String name;
  final String type;
  final String now;
  final bool alive;
  final bool hidden;
  final String testUrl;
  final String emptyFallback;
  final List<String> all;
  final int? lastDelay;
}

// ── /rules ────────────────────────────────────────────────────────────────

/// Summary of `GET /rules` (`{"rules": [...]}`).
///
/// Note: `/rules` entries carry no provider name; [providerBackedCount]
/// counts rules whose `size >= 0` (provider-backed rule sets report a
/// non-negative size, plain rules report `-1`).
class RulesInfo {
  const RulesInfo({
    this.total = 0,
    this.typeCounts = const <String, int>{},
    this.proxyCounts = const <String, int>{},
    this.disabledCount = 0,
    this.providerBackedCount = 0,
    this.hitTotal = 0,
    this.missTotal = 0,
    this.topHitRules = const <RuleEntry>[],
    this.entries = const <RuleEntry>[],
  });

  factory RulesInfo.fromJson(Map<String, dynamic>? json, {int topN = 10}) {
    final data = json ?? const <String, dynamic>{};
    final entries = _mapList(
      data['rules'],
    ).map(RuleEntry.fromJson).toList(growable: false);
    return RulesInfo.fromEntries(entries, topN: topN);
  }

  factory RulesInfo.fromEntries(List<RuleEntry> entries, {int topN = 10}) {
    final typeCounts = countByValue(entries, (e) => e.type);
    final proxyCounts = countByValue(entries, (e) => e.proxy);
    var disabled = 0;
    var providerBacked = 0;
    var hits = 0;
    var misses = 0;
    for (final entry in entries) {
      if (entry.disabled) disabled++;
      if (entry.size >= 0) providerBacked++;
      hits += entry.hitCount;
      misses += entry.missCount;
    }
    final byHits = entries.toList()
      ..sort((a, b) {
        final byHit = b.hitCount.compareTo(a.hitCount);
        return byHit != 0 ? byHit : a.index.compareTo(b.index);
      });
    return RulesInfo(
      total: entries.length,
      typeCounts: typeCounts,
      proxyCounts: proxyCounts,
      disabledCount: disabled,
      providerBackedCount: providerBacked,
      hitTotal: hits,
      missTotal: misses,
      topHitRules: topN < byHits.length ? byHits.sublist(0, topN) : byHits,
      entries: entries,
    );
  }

  List<MapEntry<String, int>> get sortedTypes => sortedCounts(typeCounts);
  List<MapEntry<String, int>> get sortedProxies => sortedCounts(proxyCounts);
  List<MapEntry<String, int>> topTypes(int n) => topEntries(typeCounts, n);
  List<MapEntry<String, int>> topProxies(int n) => topEntries(proxyCounts, n);

  /// Hit rate over all evaluations (`0.0` when nothing was evaluated).
  double get hitRate =>
      hitTotal + missTotal == 0 ? 0 : hitTotal / (hitTotal + missTotal);

  final int total;
  final Map<String, int> typeCounts;
  final Map<String, int> proxyCounts;
  final int disabledCount;
  final int providerBackedCount;
  final int hitTotal;
  final int missTotal;
  final List<RuleEntry> topHitRules;
  final List<RuleEntry> entries;
}

/// One rule from `/rules`.
class RuleEntry {
  const RuleEntry({
    this.index = 0,
    this.type = '',
    this.payload = '',
    this.proxy = '',
    this.size = -1,
    this.disabled = false,
    this.hitCount = 0,
    this.missCount = 0,
  });

  factory RuleEntry.fromJson(Map<String, dynamic> json) {
    final extra = _map(json['extra']);
    return RuleEntry(
      index: _int(json['index']),
      type: _string(json['type']),
      payload: _string(json['payload']),
      proxy: _string(json['proxy']),
      size: _int(json['size']),
      disabled: _bool(extra['disabled']),
      hitCount: _int(extra['hitCount']),
      missCount: _int(extra['missCount']),
    );
  }

  final int index;
  final String type;
  final String payload;
  final String proxy;
  final int size;
  final bool disabled;
  final int hitCount;
  final int missCount;
}

// ── /connections ──────────────────────────────────────────────────────────

/// Summary of `GET /connections`.
class ConnectionsInfo {
  const ConnectionsInfo({
    this.total = 0,
    this.uploadTotal = 0,
    this.downloadTotal = 0,
    this.memoryInuse = 0,
    this.networkCounts = const <String, int>{},
    this.inboundCounts = const <String, int>{},
    this.kindCounts = const <String, int>{},
    this.ruleCounts = const <String, int>{},
    this.topConnections = const <ConnectionEntry>[],
    this.entries = const <ConnectionEntry>[],
  });

  factory ConnectionsInfo.fromJson(
    Map<String, dynamic>? json, {
    int topN = 10,
  }) {
    final data = json ?? const <String, dynamic>{};
    final entries = _mapList(
      data['connections'],
    ).map(ConnectionEntry.fromJson).toList(growable: false);
    return ConnectionsInfo.fromEntries(
      entries,
      uploadTotal: _int(data['uploadTotal']),
      downloadTotal: _int(data['downloadTotal']),
      memoryInuse: _int(data['memory']),
      topN: topN,
    );
  }

  factory ConnectionsInfo.fromEntries(
    List<ConnectionEntry> entries, {
    int uploadTotal = 0,
    int downloadTotal = 0,
    int memoryInuse = 0,
    int topN = 10,
  }) {
    final byTraffic = entries.toList()
      ..sort((a, b) {
        final byTraffic = b.totalBytes.compareTo(a.totalBytes);
        return byTraffic != 0 ? byTraffic : a.id.compareTo(b.id);
      });
    return ConnectionsInfo(
      total: entries.length,
      uploadTotal: uploadTotal,
      downloadTotal: downloadTotal,
      memoryInuse: memoryInuse,
      networkCounts: countByValue(entries, (e) => e.network),
      inboundCounts: countByValue(entries, (e) => e.inboundName),
      kindCounts: countByValue(entries, (e) => e.kind),
      ruleCounts: countByValue(entries, (e) => e.rule),
      topConnections: topN < byTraffic.length
          ? byTraffic.sublist(0, topN)
          : byTraffic,
      entries: entries,
    );
  }

  List<MapEntry<String, int>> get sortedNetworks => sortedCounts(networkCounts);
  List<MapEntry<String, int>> get sortedInbound => sortedCounts(inboundCounts);
  List<MapEntry<String, int>> get sortedKinds => sortedCounts(kindCounts);
  List<MapEntry<String, int>> get sortedRules => sortedCounts(ruleCounts);

  /// Sum of per-connection bytes (may differ from the controller totals,
  /// which include closed connections).
  int get summedUpload => entries.fold(0, (sum, e) => sum + e.upload);
  int get summedDownload => entries.fold(0, (sum, e) => sum + e.download);

  final int total;
  final int uploadTotal;
  final int downloadTotal;
  final int memoryInuse;
  final Map<String, int> networkCounts;
  final Map<String, int> inboundCounts;
  final Map<String, int> kindCounts;
  final Map<String, int> ruleCounts;
  final List<ConnectionEntry> topConnections;
  final List<ConnectionEntry> entries;
}

/// One connection from `/connections`.
class ConnectionEntry {
  const ConnectionEntry({
    this.id = '',
    this.host = '',
    this.network = '',
    this.kind = '',
    this.inboundName = '',
    this.rule = '',
    this.rulePayload = '',
    this.upload = 0,
    this.download = 0,
    this.start = '',
    this.chains = const <String>[],
  });

  factory ConnectionEntry.fromJson(Map<String, dynamic> json) {
    final meta = _map(json['metadata']);
    return ConnectionEntry(
      id: _string(json['id']),
      host: _string(meta['host']),
      network: _string(meta['network']),
      kind: _string(meta['type']),
      inboundName: _string(meta['inboundName']),
      rule: _string(json['rule']),
      rulePayload: _string(json['rulePayload']),
      upload: _int(json['upload']),
      download: _int(json['download']),
      start: _string(json['start']),
      chains: _stringList(json['chains']),
    );
  }

  int get totalBytes => upload + download;

  /// Depth of the proxy chain (`chains.length`, e.g. leaf -> group -> policy).
  int get chainDepth => chains.length;

  final String id;
  final String host;
  final String network;
  final String kind;
  final String inboundName;
  final String rule;
  final String rulePayload;
  final int upload;
  final int download;
  final String start;
  final List<String> chains;
}

// ── /traffic ──────────────────────────────────────────────────────────────

/// One tick (or the latest tick) of the streaming `GET /traffic`.
class TrafficInfo {
  const TrafficInfo({
    this.up = 0,
    this.down = 0,
    this.upTotal = 0,
    this.downTotal = 0,
    this.sampleCount = 0,
    this.maxUp = 0,
    this.maxDown = 0,
  });

  factory TrafficInfo.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return TrafficInfo(
      up: _int(data['up']),
      down: _int(data['down']),
      upTotal: _int(data['upTotal']),
      downTotal: _int(data['downTotal']),
      sampleCount: 1,
      maxUp: _int(data['up']),
      maxDown: _int(data['down']),
    );
  }

  /// Summarizes a captured stream: the latest tick plus per-tick maxima.
  factory TrafficInfo.fromStream(List<Map<String, dynamic>> samples) {
    if (samples.isEmpty) return const TrafficInfo();
    var maxUp = 0;
    var maxDown = 0;
    for (final sample in samples) {
      if (_int(sample['up']) > maxUp) maxUp = _int(sample['up']);
      if (_int(sample['down']) > maxDown) maxDown = _int(sample['down']);
    }
    final latest = TrafficInfo.fromJson(samples.last);
    return TrafficInfo(
      up: latest.up,
      down: latest.down,
      upTotal: latest.upTotal,
      downTotal: latest.downTotal,
      sampleCount: samples.length,
      maxUp: maxUp,
      maxDown: maxDown,
    );
  }

  final int up;
  final int down;
  final int upTotal;
  final int downTotal;
  final int sampleCount;
  final int maxUp;
  final int maxDown;
}

// ── /memory ───────────────────────────────────────────────────────────────

/// One tick (or the latest tick) of the streaming `GET /memory`.
class MemoryInfo {
  const MemoryInfo({
    this.inuse = 0,
    this.oslimit = 0,
    this.sampleCount = 0,
    this.maxInuse = 0,
  });

  factory MemoryInfo.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return MemoryInfo(
      inuse: _int(data['inuse']),
      oslimit: _int(data['oslimit']),
      sampleCount: 1,
      maxInuse: _int(data['inuse']),
    );
  }

  factory MemoryInfo.fromStream(List<Map<String, dynamic>> samples) {
    if (samples.isEmpty) return const MemoryInfo();
    var maxInuse = 0;
    for (final sample in samples) {
      if (_int(sample['inuse']) > maxInuse) maxInuse = _int(sample['inuse']);
    }
    final latest = MemoryInfo.fromJson(samples.last);
    return MemoryInfo(
      inuse: latest.inuse,
      oslimit: latest.oslimit,
      sampleCount: samples.length,
      maxInuse: maxInuse,
    );
  }

  final int inuse;
  final int oslimit;
  final int sampleCount;
  final int maxInuse;
}

// ── /logs ─────────────────────────────────────────────────────────────────

/// Summary of captured `GET /logs` stream lines (`{"type":..,"payload":..}`).
class LogsInfo {
  const LogsInfo({
    this.sampleCount = 0,
    this.typeCounts = const <String, int>{},
    this.latest = const <LogEntry>[],
    this.entries = const <LogEntry>[],
  });

  factory LogsInfo.fromJsonLines(
    List<Map<String, dynamic>> lines, {
    int latestN = 10,
  }) {
    final entries = lines.map(LogEntry.fromJson).toList(growable: false);
    final latest = latestN < entries.length
        ? entries.sublist(entries.length - latestN)
        : entries;
    return LogsInfo(
      sampleCount: entries.length,
      typeCounts: countByValue(entries, (e) => e.type),
      latest: latest,
      entries: entries,
    );
  }

  int countOfType(String type) => typeCounts[type] ?? 0;

  int get warningCount => countOfType('warning');
  int get errorCount => countOfType('error');
  int get infoCount => countOfType('info');

  final int sampleCount;
  final Map<String, int> typeCounts;
  final List<LogEntry> latest;
  final List<LogEntry> entries;
}

/// One log line from `/logs`.
class LogEntry {
  const LogEntry({this.type = '', this.payload = ''});

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      LogEntry(type: _string(json['type']), payload: _string(json['payload']));

  final String type;
  final String payload;
}

// ── All nine bundled ──────────────────────────────────────────────────────

/// Bundles the nine endpoint summaries so an Info dashboard can consume
/// one object. Streaming endpoints accept either a single tick map or a
/// captured list of lines.
class MihomoInfoSummary {
  const MihomoInfoSummary({
    required this.version,
    required this.configs,
    required this.proxies,
    required this.groups,
    required this.rules,
    required this.connections,
    required this.traffic,
    required this.memory,
    required this.logs,
  });

  factory MihomoInfoSummary.fromAll({
    Map<String, dynamic>? version,
    Map<String, dynamic>? configs,
    Map<String, dynamic>? proxies,
    Map<String, dynamic>? group,
    Map<String, dynamic>? rules,
    Map<String, dynamic>? connections,
    List<Map<String, dynamic>>? trafficStream,
    Map<String, dynamic>? traffic,
    List<Map<String, dynamic>>? memoryStream,
    Map<String, dynamic>? memory,
    List<Map<String, dynamic>>? logLines,
    Map<String, dynamic>? logs,
  }) {
    return MihomoInfoSummary(
      version: VersionInfo.fromJson(version),
      configs: ConfigsInfo.fromJson(configs),
      proxies: ProxiesInfo.fromJson(proxies),
      groups: GroupsInfo.fromJson(group),
      rules: RulesInfo.fromJson(rules),
      connections: ConnectionsInfo.fromJson(connections),
      traffic: trafficStream != null
          ? TrafficInfo.fromStream(trafficStream)
          : TrafficInfo.fromJson(traffic),
      memory: memoryStream != null
          ? MemoryInfo.fromStream(memoryStream)
          : MemoryInfo.fromJson(memory),
      logs: LogsInfo.fromJsonLines(
        logLines ?? (logs != null ? [logs] : const <Map<String, dynamic>>[]),
      ),
    );
  }

  final VersionInfo version;
  final ConfigsInfo configs;
  final ProxiesInfo proxies;
  final GroupsInfo groups;
  final RulesInfo rules;
  final ConnectionsInfo connections;
  final TrafficInfo traffic;
  final MemoryInfo memory;
  final LogsInfo logs;
}
