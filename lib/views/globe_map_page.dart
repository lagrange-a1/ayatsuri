/*
 * 3D globe page: a real rotating Earth (native `flutter_earth_globe`) where
 * tapping a country opens a popup panel with the matching proxy nodes.
 *
 * Taps arrive as (latitude, longitude); `geo_hit_test` resolves them
 * against the bundled Natural Earth 110m GeoJSON (`assets/globe/`) to a
 * country alpha-2, and available countries get tappable marker points on
 * the globe (the fallback for small countries that are hard to tap).
 * Dart then shows a modal bottom sheet listing the candidate nodes.
 *
 * Tap-vs-drag disambiguation: `flutter_earth_globe` fires `onTap` on
 * tap-down, which also fires at the start of every rotate drag. A tap is
 * therefore only acted on if the globe rotation is unchanged ~300ms later.
 */

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';

import '../endpoints.dart';
import '../proxies/country_map.dart';
import '../proxies/geo_hit_test.dart';
import '../proxies/proxy_service.dart';

class GlobeMapPage extends StatefulWidget {
  const GlobeMapPage({super.key, required this.api});

  final MihomoAPI api;

  @override
  State<GlobeMapPage> createState() => _GlobeMapPageState();
}

class _GlobeMapPageState extends State<GlobeMapPage> {
  late final ProxySelection _selection;
  late final FlutterEarthGlobeController _globeController;
  CountryShapes? _shapes;
  final Set<String> _pointIds = {};
  String? _selectedAlpha2;
  String? _hoverAlpha2;
  String? _loadError;
  Timer? _tapTimer;
  int _tapToken = 0;

