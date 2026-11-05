/*
 * 3D globe page: a real rotating Earth (native `flutter_earth_globe`) where
 * tapping a country opens a popup panel with the matching proxy nodes.
 *
 * Taps arrive as (latitude, longitude); `country_shapes` resolves them
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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ayatsuri/l10n/app_localizations.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';

import '../endpoints.dart';
import '../proxies/country_map.dart';
import '../proxies/country_shapes.dart';
import '../proxies/proxy_service.dart';
import '../settings/app_settings.dart';
import '../platform/test_guard.dart';

class GlobeMapPage extends StatefulWidget {
  const GlobeMapPage({super.key, required this.api, this.settingsController});

  final MihomoAPI api;
  final AppSettingsController? settingsController;

  @override
  State<GlobeMapPage> createState() => _GlobeMapPageState();
}

class _GlobeMapPageState extends State<GlobeMapPage> {
  // Default to an empty selection (and settings) so a restart/rebuild path
  // that uses State before initState finishes never hits
  // LateInitializationError; initState swaps in the real instances.
  ProxySelection _selection = ProxySelection();
  late final FlutterEarthGlobeController _globeController;
  CountryShapes? _shapes;
  final Set<String> _pointIds = {};
  String? _selectedAlpha2;

  /// Country of the node the Mihomo kernel is actually running now
  /// (first selector group's `now`), refreshed on every load. The title
  /// shows this kernel state, not just the user's last tap.
  String? _kernelAlpha2;
  String? _hoverAlpha2;
  String? _loadError;
  bool _globeDataError = false;
  Timer? _tapTimer;
  Timer? _probeTimer;
  bool _probingAll = false;
  int _tapToken = 0;
  AppSettingsController _settings = AppSettingsController();

  AppSettings get _s => _settings.settings;

  /// In widget tests the globe's shader/texture pipeline is unavailable;
  /// render a placeholder instead.
  bool get _isTest => isFlutterTest;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsController ?? AppSettingsController();
    _settings.addListener(_onSettingsChanged);
    _restartProbeTimer();
    _selection = ProxySelection(api: widget.api);
    _globeController = FlutterEarthGlobeController(
      // Match the upstream example's setup: day surface + night surface.
      surface: const AssetImage('assets/globe/earth-day.jpg'),
      nightSurface: const AssetImage('assets/globe/earth-night.jpg'),
      isRotating: _s.autoRotate,
      rotationSpeed: _s.rotationSpeed,
      isZoomEnabled: true,
      zoom: 0.5,
      minZoom: -1.5,
      maxZoom: 5,
    );
    _globeController.onLoaded = _focusInitial;
    unawaited(_initGeoData());
    unawaited(_loadSelection());
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _tapTimer?.cancel();
    _probeTimer?.cancel();
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusInitial());
      _globeController.onLoaded = _focusInitial;
      _syncPoints();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _globeDataError = true;
        });
      }
    }
  }

  /// Resolve the initial-view target as (lat, lng). For `auto` this is the
  /// currently running node's country centroid once known; falling back to
  /// `latLngLat/Lng` for `auto` would land on Asia (28, 100), so `auto`
  /// must resolve through the kernel country first.
  (double, double) _initialTarget() {
    if (_s.initialView == InitialView.auto) {
      final alpha2 = _kernelAlpha2 ?? _selectedAlpha2;
      final centroid = alpha2 != null ? _shapes?.centroidFor(alpha2) : null;
      if (centroid != null) return centroid;
    }
    return (_s.latLngLat, _s.latLngLng);
  }

  void _focusInitial() {
    final target = _initialTarget();
    _globeController.globeKey.currentState?.focusOnCoordinates(
      GlobeCoordinates(target.$1, target.$2),
      animate: false,
      duration: null,
    );
  }

  (InitialView, double, double)? _appliedInitialView;

  void _onSettingsChanged() {
    if (!mounted) return;
    final s = _s;
    // Apply the initial view once settings are in (and whenever the user
    // changes it); without this the globe stays on its rotation-0 view
    // (Europe/Africa) because the settings load finishes after the first
    // frame, when the early focus calls find no globe state yet.
    final viewKey = (s.initialView, s.customLat, s.customLng);
    if (viewKey != _appliedInitialView) {
      _appliedInitialView = viewKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusInitial();
      });
    }
    _restartProbeTimer(immediate: _probeTimer == null);
    if (!_isTest) {
      // NOTE: assigning `controller.isRotating` alone only flips a flag;
      // the animation keeps running. Use the start/stop methods so
      // turning auto-rotate off actually stops the globe.
      if (s.autoRotate && !_globeController.isRotating) {
        _globeController.startRotation();
      } else if (!s.autoRotate && _globeController.isRotating) {
        _globeController.stopRotation();
      }
      _globeController.setRotationSpeed(s.rotationSpeed);
    }
    _syncPoints();
    if (mounted) setState(() {});
  }

  Future<void> _loadSelection() async {
    await _selection.load();
    if (!mounted) return;
    setState(() {
      _loadError = _selection.error;
      _globeDataError = false;
    });
    _refreshKernelCountry();
    _maybeResolveAutoView();
    _restartProbeTimer(immediate: true);
    _syncPoints();
  }

  /// Recompute the kernel's currently running node country from the
  /// freshly loaded proxy groups.
  void _refreshKernelCountry() {
    final alpha2 = kernelCountryAlpha2(_selection.selectors);
    if (alpha2 != null && _kernelAlpha2 != alpha2) {
      setState(() => _kernelAlpha2 = alpha2);
    }
  }

  /// Effective periodic-probe interval: null when disabled (setting -1,
  /// or more than 100 proxies — probing thousands of nodes every few
  /// seconds is wasteful, so the timer stays off there).
  Duration? _effectiveProbeInterval() {
    final count = _selection.proxies.length;
    if (count == 0 || count > 100) return null;
    final seconds = _s.probeIntervalSec;
    if (seconds < 0) return null;
    return Duration(seconds: seconds < 5 ? 5 : seconds);
  }

  void _restartProbeTimer({bool immediate = false}) {
    _probeTimer?.cancel();
    _probeTimer = null;
    if (_isTest) return;
    final interval = _effectiveProbeInterval();
    if (interval == null) return;
    _probeTimer = Timer.periodic(interval, (_) => _probeAllNodes());
    // On (re)load and on off→on transitions, start the first sweep right
    // away instead of waiting a full interval; _probeAllNodes no-ops
    // until the selection is loaded.
    if (immediate) Timer(Duration.zero, _probeAllNodes);
  }

  /// Clash Verge Rev-style background probing: test every known proxy so
  /// delays are fresh before the user even taps a country. The bottom
  /// sheet still shows the last-known delay first, then updates live.
  Future<void> _probeAllNodes() async {
    if (_probingAll || !_selection.loaded) return;
    final names = <String>{};
    for (final group in _selection.selectors) {
      names.addAll(group.all);
    }
    if (names.isEmpty) return;
    _probingAll = true;
    try {
      final list = names.toList();
      // Bounded concurrency so a full sweep does not hammer the core.
      for (var i = 0; i < list.length; i += 16) {
        if (!mounted) return;
        await Future.wait(list.skip(i).take(16).map(_selection.probeByName));
      }
    } finally {
      _probingAll = false;
    }
  }

  /// Initial view "auto": resolve the currently-selected proxy's country
  /// once, select it, and focus the globe on it.
  void _maybeResolveAutoView() {
    if (_s.initialView != InitialView.auto || _selectedAlpha2 != null) return;
    final alpha2 = kernelCountryAlpha2(_selection.selectors);
    if (alpha2 == null) return;
    _selectedAlpha2 = alpha2;
    final centroid = _shapes?.centroidFor(alpha2);
    if (centroid != null && !_isTest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _globeController.globeKey.currentState?.focusOnCoordinates(
          GlobeCoordinates(centroid.$1, centroid.$2),
          animate: false,
          duration: null,
        );
      });
    }
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
            // Quadratic so the 0.5x-2x slider range is clearly visible
            // (linear 3px*scale is only a few pixels on screen).
            size: (selected ? 8 : 4) * _s.markerScale * _s.markerScale,
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
        maxDelayMs: _s.maxDelayMs,
        hideBlocked: _s.hideBlocked,
        probeSort: _s.probeSort,
        compact: _s.compactNodeList,
        onSelected: (proxyName, groupName) {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.selectedSnack(proxyName, groupName))),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hoverPattern = _hoverAlpha2 == null ? null : kCountries[_hoverAlpha2];
    final selectedPattern = _selectedAlpha2 == null
        ? null
        : kCountries[_selectedAlpha2];
    // Title tracks the kernel's running node, falling back to the user's
    // last tap when the kernel state is unknown.
    final titleAlpha2 = _kernelAlpha2 ?? _selectedAlpha2;
    final titlePattern = titleAlpha2 == null ? null : kCountries[titleAlpha2];
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        title: Text(
          titlePattern == null
              ? l10n.globeTitle
              : '${l10n.globeTitle} (${l10n.currentNode}: '
                    '${titlePattern.flag} ${titlePattern.name})',
        ),
        actions: [
          IconButton(
            onPressed: _loadSelection,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reloadProxies,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Custom background (cover) + readability scrim behind the globe.
          if (_settings.backgroundBytes != null) ...[
            Positioned.fill(
              child: Image.memory(
                _settings.backgroundBytes!,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: _s.backgroundOpacity),
              ),
            ),
          ],
          if (_isTest)
            Center(child: Text(l10n.globeTestPlaceholder))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final radius =
                    (constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight) /
                    2 *
                    0.45 *
                    _s.globeScale;
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
                        ? l10n.selectedCountry(
                            selectedPattern?.flag ?? '',
                            selectedPattern?.name ?? _selectedAlpha2!,
                          )
                        : hoverPattern != null
                        ? '${hoverPattern.flag} ${hoverPattern.name}'
                        : l10n.tapCountry,
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
                        _globeDataError
                            ? l10n.globeDataFailed(_loadError!)
                            : _loadError!,
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
    this.maxDelayMs = 0,
    this.hideBlocked = false,
    this.probeSort = ProbeSort.delay,
    this.compact = false,
  });

  final ProxySelection selection;
  final String alpha2;
  final void Function(String proxyName, String groupName) onSelected;
  final int maxDelayMs;
  final bool hideBlocked;
  final ProbeSort probeSort;
  final bool compact;

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
          content: Text(
            AppLocalizations.of(context).failed(e.message ?? e.toString()),
          ),
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

  List<ProxyCandidate> get _visibleCandidates {
    var list = _candidates.where((c) {
      final d = c.proxy.delay;
      if (widget.hideBlocked && d == 0) return false;
      if (widget.maxDelayMs > 0 && d != null && d > widget.maxDelayMs) {
        return false;
      }
      return true;
    }).toList();
    if (widget.probeSort == ProbeSort.delay) {
      list.sort((a, b) {
        final da = a.proxy.delay;
        final db = b.proxy.delay;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        // Timed-out and blocked nodes sort last, never as "fastest".
        final daBad = da == 0 || da == kDelayTimeout;
        final dbBad = db == 0 || db == kDelayTimeout;
        if (daBad && !dbBad) return 1;
        if (dbBad && !daBad) return -1;
        return da.compareTo(db);
      });
    } else {
      list.sort((a, b) => a.proxy.name.compareTo(b.proxy.name));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pattern = kCountries[widget.alpha2];
    final visible = _visibleCandidates;
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
                        l10n.nodesCount(widget.alpha2, visible.length),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: l10n.close,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    error != null
                        ? l10n.failedToLoadProxies(error)
                        : l10n.noMatchingNode,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: visible.map((candidate) {
                    final delay = candidate.proxy.delay;
                    final color = delayColor(delay);
                    return ListTile(
                      visualDensity: widget.compact
                          ? VisualDensity.compact
                          : VisualDensity.standard,
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
                        delayLabel(l10n, delay),
                        style: TextStyle(
                          color: color,
                          fontWeight: delay == kDelayTimeout
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
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
