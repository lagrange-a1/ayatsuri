import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/re_highlight.dart';

import '../info/mihomo_info.dart';
import '../l10n/app_localizations.dart';

/// Structured dashboard for the Info tab.
///
/// Renders [summary] (parsed from the nine controller endpoints by
/// `MihomoInfoSummary`) as header stat cards plus per-section summary
/// rows and bar breakdowns. Each section keeps a collapsible raw-JSON
/// fallback ([rawBySection]) for the original payload.
class InfoDashboard extends StatelessWidget {
  const InfoDashboard({
    super.key,
    required this.summary,
    required this.rawBySection,
  });

  final MihomoInfoSummary summary;

  /// Raw payloads keyed by section id (`version`, `configs`, ...).
  final Map<String, Map<String, dynamic>?> rawBySection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _StatCards(summary: summary),
        const SizedBox(height: 8),
        _VersionSection(summary: summary, raw: rawBySection['version']),
        _ConfigsSection(summary: summary, raw: rawBySection['configs']),
        _ProxiesSection(summary: summary, raw: rawBySection['proxies']),
        _GroupsSection(summary: summary, raw: rawBySection['groups']),
        _RulesSection(summary: summary, raw: rawBySection['rules']),
        _ConnectionsSection(summary: summary, raw: rawBySection['connections']),
        _TrafficSection(summary: summary, raw: rawBySection['traffic']),
        _MemorySection(summary: summary, raw: rawBySection['memory']),
        _LogsSection(summary: summary, raw: rawBySection['logs']),
      ],
    );
  }
}

/// Header stat cards: version + the big counts + traffic + memory.
class _StatCards extends StatelessWidget {
  const _StatCards({required this.summary});

  final MihomoInfoSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = <_Stat>[];
    if (summary.version.version.isNotEmpty) {
      cards.add(
        _Stat(
          icon: Icons.info_outline,
          value: summary.version.version,
          label: l10n.summaryVersion,
        ),
      );
    }
    cards.addAll([
      _Stat(
        icon: Icons.vpn_key_outlined,
        value: '${summary.proxies.total}',
        label: l10n.summaryProxyCount,
      ),
      _Stat(
        icon: Icons.group_work_outlined,
        value: '${summary.groups.total}',
        label: l10n.summaryGroupCount,
      ),
      _Stat(
        icon: Icons.rule_outlined,
        value: '${summary.rules.total}',
        label: l10n.summaryRuleCount,
      ),
      _Stat(
        icon: Icons.cable_outlined,
        value: '${summary.connections.total}',
        label: l10n.summaryConnectionCount,
      ),
      _Stat(
        icon: Icons.memory_outlined,
        value: formatBytes(summary.memory.inuse),
        label: l10n.summaryMemoryInUse,
      ),
      _Stat(
        icon: Icons.arrow_upward,
        value: formatRate(summary.traffic.up),
        label: l10n.summaryTrafficUp,
      ),
      _Stat(
        icon: Icons.arrow_downward,
        value: formatRate(summary.traffic.down),
        label: l10n.summaryTrafficDown,
      ),
    ]);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards.map((s) => _StatCard(stat: s)).toList(),
    );
  }
}

