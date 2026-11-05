// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  themeMode:
      $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
      ThemeMode.system,
  seedColor: json['seed'] == null
      ? const Color(0xFFE65100)
      : _colorFromJson(json['seed']),
  pureBlack: json['pureBlack'] as bool? ?? false,
  schemeVariant:
      $enumDecodeNullable(_$DynamicSchemeVariantEnumMap, json['variant']) ??
      DynamicSchemeVariant.content,
  textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
  serverUrl: json['serverUrl'] as String?,
  secret: json['secret'] as String?,
  backgroundBase64: json['bg'] as String?,
  backgroundPath: json['bgPath'] as String?,
  backgroundOpacity: (json['bgOpacity'] as num?)?.toDouble() ?? 0.65,
  autoRotate: json['autoRotate'] as bool? ?? false,
  rotationSpeed: (json['rotSpeed'] as num?)?.toDouble() ?? 0.01,
  markerScale: (json['markerScale'] as num?)?.toDouble() ?? 1.0,
  globeScale: (json['globeScale'] as num?)?.toDouble() ?? 1.0,
  initialView:
      $enumDecodeNullable(_$InitialViewEnumMap, json['initialView']) ??
      InitialView.auto,
  customLat: (json['customLat'] as num?)?.toDouble() ?? 28,
  customLng: (json['customLng'] as num?)?.toDouble() ?? 100,
  maxDelayMs: (json['maxDelayMs'] as num?)?.toInt() ?? 0,
  hideBlocked: json['hideBlocked'] as bool? ?? false,
  probeSort:
      $enumDecodeNullable(_$ProbeSortEnumMap, json['probeSort']) ??
      ProbeSort.delay,
  globeQuality:
      $enumDecodeNullable(_$GlobeTextureQualityEnumMap, json['globeQuality']) ??
      GlobeTextureQuality.k8,
  globeTime:
      $enumDecodeNullable(_$GlobeTimeEnumMap, json['globeTime']) ??
      GlobeTime.system,
  probeIntervalSec: (json['probeInterval'] as num?)?.toInt() ?? 30,
  compactNodeList: json['compact'] as bool? ?? false,
  locale:
      $enumDecodeNullable(_$AppLocaleEnumMap, json['locale']) ??
      AppLocale.system,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'seed': _colorToJson(instance.seedColor),
      'pureBlack': instance.pureBlack,
      'variant': _$DynamicSchemeVariantEnumMap[instance.schemeVariant]!,
      'textScale': instance.textScale,
      'serverUrl': instance.serverUrl,
      'secret': instance.secret,
      'bg': instance.backgroundBase64,
      'bgPath': instance.backgroundPath,
      'bgOpacity': instance.backgroundOpacity,
      'autoRotate': instance.autoRotate,
      'rotSpeed': instance.rotationSpeed,
      'markerScale': instance.markerScale,
      'globeScale': instance.globeScale,
      'initialView': _$InitialViewEnumMap[instance.initialView]!,
      'customLat': instance.customLat,
      'customLng': instance.customLng,
      'maxDelayMs': instance.maxDelayMs,
      'hideBlocked': instance.hideBlocked,
      'probeSort': _$ProbeSortEnumMap[instance.probeSort]!,
      'globeQuality': _$GlobeTextureQualityEnumMap[instance.globeQuality]!,
      'globeTime': _$GlobeTimeEnumMap[instance.globeTime]!,
      'probeInterval': instance.probeIntervalSec,
      'compact': instance.compactNodeList,
      'locale': _$AppLocaleEnumMap[instance.locale]!,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

const _$DynamicSchemeVariantEnumMap = {
  DynamicSchemeVariant.tonalSpot: 'tonalSpot',
  DynamicSchemeVariant.fidelity: 'fidelity',
  DynamicSchemeVariant.monochrome: 'monochrome',
  DynamicSchemeVariant.neutral: 'neutral',
  DynamicSchemeVariant.vibrant: 'vibrant',
  DynamicSchemeVariant.expressive: 'expressive',
  DynamicSchemeVariant.content: 'content',
  DynamicSchemeVariant.rainbow: 'rainbow',
  DynamicSchemeVariant.fruitSalad: 'fruitSalad',
};

const _$InitialViewEnumMap = {
  InitialView.auto: 'auto',
  InitialView.asia: 'asia',
  InitialView.global: 'global',
  InitialView.custom: 'custom',
};

const _$ProbeSortEnumMap = {ProbeSort.delay: 'delay', ProbeSort.name: 'name'};

const _$GlobeTextureQualityEnumMap = {
  GlobeTextureQuality.k2: 'k2',
  GlobeTextureQuality.k8: 'k8',
};

const _$GlobeTimeEnumMap = {
  GlobeTime.system: 'system',
  GlobeTime.day: 'day',
  GlobeTime.night: 'night',
};

const _$AppLocaleEnumMap = {
  AppLocale.system: 'system',
  AppLocale.zh: 'zh',
  AppLocale.en: 'en',
};
