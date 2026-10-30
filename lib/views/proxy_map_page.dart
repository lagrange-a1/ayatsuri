/*
 * Interactive world map page: tap a country, pick the matching node.
 *
 * The click returns a raw `interactive_world_map` map ID (ISO alpha-2 for
 * most countries, `X_<alpha-3>` for the overriden ones).
 * `country_map.countryAlpha2FromMapId` collapses that back to the alpha-2 key
 * used by `country_map`.
 *
 * The map only renders the caller-provided countries, so the page selects the
 * largest region covering the groups in this config (Asia/Europe/Oceania).
 */

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:interactive_world_map/interactive_world_map.dart';

import '../proxies/country_map.dart';
import '../proxies/proxy_service.dart';

import '../endpoints.dart';

class ProxyMapPage extends StatefulWidget {
  const ProxyMapPage({super.key, required this.api});

  final MihomoAPI api;

  @override
  State<ProxyMapPage> createState() => _ProxyMapPageState();
}

class _ProxyMapPageState extends State<ProxyMapPage> {
  final _controller = WorldMapController();
  late final ProxySelection _selection;
  List<ProxyCandidate> _candidates = [];
  String? _selectedId;
  Set<String>? _visibleIds;
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    _selection = ProxySelection(api: widget.api);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _selection.load();
    final ids = <String>{};
    for (final group in _selection.selectors) {
      for (final name in group.all) {
        final alpha2 = nameToFrontAlpha2(name);
        if (alpha2 != null) ids.add(alpha2);
      }
    }
    if (mounted) {
      setState(() {
        _visibleIds = ids.isEmpty ? kCountries.keys.toSet() : ids;
      });
    }
  }

  Future<void> _pick(String id) async {
    setState(() {
      _selectedId = id;
      _candidates = [];
      _probing = true;
    });
    await _selection.load();
    if (!mounted) return;
    setState(() => _candidates = _selection.candidatesForMapId(id));
    // Probe every candidate so the list shows real latencies.
    if (_candidates.isEmpty) {
      if (mounted) setState(() => _probing = false);
      return;
    }
    await Future.wait(
      _candidates.map((c) => _selection.probeByName(c.proxy.name)),
    );
    if (mounted) {
      setState(() {
        _candidates = _selection.candidatesForMapId(id);
        _probing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a node · World Map')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // ── Map ────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: InteractiveWorldMap(
                              controller: _controller,
                              allowPan: true,
                              allowZoom: true,
                              selectOnTap: false,
                              toggleSelectionOnTap: true,
                              onCountryTap: _pick,
                              style: const WorldMapStyle(
                                landFillColor: Color(0xFF202020),
                                selectedFillColor: Color(0xFF9C27B0),
                                borderColor: Color(0xFF404040),
                                borderWidth: 0.5,
                              ),
                              visibleCountryIds: _visibleIds,
                            ),
                          ),
                          Positioned(
                            left: 16,
                            top: 16,
                            child: _InfoPill(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.place, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Selected: ${_selectedId ?? 'None'}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ── Results ────────────────────────────────────────────
              Flexible(
                flex: 1,
                child: SizedBox.expand(
                  child: Card(
                    margin: const EdgeInsets.all(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nodes for ${_selectedId ?? '—'}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (_selectedId == null)
                            const Text('Tap a country on the map.')
                          else if (_probing)
                            const Text('Probing nodes...')
                          else if (_candidates.isEmpty)
                            const Text('No matching node for this country.')
                          else
                            Expanded(
                              child: ListView(
                                children: _candidates.map((candidate) {
                                  final delay = candidate.proxy.delay;
                                  final color = delayColor(delay);
                                  return ListTile(
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Colored status dot: unprobed/grey,
                                        // blocked/red, fast/green, slow/red.
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(candidate.proxy.name),
                                      ],
                                    ),
                                    title: Text(candidate.group.name),
                                    subtitle: Text(
                                      delayLabel(delay),
                                      style: TextStyle(color: color),
                                    ),
                                    isThreeLine: true,
                                    tileColor: candidate.isNow
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer
                                        : null,
                                    onTap: () => _onSelect(candidate),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onSelect(ProxyCandidate candidate) async {
    try {
      await _selection.select(candidate.group.name, candidate.proxy.name);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.message ?? e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }
    // Reload the group state so the card re-lists candidates with the new
    // node selected (`now`), and highlights it.
    await _selection.load();
    if (mounted && _selectedId != null) {
      setState(() => _candidates = _selection.candidatesForMapId(_selectedId!));
    }
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          child: child,
        ),
      ),
    );
  }
}