class _Stat {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stat.icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                stat.value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(stat.label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// One summary label/value row.
class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// One labelled breakdown bar (`label  █████  42`).
class BreakdownBar extends StatelessWidget {
  const BreakdownBar({
    super.key,
    required this.label,
    required this.count,
    required this.maxCount,
  });

  final String label;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : (count / maxCount).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 44, child: Text('$count', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// Renders a sorted count map as a list of [BreakdownBar]s (empty-safe).
Widget breakdownBars(List<MapEntry<String, int>> sorted) {
  if (sorted.isEmpty) return const SizedBox.shrink();
  final maxCount = sorted.first.value;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final e in sorted)
        BreakdownBar(label: e.key, count: e.value, maxCount: maxCount),
    ],
  );
}

/// Section card wrapper: title, body widgets, raw-JSON fallback.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.raw,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
            if (raw != null)
              ExpansionTile(
                title: Text(
                  'Raw JSON',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: [RawJsonView(data: raw!)],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sections ───────────────────────────────────────────────────────────────

class _VersionSection extends StatelessWidget {
  const _VersionSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final v = summary.version;
    return SectionCard(
      title: l10n.sectionVersion,
      icon: Icons.info_outline,
      raw: raw,
      children: [
        SummaryRow(
          label: l10n.summaryVersion,
          value: v.version.isEmpty ? '-' : v.version,
        ),
        SummaryRow(label: l10n.summaryMeta, value: v.meta ? 'true' : 'false'),
        // Go version / preview are not in this controller payload; show
        // the raw keys if a future version adds them.
        if (raw != null && raw!.containsKey('goVersion'))
          SummaryRow(
            label: l10n.summaryGoVersion,
            value: '${raw!['goVersion']}',
          ),
        if (raw != null && raw!.containsKey('preview'))
          SummaryRow(label: l10n.summaryPreview, value: '${raw!['preview']}'),
      ],
    );
  }
}

class _ConfigsSection extends StatelessWidget {
  const _ConfigsSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  static String _yn(bool b) => b ? 'true' : 'false';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = summary.configs;
    return SectionCard(
      title: l10n.sectionConfigs,
      icon: Icons.settings_outlined,
      raw: raw,
      children: [
        SummaryRow(
          label: l10n.summaryMode,
          value: c.mode.isEmpty ? '-' : c.mode,
        ),
        SummaryRow(
          label: l10n.summaryLogLevel,
          value: c.logLevel.isEmpty ? '-' : c.logLevel,
        ),
        SummaryRow(label: l10n.summaryAllowLan, value: _yn(c.allowLan)),
        SummaryRow(label: l10n.summaryIPv6, value: _yn(c.ipv6)),
        SummaryRow(label: l10n.summaryTunEnable, value: _yn(c.tunEnabled)),
        if (c.tunEnabled) ...[
          SummaryRow(
            label: 'TUN device',
            value: c.tunDevice.isEmpty ? '-' : c.tunDevice,
          ),
          SummaryRow(
            label: 'TUN stack',
            value: c.tunStack.isEmpty ? '-' : c.tunStack,
          ),
          SummaryRow(label: 'TUN MTU', value: '${c.tunMtu}'),
        ],
        for (final e in c.activePorts.entries)
          SummaryRow(label: e.key, value: '${e.value}'),
        SummaryRow(
          label: l10n.summarySystemProxy,
          value: _yn(
            c.raw.containsKey('system-proxy') && c.raw['system-proxy'] == true,
          ),
        ),
      ],
    );
  }
}

class _ProxiesSection extends StatelessWidget {
  const _ProxiesSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = summary.proxies;
    return SectionCard(
      title: l10n.sectionProxies,
      icon: Icons.vpn_key_outlined,
      raw: raw,
      children: [
        SummaryRow(label: l10n.summaryProxyCount, value: '${p.total}'),
        SummaryRow(label: 'Alive', value: '${p.aliveCount}'),
        SummaryRow(label: 'Dead', value: '${p.deadCount}'),
        if (p.probedCount > 0) ...[
          SummaryRow(label: 'Avg delay', value: '${p.averageDelay} ms'),
          SummaryRow(label: 'Min delay', value: '${p.minDelay} ms'),
          SummaryRow(label: 'Max delay', value: '${p.maxDelay} ms'),
        ],
        const SizedBox(height: 8),
        breakdownBars(proxiesTopTypes(p)),
      ],
    );
  }
}

/// Proxy types in display order (all types, deterministic).
List<MapEntry<String, int>> proxiesTopTypes(ProxiesInfo p) => p.sortedTypes;

