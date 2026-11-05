/*
 * App settings: model + persistence (SharedPreferences).
 *
 * One JSON document under a single key (`ayatsuri_settings_v1`) with a
 * schema version; unreadable/corrupt data falls back to defaults so startup
 * is never blocked.
 *
 * The custom background image is persisted as a real file under the
 * app-private documents directory on file-system platforms (Android:
 * `/data/data/<package>/files/`), with only its path stored in the JSON;
 * on Web (no file system) it is stored as base64 in the same document.
 * `AppSettingsController.backgroundBytes` holds the decoded bytes for
 * display; old base64-only settings keep working (migration fallback).
 */
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_file.dart';

const _prefsKey = 'ayatsuri_settings_v1';
const _schemaVersion = 1;

enum InitialView {
  /// Follow the currently selected proxy's country (resolved at runtime).
  auto,
  asia,
  global,
  custom,
}

enum ProbeSort { delay, name }

/// UI language: follow system, Simplified Chinese, or English.
enum AppLocale {
  system,
  zh,
  en;

  /// Locale for `MaterialApp.locale`; null means follow the system.
  Locale? get flutterLocale => switch (this) {
    AppLocale.system => null,
    AppLocale.zh => const Locale('zh'),
    AppLocale.en => const Locale('en'),
  };
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.seedColor = const Color(0xFF6750A4),
    this.pureBlack = false,
    this.schemeVariant = DynamicSchemeVariant.content,
    this.textScale = 1.0,
    this.backgroundBase64,
    this.backgroundPath,
    this.backgroundOpacity = 0.65,
    this.autoRotate = false,
    this.rotationSpeed = 0.01,
    this.markerScale = 1.0,
    this.globeScale = 1.0,
    this.initialView = InitialView.auto,
    this.customLat = 28,
    this.customLng = 100,
    this.maxDelayMs = 0,
    this.hideBlocked = false,
    this.probeSort = ProbeSort.delay,
    this.compactNodeList = false,
    this.locale = AppLocale.system,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final bool pureBlack;
  final DynamicSchemeVariant schemeVariant;
  final double textScale;
  final String? backgroundBase64;

  /// File-system path of the persisted background image (native only).
  final String? backgroundPath;
  final double backgroundOpacity;
  final bool autoRotate;
  final double rotationSpeed;
  final double markerScale;
  final double globeScale;
  final InitialView initialView;
  final double customLat;
  final double customLng;
  final int maxDelayMs;
  final bool hideBlocked;
  final ProbeSort probeSort;
  final bool compactNodeList;
  final AppLocale locale;

  /// Whether a custom background is configured (file or base64).
  bool get hasBackground => backgroundPath != null || backgroundBase64 != null;

  double get latLngLat => switch (initialView) {
    InitialView.global => 0,
    InitialView.custom => customLat,
    InitialView.auto || InitialView.asia => 28,
  };
  double get latLngLng => switch (initialView) {
    InitialView.global => 0,
    InitialView.custom => customLng,
    InitialView.auto || InitialView.asia => 100,
  };

  AppSettings copyWith({
    ThemeMode? themeMode,
    Color? seedColor,
    bool? pureBlack,
    DynamicSchemeVariant? schemeVariant,
    double? textScale,
    String? Function()? backgroundBase64,
    String? Function()? backgroundPath,
    double? backgroundOpacity,
    bool? autoRotate,
    double? rotationSpeed,
    double? markerScale,
    double? globeScale,
    InitialView? initialView,
    double? customLat,
    double? customLng,
    int? maxDelayMs,
    bool? hideBlocked,
    ProbeSort? probeSort,
    bool? compactNodeList,
    AppLocale? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      seedColor: seedColor ?? this.seedColor,
      pureBlack: pureBlack ?? this.pureBlack,
      schemeVariant: schemeVariant ?? this.schemeVariant,
      textScale: textScale ?? this.textScale,
      backgroundBase64: backgroundBase64 != null
          ? backgroundBase64()
          : this.backgroundBase64,
      backgroundPath: backgroundPath != null
          ? backgroundPath()
          : this.backgroundPath,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      autoRotate: autoRotate ?? this.autoRotate,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
      markerScale: markerScale ?? this.markerScale,
      globeScale: globeScale ?? this.globeScale,
      initialView: initialView ?? this.initialView,
      customLat: customLat ?? this.customLat,
      customLng: customLng ?? this.customLng,
      maxDelayMs: maxDelayMs ?? this.maxDelayMs,
      hideBlocked: hideBlocked ?? this.hideBlocked,
      probeSort: probeSort ?? this.probeSort,
      compactNodeList: compactNodeList ?? this.compactNodeList,
      locale: locale ?? this.locale,
    );
  }

