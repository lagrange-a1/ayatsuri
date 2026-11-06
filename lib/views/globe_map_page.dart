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
import '../proxies/country_names.dart';
import '../proxies/country_shapes.dart';
import '../proxies/proxy_service.dart';
import '../settings/app_settings.dart';
import '../platform/test_guard.dart';

/// Theme-semantic delay colour. Thresholds preserve the proxy-service
/// contract exactly: <500 good, 500–5000 warning, >5000 / 0 / timeout
/// bad, null unprobed. Colours come from [ColorScheme] instead of
/// hard-coded `Colors.*` so contrast follows light/dark/seed themes.
Color _delayColorForTheme(ColorScheme scheme, int? delay) {
  if (delay == null) return scheme.outline;
  if (delay == kDelayTimeout || delay == 0) return scheme.error;
  if (delay < 500) return scheme.tertiary;
  if (delay < 5000) return scheme.secondary;
  return scheme.error;
}

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
  bool _selectionLoading = true;
  bool _geoLoading = true;
  bool _tapPending = false;
  DateTime? _lastProbeAt;
  Timer? _tapTimer;
  Timer? _probeTimer;
  Timer? _immediateProbeTimer;
  bool _probingAll = false;
  int _tapToken = 0;

  /// Proxy-service offline/error distinction (read-only contract from
  /// `proxy_service.dart`): unreachable/offline errors contain these
  /// markers; a genuinely empty proxy set has no error at all.
  bool _isOfflineError(String? error) {
    if (error == null) return false;
    final e = error.toLowerCase();
    return e.contains('unreachable') ||
        e.contains('offline') ||
        e.contains('connection') ||
        e.contains('connection refused') ||
        e.contains('socket');
  }

  String get _loadingText => _isChinese ? '加载中…' : 'Loading…';

  String get _oceanText =>
      _isChinese ? '海洋 — 这里没有国家' : 'Ocean — no country here';

  String get _dragText =>
      _isChinese ? '检测到拖动 — 不是点击' : 'Drag detected — not a tap';

  String get _probePausedText =>
      _isChinese ? '节点超过 100，周期测速已暂停' : 'Periodic probing paused (100+ nodes)';
  AppSettingsController _settings = AppSettingsController();

  AppSettings get _s => _settings.settings;

  bool get _isChinese => Localizations.localeOf(context).languageCode == 'zh';

  String _displayName(String alpha2) =>
      countryDisplayName(alpha2, chinese: _isChinese);

  /// In widget tests the globe's shader/texture pipeline is unavailable;
  /// render a placeholder instead.
  bool get _isTest => isFlutterTest;

  /// The visible surface currently bound to the controller. `globeTime`
  /// (system/day/night) and quality both feed into this, always resolved
  /// against the live platform brightness.
  String? _appliedSurface;

  /// Resolves the visible surface for the current settings + brightness.
  String _resolvedSurface() =>
      _s.surfaceAssetFor(MediaQuery.platformBrightnessOf(context));

  void _applySurface() {
    if (_isTest) return;
    final resolved = _resolvedSurface();
    if (resolved == _appliedSurface) return;
    _appliedSurface = resolved;
    _globeController.loadSurface(AssetImage(resolved));
    // The night texture stays bound for the day/night cycle; the visible
    // one above is whichever of day/night the time mode picks.
    _globeController.loadNightSurface(AssetImage(_s.nightSurfaceAsset));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Platform brightness can flip (system time switch) while the page
    // is alive; re-resolve the visible surface on every dependency change.
    _applySurface();
  }

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsController ?? AppSettingsController();
    _settings.addListener(_onSettingsChanged);
    _restartProbeTimer();
    _selection = ProxySelection(api: widget.api);
    _appliedSurface = _s.daySurfaceAsset;
    _globeController = FlutterEarthGlobeController(
      // Match the upstream example's setup: day surface + night surface.
      surface: AssetImage(_s.daySurfaceAsset),
      nightSurface: AssetImage(_s.nightSurfaceAsset),
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
    _immediateProbeTimer?.cancel();
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
      setState(() {
        _shapes = parseCountryShapes(text);
        _geoLoading = false;
      });
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
          _geoLoading = false;
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
      // Swap textures in place when the user switches 2K <-> 8K or
      // changes the globe time mode.
      _applySurface();
    }
    _syncPoints();
    if (mounted) setState(() {});
  }

  Future<void> _loadSelection() async {
    if (mounted) setState(() => _selectionLoading = true);
    await _selection.load();
    if (!mounted) return;
    setState(() {
      _selectionLoading = false;
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
    _immediateProbeTimer?.cancel();
    _immediateProbeTimer = null;
    if (_isTest) return;
    final interval = _effectiveProbeInterval();
    if (interval == null) return;
    _probeTimer = Timer.periodic(interval, (_) => _probeAllNodes());
    // On (re)load and on off→on transitions, start the first sweep right
    // away instead of waiting a full interval; _probeAllNodes no-ops
    // until the selection is loaded. Keep the zero-timer handle so it
    // can be cancelled on dispose/restart instead of firing blindly.
    if (immediate) _immediateProbeTimer = Timer(Duration.zero, _probeAllNodes);
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
      if (mounted) setState(() => _lastProbeAt = DateTime.now());
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
          label: selected ? _displayName(alpha2) : null,
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

  void _showTapFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onGlobeTap(GlobeCoordinates? coords) {
    if (coords == null || _shapes == null) return;
    final rotation = _rotationSnapshot();
    final token = ++_tapToken;
    // Instant feedback within the 300ms tap-vs-drag window instead of
    // silence: the pill shows a spinner while we wait.
    if (mounted) setState(() => _tapPending = true);
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || token != _tapToken) return;
      setState(() => _tapPending = false);
      // A rotate-drag changes the rotation; a genuine tap does not.
      // Previously this (and ocean taps) returned silently.
      if (_rotationSnapshot() != rotation) {
        _showTapFeedback(_dragText);
        return;
      }
      final alpha2 = _shapes?.alpha2At(coords.latitude, coords.longitude);
      if (alpha2 == null) {
        _showTapFeedback(_oceanText);
        return; // Ocean tap.
      }
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
    if (alpha2.isEmpty || alpha2 == '-99') {
      _showTapFeedback(AppLocalizations.of(context).noMatchingNode);
      return;
    }
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
      // fade/scale/spring/none animate the sheet *content* instead of
      // sliding the sheet itself; slide keeps the Material default.
      sheetAnimationStyle: _s.sheetAnimation == SheetAnimation.slide
          ? null
          : AnimationStyle.noAnimation,
      builder: (_) => _CountrySheet(
        selection: _selection,
        alpha2: alpha2,
        maxDelayMs: _s.maxDelayMs,
        hideBlocked: _s.hideBlocked,
        probeSort: _s.probeSort,
        compact: _s.compactNodeList,
        sheetAnimation: _s.sheetAnimation,
        onSelected: (proxyName, groupName) {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.selectedSnack(proxyName, groupName)),
                duration: const Duration(seconds: 6),
                behavior: SnackBarBehavior.floating,
              ),
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
    final loading = _selectionLoading || _geoLoading;
    final offline = _isOfflineError(_loadError) && !_globeDataError;
    final hasData = _selection.proxies.isNotEmpty;
    final isEmpty =
        !loading &&
        _loadError == null &&
        _selection.loaded &&
        _selection.proxies.isEmpty;
    final focusAlpha2 = _selectedAlpha2 ?? _hoverAlpha2;
    final globeLabel = focusAlpha2 != null
        ? _displayName(focusAlpha2)
        : l10n.tapCountry;
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      appBar: AppBar(
        title: Text(
          titlePattern == null
              ? l10n.globeTitle
              : '${l10n.globeTitle} (${l10n.currentNode}: '
                    '${titlePattern.flag} ${_displayName(titleAlpha2!)})',
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
                      // Screen-reader / keyboard access: the globe is a
                      // button whose label is the country *name* (not the
                      // flag emoji alone); Enter/Space opens the selected
                      // or hovered country. Marker Points have no semantics
                      // of their own, so this wrapper is the keyboard path.
                      child: Semantics(
                        container: true,
                        button: true,
                        label: globeLabel,
                        hint: l10n.tapCountry,
                        onTap: focusAlpha2 == null
                            ? null
                            : () => _onCountry(focusAlpha2),
                        child: FocusableActionDetector(
                          onShowFocusHighlight: (_) {},
                          child: Shortcuts(
                            shortcuts: {
                              SingleActivator(LogicalKeyboardKey.enter):
                                  _GlobeActivateIntent(),
                              SingleActivator(LogicalKeyboardKey.space):
                                  _GlobeActivateIntent(),
                            },
                            child: Actions(
                              actions: {
                                _GlobeActivateIntent: CallbackAction(
                                  onInvoke: (_) {
                                    if (focusAlpha2 != null) {
                                      _onCountry(focusAlpha2);
                                    }
                                    return null;
                                  },
                                ),
                              },
                              child: FlutterEarthGlobe(
                                radius: radius,
                                controller: _globeController,
                                onTap: _onGlobeTap,
                                onHover: _onGlobeHover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          Positioned(
            left: 16,
            top: 16,
            child: Semantics(
              liveRegion: true,
              label: globeLabel,
              child: _InfoPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _selectedAlpha2 != null
                            ? l10n.selectedCountry(
                                selectedPattern?.flag ?? '',
                                _displayName(_selectedAlpha2!),
                              )
                            : hoverPattern != null
                            ? '${hoverPattern.flag} ${_displayName(_hoverAlpha2!)}'
                            : l10n.tapCountry,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (_tapPending) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_selection.proxies.length > 100)
            Positioned(
              left: 16,
              top: 68,
              child: _InfoPill(child: Text(_probePausedText)),
            ),
          if (_lastProbeAt != null && _selection.proxies.isNotEmpty)
            Positioned(
              left: 16,
              top: _selection.proxies.length > 100 ? 116 : 68,
              child: _InfoPill(
                child: Text(
                  '${_isChinese ? '上次测速' : 'Last probe'} '
                  '${_lastProbeAt!.hour.toString().padLeft(2, '0')}:'
                  '${_lastProbeAt!.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          if (loading && !hasData && _loadError == null)
            Center(
              child: Semantics(
                label: _loadingText,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      key: ValueKey('globe-loading'),
                    ),
                    const SizedBox(height: 12),
                    Text(_loadingText),
                  ],
                ),
              ),
            ),
          if (isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.noDataYet, key: const ValueKey('globe-empty')),
                    const SizedBox(height: 4),
                    Text(l10n.noDataHint, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          if (_loadError != null)
            Positioned(
              key: ValueKey(offline ? 'globe-offline' : 'globe-error'),
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
                      offline ? Icons.cloud_off : Icons.error_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _globeDataError
                            ? l10n.globeDataFailed(_loadError!)
                            : offline
                            ? '${_isChinese ? '离线' : 'Offline'}: $_loadError'
                            : _loadError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _loadSelection,
                      child: Text(l10n.retry),
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
    this.sheetAnimation = SheetAnimation.slide,
  });

  final ProxySelection selection;
  final String alpha2;
  final void Function(String proxyName, String groupName) onSelected;
  final int maxDelayMs;
  final bool hideBlocked;
  final ProbeSort probeSort;
  final bool compact;
  final SheetAnimation sheetAnimation;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  late List<ProxyCandidate> _candidates;
  int _generation = 0;
  String? _selecting;
  String? _selectedGroupName;

  @override
  void initState() {
    super.initState();
    _candidates = widget.selection.candidatesForMapId(widget.alpha2);
    _selectedGroupName = _defaultGroupName(_candidates);
    _probeAll();
  }

  /// Default protocol/class tab: the group whose `now` is in this country
  /// (what the kernel is actually running), otherwise the first group.
  String? _defaultGroupName(List<ProxyCandidate> candidates) {
    for (final c in candidates) {
      if (c.isNow) return c.group.name;
    }
    return candidates.isEmpty ? null : candidates.first.group.name;
  }

  void _probeAll() {
    final gen = ++_generation;
    // Same node often appears in several groups; probe each name once.
    final names = _candidates.map((c) => c.proxy.name).toSet();
    for (final name in names) {
      widget.selection.probeByName(name).then((_) {
        if (!mounted || gen != _generation) return;
        setState(() {
          _candidates = widget.selection.candidatesForMapId(widget.alpha2);
          if (_selectedGroupName == null ||
              !_candidates.any((c) => c.group.name == _selectedGroupName)) {
            _selectedGroupName = _defaultGroupName(_candidates);
          }
        });
      });
    }
  }

  Future<void> _onTap(ProxyCandidate candidate) async {
    if (_selecting != null) return;
    setState(() => _selecting = candidate.proxy.name);
    try {
      await widget.selection.select(candidate.group.name, candidate.proxy.name);
    } catch (e) {
      // Not only DioException: any select failure (parse, state, …)
      // must surface the same persistent feedback, not crash silently.
      if (!mounted) return;
      setState(() => _selecting = null);
      final message = e is DioException
          ? (e.message ?? e.toString())
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).failed(message)),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
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
      if (_selectedGroupName == null ||
          !_candidates.any((c) => c.group.name == _selectedGroupName)) {
        _selectedGroupName = _defaultGroupName(_candidates);
      }
    });
    widget.onSelected(candidate.proxy.name, candidate.group.name);
    Navigator.of(context).pop();
  }

  List<ProxyCandidate> _filterAndSort(List<ProxyCandidate> source) {
    var list = source.where((c) {
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

  /// Candidates grouped by class/group, preserving the order in which
  /// groups appear in the kernel config.
  ///
  /// Group first (in original candidate order), then filter/sort
  /// within each group. Sorting the whole list first would reorder
  /// the groups themselves by their fastest node.
  Map<String, List<ProxyCandidate>> get _visibleByGroup {
    final grouped = <String, List<ProxyCandidate>>{};
    for (final c in _candidates) {
      grouped.putIfAbsent(c.group.name, () => []).add(c);
    }
    final map = <String, List<ProxyCandidate>>{};
    for (final entry in grouped.entries) {
      final filtered = _filterAndSort(entry.value);
      if (filtered.isNotEmpty) map[entry.key] = filtered;
    }
    return map;
  }

  Widget _buildNodeCard(
    AppLocalizations l10n,
    ProxyCandidate candidate,
    ColorScheme scheme,
  ) {
    final delay = candidate.proxy.delay;
    final color = _delayColorForTheme(scheme, delay);
    final selecting = _selecting == candidate.proxy.name;
    return Material(
      color: candidate.isNow
          ? scheme.secondaryContainer
          : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: candidate.isNow ? scheme.primary : scheme.outlineVariant,
          width: candidate.isNow ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: selecting ? null : () => _onTap(candidate),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      candidate.proxy.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selecting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (candidate.isNow)
                    Icon(Icons.check_circle, size: 16, color: scheme.tertiary),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    delayLabel(l10n, delay),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: delay == kDelayTimeout
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      candidate.proxy.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pattern = kCountries[widget.alpha2];
    final byGroup = _visibleByGroup;
    // If filtering emptied the remembered tab, fall back to any group that
    // still has nodes (first in config order) so the sheet never shows a
    // blank tab while other classes are available.
    final selectedGroup = byGroup.containsKey(_selectedGroupName)
        ? _selectedGroupName
        : (byGroup.isEmpty ? null : byGroup.keys.first);
    final visible = selectedGroup == null
        ? <ProxyCandidate>[]
        : byGroup[selectedGroup]!;
    final scheme = Theme.of(context).colorScheme;
    final error = widget.selection.error;
    return _SheetEnter(
      animation: widget.sheetAnimation,
      child: ConstrainedBox(
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
                  // Flag emoji is decorative; the country name next to it
                  // is the accessible label (no emoji-only identifier).
                  ExcludeSemantics(
                    child: Text(
                      pattern?.flag ?? flagForAlpha2(widget.alpha2),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          countryDisplayName(
                            widget.alpha2,
                            chinese:
                                Localizations.localeOf(context).languageCode ==
                                'zh',
                          ),
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
              // Class/group tabs (A/B/C/D…): pick a class, then its nodes
              // (1…9) are shown once below as cards — not repeated per group.
              if (byGroup.length > 1) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: byGroup.entries.map((entry) {
                      final selected = entry.key == selectedGroup;
                      final hasNow = entry.value.any((c) => c.isNow);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${entry.key} · ${entry.value.length}'),
                          selected: selected,
                          avatar: hasNow
                              ? const Icon(Icons.check, size: 16)
                              : null,
                          onSelected: (_) =>
                              setState(() => _selectedGroupName = entry.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
                  child: GridView.builder(
                    // Re-key per class tab so cards re-stagger on tab switch.
                    key: ValueKey('cards-$selectedGroup'),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 600
                          ? 3
                          : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: widget.compact ? 2.6 : 2.1,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _StaggerCard(
                      animation: widget.sheetAnimation,
                      index: i,
                      child: _buildNodeCard(l10n, visible[i], scheme),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrance animation for the whole sheet *content*.
///
/// `slide` is handled by the sheet itself (Material default), so it is a
/// pass-through here; the other modes are used together with
/// `AnimationStyle.noAnimation` on the sheet, so this is the only motion.
class _SheetEnter extends StatelessWidget {
  const _SheetEnter({required this.animation, required this.child});

  final SheetAnimation animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (animation) {
      case SheetAnimation.slide:
      case SheetAnimation.none:
        return child;
      case SheetAnimation.fade:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (_, t, c) => Opacity(opacity: t.clamp(0.0, 1.0), child: c),
          child: child,
        );
      case SheetAnimation.scale:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (_, t, c) =>
              Transform.scale(scale: 0.92 + 0.08 * t, child: c),
          child: child,
        );
      case SheetAnimation.spring:
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, t, c) => Transform.scale(scale: 0.9 + 0.1 * t, child: c),
          child: child,
        );
    }
  }
}

/// Per-card staggered entrance (the `flutter_animate`-style pattern,
/// hand-rolled with `TweenAnimationBuilder` so no package is needed).
/// Each card starts `index * 30ms` after the previous one (capped), and
/// the whole stagger replays when the class tab changes because the
/// grid is re-keyed per tab.
class _StaggerCard extends StatelessWidget {
  const _StaggerCard({
    required this.animation,
    required this.index,
    required this.child,
  });

  final SheetAnimation animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (animation == SheetAnimation.none) return child;
    const baseMs = 350;
    final delayMs = (index * 30).clamp(0, 300);
    final curve = animation == SheetAnimation.spring
        ? Curves.elasticOut
        : Curves.easeOutBack;
    // TweenAnimationBuilder has no delay parameter, so fold the stagger
    // delay into the total duration and map it back to 0..1 progress.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delayMs + baseMs),
      builder: (_, raw, c) {
        final p = ((raw * (delayMs + baseMs) - delayMs) / baseMs).clamp(
          0.0,
          1.0,
        );
        final t = curve.transform(p);
        // Overshoot curves (easeOutBack/elasticOut) exceed 1.0, which
        // Opacity asserts against — so opacity gets its own clamped,
        // non-overshooting progress and only scale uses the overshoot.
        final faded = Curves.easeOut.transform(p).clamp(0.0, 1.0);
        Widget out = c!;
        switch (animation) {
          case SheetAnimation.fade:
            out = Opacity(opacity: faded, child: out);
          case SheetAnimation.scale:
          case SheetAnimation.spring:
            out = Transform.scale(scale: 0.85 + 0.15 * t, child: out);
          case SheetAnimation.slide:
            out = Opacity(
              opacity: faded,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - faded)),
                child: out,
              ),
            );
          case SheetAnimation.none:
            break;
        }
        return out;
      },
      child: child,
    );
  }
}

/// Keyboard activation intent for the globe (Enter/Space).
class _GlobeActivateIntent extends Intent {
  const _GlobeActivateIntent();
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