class _GroupsSection extends StatelessWidget {
  const _GroupsSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = summary.groups;
    final proxyNames = summary.proxies.names.toSet();
    return SectionCard(
      title: l10n.sectionGroups,
      icon: Icons.group_work_outlined,
      raw: raw,
      children: [
        SummaryRow(label: l10n.summaryGroupCount, value: '${g.total}'),
        const SizedBox(height: 8),
        breakdownBars(sortedCounts(g.typeCounts)),
        const SizedBox(height: 8),
        for (final entry in g.sortedEntries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              '${entry.name} (${entry.type}) → ${g.chainFor(entry.name, proxyNames: proxyNames).join(' → ')}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _RulesSection extends StatelessWidget {
  const _RulesSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = summary.rules;
    return SectionCard(
      title: l10n.sectionRules,
      icon: Icons.rule_outlined,
      raw: raw,
      children: [
        SummaryRow(label: l10n.summaryRuleCount, value: '${r.total}'),
        SummaryRow(label: 'Disabled', value: '${r.disabledCount}'),
        SummaryRow(label: 'Provider-backed', value: '${r.providerBackedCount}'),
        SummaryRow(
          label: 'Hit rate',
          value: '${(r.hitRate * 100).toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        breakdownBars(r.sortedTypes.take(8).toList()),
        const SizedBox(height: 8),
        breakdownBars(r.sortedProxies.take(8).toList()),
      ],
    );
  }
}

class _ConnectionsSection extends StatelessWidget {
  const _ConnectionsSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = summary.connections;
    return SectionCard(
      title: l10n.sectionConnections,
      icon: Icons.cable_outlined,
      raw: raw,
      children: [
        SummaryRow(label: l10n.summaryConnectionCount, value: '${c.total}'),
        SummaryRow(
          label: l10n.summaryTrafficUp,
          value: formatBytes(c.uploadTotal),
        ),
        SummaryRow(
          label: l10n.summaryTrafficDown,
          value: formatBytes(c.downloadTotal),
        ),
        const SizedBox(height: 8),
        breakdownBars(c.sortedNetworks),
        breakdownBars(c.sortedInbound),
        breakdownBars(c.sortedKinds),
        const SizedBox(height: 8),
        for (final e in c.topConnections.take(5))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${e.host.isEmpty ? e.id : e.host} · ${formatBytes(e.totalBytes)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _TrafficSection extends StatelessWidget {
  const _TrafficSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = summary.traffic;
    return SectionCard(
      title: l10n.sectionTraffic,
      icon: Icons.speed_outlined,
      raw: raw,
      children: [
        SummaryRow(label: l10n.summaryTrafficUp, value: formatRate(t.up)),
        SummaryRow(label: l10n.summaryTrafficDown, value: formatRate(t.down)),
        SummaryRow(label: 'Up total', value: formatBytes(t.upTotal)),
        SummaryRow(label: 'Down total', value: formatBytes(t.downTotal)),
        if (t.sampleCount > 1) ...[
          SummaryRow(label: 'Max up', value: formatRate(t.maxUp)),
          SummaryRow(label: 'Max down', value: formatRate(t.maxDown)),
        ],
      ],
    );
  }
}

class _MemorySection extends StatelessWidget {
  const _MemorySection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = summary.memory;
    return SectionCard(
      title: l10n.sectionMemory,
      icon: Icons.memory_outlined,
      raw: raw,
      children: [
        SummaryRow(label: l10n.summaryMemoryInUse, value: formatBytes(m.inuse)),
        SummaryRow(
          label: 'OS limit',
          value: m.oslimit == 0 ? '-' : formatBytes(m.oslimit),
        ),
        if (m.sampleCount > 1)
          SummaryRow(label: 'Max in use', value: formatBytes(m.maxInuse)),
        SummaryRow(label: l10n.summaryLastUpdated, value: '${m.sampleCount}'),
      ],
    );
  }
}

class _LogsSection extends StatelessWidget {
  const _LogsSection({required this.summary, required this.raw});

  final MihomoInfoSummary summary;
  final Map<String, dynamic>? raw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final logs = summary.logs;
    return SectionCard(
      title: l10n.sectionLogs,
      icon: Icons.list_alt_outlined,
      raw: raw,
      children: [
        SummaryRow(label: l10n.summaryLogCount, value: '${logs.sampleCount}'),
        const SizedBox(height: 8),
        breakdownBars(sortedCounts(logs.typeCounts)),
        const SizedBox(height: 8),
        for (final e in logs.latest.take(5))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '[${e.type}] ${e.payload}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Pretty raw JSON with syntax highlighting (moved from `main.dart` so the
/// dashboard owns the fallback rendering).
class RawJsonView extends StatefulWidget {
  const RawJsonView({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  State<RawJsonView> createState() => _RawJsonViewState();
}

class _RawJsonViewState extends State<RawJsonView> {
  static final Highlight _highlighter = Highlight()
    ..registerLanguages({'json': langJson});

  static String prettyJson(Map<String, dynamic> json) =>
      const JsonEncoder.withIndent('  ').convert(json);

  static Map<String, TextStyle> _batTheme(ColorScheme scheme) {
    final base = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );
    return {
      'attr': base.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
      'string': base.copyWith(color: scheme.secondary),
      'number': base.copyWith(color: scheme.tertiary),
      'literal': base.copyWith(
        color: scheme.error,
        fontWeight: FontWeight.w600,
      ),
      'keyword': base.copyWith(
        color: scheme.error,
        fontWeight: FontWeight.w600,
      ),
      'punctuation': base.copyWith(color: scheme.onSurfaceVariant),
    };
  }

  TextSpan _highlight(String code, ColorScheme scheme) {
    final result = _highlighter.highlight(code: code, language: 'json');
    final renderer = TextSpanRenderer(
      TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: scheme.onSurfaceVariant,
      ),
      _batTheme(scheme),
    );
    result.render(renderer);
    return renderer.span ??
        TextSpan(
          text: code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final span = _highlight(prettyJson(widget.data), scheme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SelectableText.rich(span),
    );
  }
}