  Map<String, dynamic> toJson() => {
    'v': _schemaVersion,
    'themeMode': themeMode.name,
    'seed': seedColor.toARGB32(),
    'pureBlack': pureBlack,
    'variant': schemeVariant.name,
    'textScale': textScale,
    'bg': backgroundBase64,
    'bgPath': backgroundPath,
    'bgOpacity': backgroundOpacity,
    'autoRotate': autoRotate,
    'rotSpeed': rotationSpeed,
    'markerScale': markerScale,
    'globeScale': globeScale,
    'initialView': initialView.name,
    'customLat': customLat,
    'customLng': customLng,
    'maxDelayMs': maxDelayMs,
    'hideBlocked': hideBlocked,
    'probeSort': probeSort.name,
    'compact': compactNodeList,
    'locale': locale.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    T enumOf<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((e) => e.name == name, orElse: () => fallback);
    double numOf(Object? v, double fb) => v is num ? v.toDouble() : fb;
    return AppSettings(
      themeMode: enumOf(ThemeMode.values, j['themeMode'], ThemeMode.system),
      seedColor: j['seed'] is num
          ? Color((j['seed']! as num).toInt())
          : const Color(0xFF6750A4),
      pureBlack: j['pureBlack'] == true,
      schemeVariant: enumOf(
        DynamicSchemeVariant.values,
        j['variant'],
        DynamicSchemeVariant.content,
      ),
      textScale: numOf(j['textScale'], 1.0).clamp(0.85, 1.3),
      backgroundBase64: j['bg'] is String ? j['bg'] as String : null,
      backgroundPath: j['bgPath'] is String ? j['bgPath'] as String : null,
      backgroundOpacity: numOf(j['bgOpacity'], 0.65).clamp(0.0, 1.0),
      autoRotate: j['autoRotate'] == true,
      // Scale migration: the old 0.05-1.0 slider range was ~19-377 deg/s
      // (the package ticks every frame); values above the new range are
      // interpreted in the old scale (0.2 -> 0.01, i.e. ~4 deg/s).
      rotationSpeed: () {
        final raw = numOf(j['rotSpeed'], 0.01);
        return (raw > 0.05 ? raw * 0.05 : raw).clamp(0.002, 0.05);
      }(),
      markerScale: numOf(j['markerScale'], 1.0).clamp(0.5, 2.0),
      globeScale: numOf(j['globeScale'], 1.0).clamp(0.7, 1.3),
      initialView: enumOf(
        InitialView.values,
        j['initialView'],
        InitialView.asia,
      ),
      customLat: numOf(j['customLat'], 28).clamp(-90.0, 90.0),
      customLng: numOf(j['customLng'], 100).clamp(-180.0, 180.0),
      maxDelayMs: j['maxDelayMs'] is num
          ? (j['maxDelayMs']! as num).toInt().clamp(0, 1000)
          : 0,
      hideBlocked: j['hideBlocked'] == true,
      probeSort: enumOf(ProbeSort.values, j['probeSort'], ProbeSort.delay),
      compactNodeList: j['compact'] == true,
      locale: enumOf(AppLocale.values, j['locale'], AppLocale.system),
    );
  }
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({AppSettings? initial})
    : _settings = initial ?? const AppSettings();

  AppSettings _settings;
  AppSettings get settings => _settings;
  bool _loaded = false;
  bool get loaded => _loaded;

  /// Decoded background bytes for display (from file or base64).
  Uint8List? _backgroundBytes;
  Uint8List? get backgroundBytes => _backgroundBytes;

  Future<void> _resolveBackgroundBytes() async {
    if (_settings.backgroundPath != null) {
      _backgroundBytes = await readBackgroundFile();
      if (_backgroundBytes != null) return;
      // File vanished (cleared app data, etc.): drop the stale path.
      _settings = _settings.copyWith(backgroundPath: () => null);
    }
    final b64 = _settings.backgroundBase64;
    _backgroundBytes = b64 == null ? null : base64Decode(b64);
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        _settings = AppSettings.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      _settings = const AppSettings();
    }
    await _resolveBackgroundBytes();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    _settings = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(next.toJson()));
    } catch (_) {
      // Persistence failure must not break the running app.
    }
  }

  /// Pick an image via file_picker (works on Android + Web with data).
  ///
  /// Native: bytes are written to a file in the app documents directory
  /// (`/data/data/<package>/files/` on Android) and only the path is
  /// persisted. Web: falls back to base64 in SharedPreferences.
  Future<bool> pickBackground() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return false;
      final bytes = await file.readAsBytes();
      _backgroundBytes = bytes;
      if (kIsWeb) {
        await update(
          _settings.copyWith(
            backgroundBase64: () => base64Encode(bytes),
            backgroundPath: () => null,
          ),
        );
      } else {
        final path = await writeBackgroundFile(bytes);
        if (path != null) {
          await update(
            _settings.copyWith(
              backgroundPath: () => path,
              backgroundBase64: () => null,
            ),
          );
        } else {
          // File write failed: keep the image as base64 so it still shows.
          await update(
            _settings.copyWith(
              backgroundBase64: () => base64Encode(bytes),
              backgroundPath: () => null,
            ),
          );
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearBackground() async {
    await deleteBackgroundFile();
    _backgroundBytes = null;
    await update(
      _settings.copyWith(
        backgroundBase64: () => null,
        backgroundPath: () => null,
      ),
    );
  }
}

/// Build a Material 3 theme from settings for [brightness].
ThemeData buildAppTheme(AppSettings s, Brightness brightness) {
  var scheme = ColorScheme.fromSeed(
    seedColor: s.seedColor,
    brightness: brightness,
    dynamicSchemeVariant: s.schemeVariant,
  );
  if (s.pureBlack && brightness == Brightness.dark) {
    scheme = scheme.copyWith(surface: const Color(0xFF000000));
  }
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
  );
}
