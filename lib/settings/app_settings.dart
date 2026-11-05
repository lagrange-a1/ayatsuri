/*
 * App settings: model + persistence (SharedPreferences).
 *
 * One JSON document under a single key (`ayatsuri_settings_v1`) with a
 * schema version; unreadable/corrupt data falls back to defaults so startup
 * is never blocked.
 *
 * The data class is generated with freezed (copyWith / equality) and
 * json_serializable (toJson / fromJson) — see app_settings.freezed.dart /
 * app_settings.g.dart. The hand-written part is only the fromJson
 * pre-processing ([_normalize]), which preserves the historical behaviour:
 * clamped numbers, enum-name fallbacks, renamed keys ('seed', 'bg',
 * 'rotSpeed', ...), and the old rotationSpeed scale migration.
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
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_file.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

const _prefsKey = 'ayatsuri_settings_v1';
// The stored document used to carry a `v` schema-version key. It was never
// read back, and json_serializable does not write getters, so `v` is no
// longer emitted; old stored documents with `v` still parse (unknown keys
// are ignored by the generated fromJson).

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

// ── json_serializable converters ────────────────────────────────────────

/// Color <-> ARGB32 int. Non-numeric values fall back to the default seed.
Color _colorFromJson(Object? v) =>
    v is num ? Color(v.toInt()) : const Color(0xFF6750A4);

int _colorToJson(Color c) => c.toARGB32();

// ── fromJson pre-processing ─────────────────────────────────────────────

double _num(Object? v, double fallback) => v is num ? v.toDouble() : fallback;

double _clampNum(Object? v, double fallback, double lo, double hi) =>
    _num(v, fallback).clamp(lo, hi);

bool _isKnownName<T extends Enum>(List<T> values, Object? name) =>
    values.any((e) => e.name == name);

/// Normalizes a raw stored document so the generated fromJson can stay dumb:
/// enum names fall back to defaults instead of throwing, out-of-range numbers
/// are clamped, and the old 0.05-1.0 rotationSpeed slider scale (values above
/// the new range, e.g. 0.2 -> 0.01, ~4 deg/s) is migrated.
Map<String, dynamic> _normalize(Map<String, dynamic> j) {
  final m = Map<String, dynamic>.of(j);
  void enumKey<T extends Enum>(String key, List<T> values, T fallback) {
    if (!_isKnownName(values, m[key])) m[key] = fallback.name;
  }

  enumKey('themeMode', ThemeMode.values, ThemeMode.system);
  enumKey('variant', DynamicSchemeVariant.values, DynamicSchemeVariant.content);
  enumKey('initialView', InitialView.values, InitialView.asia);
  enumKey('probeSort', ProbeSort.values, ProbeSort.delay);
  enumKey('locale', AppLocale.values, AppLocale.system);

  m['textScale'] = _clampNum(m['textScale'], 1.0, 0.85, 1.3);
  m['bgOpacity'] = _clampNum(m['bgOpacity'], 0.65, 0.0, 1.0);
  m['markerScale'] = _clampNum(m['markerScale'], 1.0, 0.5, 2.0);
  m['globeScale'] = _clampNum(m['globeScale'], 1.0, 0.7, 1.3);
  m['customLat'] = _clampNum(m['customLat'], 28, -90.0, 90.0);
  m['customLng'] = _clampNum(m['customLng'], 100, -180.0, 180.0);
  final rawRot = _num(m['rotSpeed'], 0.01);
  m['rotSpeed'] = (rawRot > 0.05 ? rawRot * 0.05 : rawRot).clamp(0.002, 0.05);
  m['maxDelayMs'] = m['maxDelayMs'] is num
      ? (m['maxDelayMs']! as num).toInt().clamp(0, 1000)
      : 0;
  // -1 (off) is preserved; otherwise clamp to the 5s..300s slider range.
  final rawInterval = m['probeInterval'];
  m['probeInterval'] = rawInterval == -1
      ? -1
      : (rawInterval is num ? rawInterval.toInt() : 30).clamp(5, 300);

  // Tolerate corrupt non-bool/non-String payloads like the old `== true` /
  // `is String` checks did.
  for (final key in ['pureBlack', 'autoRotate', 'hideBlocked', 'compact']) {
    m[key] = m[key] == true;
  }
  for (final key in ['bg', 'bgPath', 'serverUrl', 'secret']) {
    if (m[key] != null && m[key] is! String) m[key] = null;
  }
  return m;
}

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson)
    @Default(Color(0xFF6750A4))
    Color seedColor,
    @Default(false) bool pureBlack,
    @JsonKey(name: 'variant')
    @Default(DynamicSchemeVariant.content)
    DynamicSchemeVariant schemeVariant,
    @Default(1.0) double textScale,

    /// Mihomo external-controller API base URL (e.g. `http://localhost:9091`);
    /// null falls back to the `.env` host/port.
    @JsonKey(name: 'serverUrl') String? serverUrl,

    /// Bearer secret for the controller; null falls back to `.env` `secret`.
    @JsonKey(name: 'secret') String? secret,

    @JsonKey(name: 'bg') String? backgroundBase64,

    /// File-system path of the persisted background image (native only).
    @JsonKey(name: 'bgPath') String? backgroundPath,
    @JsonKey(name: 'bgOpacity') @Default(0.65) double backgroundOpacity,
    @Default(false) bool autoRotate,
    @JsonKey(name: 'rotSpeed') @Default(0.01) double rotationSpeed,
    @Default(1.0) double markerScale,
    @Default(1.0) double globeScale,
    @Default(InitialView.auto) InitialView initialView,
    @Default(28) double customLat,
    @Default(100) double customLng,
    @Default(0) int maxDelayMs,
    @Default(false) bool hideBlocked,
    @Default(ProbeSort.delay) ProbeSort probeSort,

    /// Periodic full-probe interval in seconds; -1 disables the timer.
    @JsonKey(name: 'probeInterval') @Default(30) int probeIntervalSec,
    @JsonKey(name: 'compact') @Default(false) bool compactNodeList,
    @Default(AppLocale.system) AppLocale locale,
  }) = _AppSettings;

  const AppSettings._();

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(_normalize(json));

  /// Whether a custom background is configured (file or base64).
  @JsonKey(includeToJson: false, includeFromJson: false)
  bool get hasBackground => backgroundPath != null || backgroundBase64 != null;

  @JsonKey(includeToJson: false, includeFromJson: false)
  double get latLngLat => switch (initialView) {
    InitialView.global => 0,
    InitialView.custom => customLat,
    InitialView.auto || InitialView.asia => 28,
  };

  @JsonKey(includeToJson: false, includeFromJson: false)
  double get latLngLng => switch (initialView) {
    InitialView.global => 0,
    InitialView.custom => customLng,
    InitialView.auto || InitialView.asia => 100,
  };
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
      _settings = _settings.copyWith(backgroundPath: null);
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
            backgroundBase64: base64Encode(bytes),
            backgroundPath: null,
          ),
        );
      } else {
        final path = await writeBackgroundFile(bytes);
        if (path != null) {
          await update(
            _settings.copyWith(backgroundPath: path, backgroundBase64: null),
          );
        } else {
          // File write failed: keep the image as base64 so it still shows.
          await update(
            _settings.copyWith(
              backgroundBase64: base64Encode(bytes),
              backgroundPath: null,
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
      _settings.copyWith(backgroundBase64: null, backgroundPath: null),
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