  /// In widget tests the globe's shader/texture pipeline is unavailable;
  /// render a placeholder instead.
  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _selection = ProxySelection(api: widget.api);
    _globeController = FlutterEarthGlobeController(
      // Match the upstream example's setup: day surface + night surface.
      surface: const AssetImage('assets/globe/earth-day.jpg'),
      nightSurface: const AssetImage('assets/globe/earth-night.jpg'),
      isRotating: false,
      isZoomEnabled: true,
      zoom: 0.5,
      minZoom: -1.5,
      maxZoom: 5,
    );
    _globeController.onLoaded = () => _focusAsia();
    unawaited(_initGeoData());
    unawaited(_loadSelection());
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    // The package's dispose() touches a late AnimationController that only
    // the globe widget initializes; in tests the globe is never built.
    if (!_isTest) _globeController.dispose();
    super.dispose();
  }

  Future<void> _initGeoData() async {
    try {
      final text = await rootBundle.loadString(
        'assets/globe/countries.geojson',
      );
      if (!mounted) return;
      setState(() => _shapes = parseCountryShapes(text));
      // Start facing Asia, where most of this project's nodes are. The
      // globe state only exists after the first frame, so focus post-frame
      // (and again once the texture is ready, in case of an early call).
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusAsia());
      _globeController.onLoaded = () => _focusAsia();
      _syncPoints();
    } catch (e) {
      if (mounted) setState(() => _loadError = 'Globe data failed: $e');
    }
  }

  void _focusAsia() {
    _globeController.globeKey.currentState?.focusOnCoordinates(
      const GlobeCoordinates(28, 100),
      animate: false,
      duration: null,
    );
  }

  Future<void> _loadSelection() async {
    await _selection.load();
    if (!mounted) return;
    setState(() => _loadError = _selection.error);
    _syncPoints();
  }

  /// Marker points for every country that has candidate nodes, plus a
  /// larger labeled point for the selected country.
  void _syncPoints() {
    final shapes = _shapes;
    if (shapes == null || _isTest) return;
    for (final id in _pointIds) {
      _globeController.removePoint(id);
    }
    _pointIds.clear();

    final available = <String>{};
    for (final group in _selection.selectors) {
      for (final name in group.all) {
        final alpha2 = nameToFrontAlpha2(name);
        if (alpha2 != null) available.add(alpha2);
      }
    }
    for (final alpha2 in available) {
      final centroid = shapes.centroidFor(alpha2);
      if (centroid == null) continue;
      final id = 'country-$alpha2';
      final selected = alpha2 == _selectedAlpha2;
      _globeController.addPoint(
        Point(
          id: id,
          coordinates: GlobeCoordinates(centroid.$1, centroid.$2),
          label: selected ? (kCountries[alpha2]?.name ?? alpha2) : null,
          isLabelVisible: selected,
          style: PointStyle(
            color: selected ? const Color(0xFFC084FC) : const Color(0xFF38BDF8),
            size: selected ? 6 : 3,
          ),
          onTap: () => _onCountry(alpha2),
        ),
      );
      _pointIds.add(id);
    }
  }

  // ── Globe input ────────────────────────────────────────────────────

  void _onGlobeTap(GlobeCoordinates? coords) {
    if (coords == null || _shapes == null) return;
    final rotation = _rotationSnapshot();
    final token = ++_tapToken;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || token != _tapToken) return;
      // A rotate-drag changes the rotation; a genuine tap does not.
      if (_rotationSnapshot() != rotation) return;
      final alpha2 = _shapes?.alpha2At(coords.latitude, coords.longitude);
      if (alpha2 == null) return; // Ocean tap.
      _onCountry(alpha2);
    });
  }

  ({double x, double y, double z})? _rotationSnapshot() {
    final state = _globeController.globeKey.currentState;
    if (state == null) return null;
    return (x: state.rotationX, y: state.rotationY, z: state.rotationZ);
  }

  void _onGlobeHover(GlobeCoordinates? coords) {
    if (coords == null || _shapes == null) return;
    final alpha2 = _shapes!.alpha2At(coords.latitude, coords.longitude);
    if (alpha2 == _hoverAlpha2) return;
    setState(() => _hoverAlpha2 = alpha2);
  }

  Future<void> _onCountry(String alpha2) async {
    if (alpha2.isEmpty || alpha2 == '-99') return;
    if (!mounted) return;
    setState(() => _selectedAlpha2 = alpha2);
    _syncPoints();
    if (!_selection.loaded) {
      await _loadSelection();
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CountrySheet(
        selection: _selection,
        alpha2: alpha2,
        onSelected: (proxyName, groupName) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected $proxyName in $groupName')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoverPattern = _hoverAlpha2 == null ? null : kCountries[_hoverAlpha2];
    final selectedPattern = _selectedAlpha2 == null
        ? null
        : kCountries[_selectedAlpha2];
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        title: const Text('Select a node · Globe'),
        actions: [
          IconButton(
            onPressed: _loadSelection,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload proxies',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isTest)
            const Center(child: Text('Globe (3D unavailable in tests)'))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final radius =
                    (constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight) /
                    2 *
                    0.4;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: FlutterEarthGlobe(
                        radius: radius,
                        controller: _globeController,
                        onTap: _onGlobeTap,
                        onHover: _onGlobeHover,
                      ),
                    ),
                  ],
                );
              },
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
                    _selectedAlpha2 != null
                        ? 'Selected: ${selectedPattern?.flag ?? ''} '
                              '${selectedPattern?.name ?? _selectedAlpha2}'
                        : hoverPattern != null
                        ? '${hoverPattern.flag} ${hoverPattern.name}'
                        : 'Tap a country',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          if (_loadError != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loadError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Popup panel listing the nodes that match one tapped country.
///
/// Candidates are shown immediately (with their last-known delay); each row's
/// delay then fills in as its probe completes.
class _CountrySheet extends StatefulWidget {
  const _CountrySheet({
    required this.selection,
    required this.alpha2,
    required this.onSelected,
  });

  final ProxySelection selection;
  final String alpha2;
  final void Function(String proxyName, String groupName) onSelected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  late List<ProxyCandidate> _candidates;
  int _generation = 0;
  String? _selecting;

  @override
  void initState() {
    super.initState();
    _candidates = widget.selection.candidatesForMapId(widget.alpha2);
    _probeAll();
  }

  void _probeAll() {
    final gen = ++_generation;
    for (final candidate in _candidates) {
      widget.selection.probeByName(candidate.proxy.name).then((_) {
        if (!mounted || gen != _generation) return;
        setState(
          () =>
              _candidates = widget.selection.candidatesForMapId(widget.alpha2),
        );
      });
    }
  }

  Future<void> _onTap(ProxyCandidate candidate) async {
    if (_selecting != null) return;
    setState(() => _selecting = candidate.proxy.name);
    try {
      await widget.selection.select(candidate.group.name, candidate.proxy.name);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _selecting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.message ?? e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    await widget.selection.load();
    if (!mounted) return;
    setState(() {
      _selecting = null;
      _candidates = widget.selection.candidatesForMapId(widget.alpha2);
    });
    widget.onSelected(candidate.proxy.name, candidate.group.name);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pattern = kCountries[widget.alpha2];
    final scheme = Theme.of(context).colorScheme;
    final error = widget.selection.error;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  pattern?.flag ?? flagForAlpha2(widget.alpha2),
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pattern?.name ?? widget.alpha2,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${widget.alpha2} · ${_candidates.length} node(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    error != null
                        ? 'Failed to load proxies:\n$error'
                        : 'No matching node for this country.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _candidates.map((candidate) {
                    final delay = candidate.proxy.delay;
                    final color = delayColor(delay);
                    return ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              candidate.proxy.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      title: Text(candidate.group.name),
                      subtitle: Text(
                        delayLabel(delay),
                        style: TextStyle(color: color),
                      ),
                      trailing: _selecting == candidate.proxy.name
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : candidate.isNow
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      tileColor: candidate.isNow
                          ? scheme.secondaryContainer
                          : null,
                      onTap: () => _onTap(candidate),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
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
