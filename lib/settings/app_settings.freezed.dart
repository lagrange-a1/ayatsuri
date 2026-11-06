// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 ThemeMode get themeMode;@JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson) Color get seedColor; bool get pureBlack;@JsonKey(name: 'variant') DynamicSchemeVariant get schemeVariant; double get textScale;/// Mihomo external-controller API base URL (e.g. `http://localhost:9091`);
/// null falls back to the `.env` host/port.
@JsonKey(name: 'serverUrl') String? get serverUrl;/// Bearer secret for the controller; null falls back to `.env` `secret`.
@JsonKey(name: 'secret') String? get secret;@JsonKey(name: 'bg') String? get backgroundBase64;/// File-system path of the persisted background image (native only).
@JsonKey(name: 'bgPath') String? get backgroundPath;@JsonKey(name: 'bgOpacity') double get backgroundOpacity; bool get autoRotate;@JsonKey(name: 'rotSpeed') double get rotationSpeed; double get markerScale; double get globeScale; InitialView get initialView; double get customLat; double get customLng; int get maxDelayMs; bool get hideBlocked; ProbeSort get probeSort;@JsonKey(name: 'globeQuality') GlobeTextureQuality get globeQuality;@JsonKey(name: 'globeTime') GlobeTime get globeTime;/// Periodic full-probe interval in seconds; -1 disables the timer.
@JsonKey(name: 'probeInterval') int get probeIntervalSec;@JsonKey(name: 'compact') bool get compactNodeList; SheetAnimation get sheetAnimation; AppLocale get locale;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&const DeepCollectionEquality().equals(other.seedColor, seedColor)&&(identical(other.pureBlack, pureBlack) || other.pureBlack == pureBlack)&&(identical(other.schemeVariant, schemeVariant) || other.schemeVariant == schemeVariant)&&(identical(other.textScale, textScale) || other.textScale == textScale)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.backgroundBase64, backgroundBase64) || other.backgroundBase64 == backgroundBase64)&&(identical(other.backgroundPath, backgroundPath) || other.backgroundPath == backgroundPath)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&(identical(other.autoRotate, autoRotate) || other.autoRotate == autoRotate)&&(identical(other.rotationSpeed, rotationSpeed) || other.rotationSpeed == rotationSpeed)&&(identical(other.markerScale, markerScale) || other.markerScale == markerScale)&&(identical(other.globeScale, globeScale) || other.globeScale == globeScale)&&(identical(other.initialView, initialView) || other.initialView == initialView)&&(identical(other.customLat, customLat) || other.customLat == customLat)&&(identical(other.customLng, customLng) || other.customLng == customLng)&&(identical(other.maxDelayMs, maxDelayMs) || other.maxDelayMs == maxDelayMs)&&(identical(other.hideBlocked, hideBlocked) || other.hideBlocked == hideBlocked)&&(identical(other.probeSort, probeSort) || other.probeSort == probeSort)&&(identical(other.globeQuality, globeQuality) || other.globeQuality == globeQuality)&&(identical(other.globeTime, globeTime) || other.globeTime == globeTime)&&(identical(other.probeIntervalSec, probeIntervalSec) || other.probeIntervalSec == probeIntervalSec)&&(identical(other.compactNodeList, compactNodeList) || other.compactNodeList == compactNodeList)&&(identical(other.sheetAnimation, sheetAnimation) || other.sheetAnimation == sheetAnimation)&&(identical(other.locale, locale) || other.locale == locale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,themeMode,const DeepCollectionEquality().hash(seedColor),pureBlack,schemeVariant,textScale,serverUrl,secret,backgroundBase64,backgroundPath,backgroundOpacity,autoRotate,rotationSpeed,markerScale,globeScale,initialView,customLat,customLng,maxDelayMs,hideBlocked,probeSort,globeQuality,globeTime,probeIntervalSec,compactNodeList,sheetAnimation,locale]);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, seedColor: $seedColor, pureBlack: $pureBlack, schemeVariant: $schemeVariant, textScale: $textScale, serverUrl: $serverUrl, secret: $secret, backgroundBase64: $backgroundBase64, backgroundPath: $backgroundPath, backgroundOpacity: $backgroundOpacity, autoRotate: $autoRotate, rotationSpeed: $rotationSpeed, markerScale: $markerScale, globeScale: $globeScale, initialView: $initialView, customLat: $customLat, customLng: $customLng, maxDelayMs: $maxDelayMs, hideBlocked: $hideBlocked, probeSort: $probeSort, globeQuality: $globeQuality, globeTime: $globeTime, probeIntervalSec: $probeIntervalSec, compactNodeList: $compactNodeList, sheetAnimation: $sheetAnimation, locale: $locale)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 ThemeMode themeMode,@JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson) Color seedColor, bool pureBlack,@JsonKey(name: 'variant') DynamicSchemeVariant schemeVariant, double textScale,@JsonKey(name: 'serverUrl') String? serverUrl,@JsonKey(name: 'secret') String? secret,@JsonKey(name: 'bg') String? backgroundBase64,@JsonKey(name: 'bgPath') String? backgroundPath,@JsonKey(name: 'bgOpacity') double backgroundOpacity, bool autoRotate,@JsonKey(name: 'rotSpeed') double rotationSpeed, double markerScale, double globeScale, InitialView initialView, double customLat, double customLng, int maxDelayMs, bool hideBlocked, ProbeSort probeSort,@JsonKey(name: 'globeQuality') GlobeTextureQuality globeQuality,@JsonKey(name: 'globeTime') GlobeTime globeTime,@JsonKey(name: 'probeInterval') int probeIntervalSec,@JsonKey(name: 'compact') bool compactNodeList, SheetAnimation sheetAnimation, AppLocale locale
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? seedColor = freezed,Object? pureBlack = null,Object? schemeVariant = null,Object? textScale = null,Object? serverUrl = freezed,Object? secret = freezed,Object? backgroundBase64 = freezed,Object? backgroundPath = freezed,Object? backgroundOpacity = null,Object? autoRotate = null,Object? rotationSpeed = null,Object? markerScale = null,Object? globeScale = null,Object? initialView = null,Object? customLat = null,Object? customLng = null,Object? maxDelayMs = null,Object? hideBlocked = null,Object? probeSort = null,Object? globeQuality = null,Object? globeTime = null,Object? probeIntervalSec = null,Object? compactNodeList = null,Object? sheetAnimation = null,Object? locale = null,}) {
  return _then(_self.copyWith(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,seedColor: freezed == seedColor ? _self.seedColor : seedColor // ignore: cast_nullable_to_non_nullable
as Color,pureBlack: null == pureBlack ? _self.pureBlack : pureBlack // ignore: cast_nullable_to_non_nullable
as bool,schemeVariant: null == schemeVariant ? _self.schemeVariant : schemeVariant // ignore: cast_nullable_to_non_nullable
as DynamicSchemeVariant,textScale: null == textScale ? _self.textScale : textScale // ignore: cast_nullable_to_non_nullable
as double,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,secret: freezed == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String?,backgroundBase64: freezed == backgroundBase64 ? _self.backgroundBase64 : backgroundBase64 // ignore: cast_nullable_to_non_nullable
as String?,backgroundPath: freezed == backgroundPath ? _self.backgroundPath : backgroundPath // ignore: cast_nullable_to_non_nullable
as String?,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,autoRotate: null == autoRotate ? _self.autoRotate : autoRotate // ignore: cast_nullable_to_non_nullable
as bool,rotationSpeed: null == rotationSpeed ? _self.rotationSpeed : rotationSpeed // ignore: cast_nullable_to_non_nullable
as double,markerScale: null == markerScale ? _self.markerScale : markerScale // ignore: cast_nullable_to_non_nullable
as double,globeScale: null == globeScale ? _self.globeScale : globeScale // ignore: cast_nullable_to_non_nullable
as double,initialView: null == initialView ? _self.initialView : initialView // ignore: cast_nullable_to_non_nullable
as InitialView,customLat: null == customLat ? _self.customLat : customLat // ignore: cast_nullable_to_non_nullable
as double,customLng: null == customLng ? _self.customLng : customLng // ignore: cast_nullable_to_non_nullable
as double,maxDelayMs: null == maxDelayMs ? _self.maxDelayMs : maxDelayMs // ignore: cast_nullable_to_non_nullable
as int,hideBlocked: null == hideBlocked ? _self.hideBlocked : hideBlocked // ignore: cast_nullable_to_non_nullable
as bool,probeSort: null == probeSort ? _self.probeSort : probeSort // ignore: cast_nullable_to_non_nullable
as ProbeSort,globeQuality: null == globeQuality ? _self.globeQuality : globeQuality // ignore: cast_nullable_to_non_nullable
as GlobeTextureQuality,globeTime: null == globeTime ? _self.globeTime : globeTime // ignore: cast_nullable_to_non_nullable
as GlobeTime,probeIntervalSec: null == probeIntervalSec ? _self.probeIntervalSec : probeIntervalSec // ignore: cast_nullable_to_non_nullable
as int,compactNodeList: null == compactNodeList ? _self.compactNodeList : compactNodeList // ignore: cast_nullable_to_non_nullable
as bool,sheetAnimation: null == sheetAnimation ? _self.sheetAnimation : sheetAnimation // ignore: cast_nullable_to_non_nullable
as SheetAnimation,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as AppLocale,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeMode themeMode, @JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson)  Color seedColor,  bool pureBlack, @JsonKey(name: 'variant')  DynamicSchemeVariant schemeVariant,  double textScale, @JsonKey(name: 'serverUrl')  String? serverUrl, @JsonKey(name: 'secret')  String? secret, @JsonKey(name: 'bg')  String? backgroundBase64, @JsonKey(name: 'bgPath')  String? backgroundPath, @JsonKey(name: 'bgOpacity')  double backgroundOpacity,  bool autoRotate, @JsonKey(name: 'rotSpeed')  double rotationSpeed,  double markerScale,  double globeScale,  InitialView initialView,  double customLat,  double customLng,  int maxDelayMs,  bool hideBlocked,  ProbeSort probeSort, @JsonKey(name: 'globeQuality')  GlobeTextureQuality globeQuality, @JsonKey(name: 'globeTime')  GlobeTime globeTime, @JsonKey(name: 'probeInterval')  int probeIntervalSec, @JsonKey(name: 'compact')  bool compactNodeList,  SheetAnimation sheetAnimation,  AppLocale locale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.seedColor,_that.pureBlack,_that.schemeVariant,_that.textScale,_that.serverUrl,_that.secret,_that.backgroundBase64,_that.backgroundPath,_that.backgroundOpacity,_that.autoRotate,_that.rotationSpeed,_that.markerScale,_that.globeScale,_that.initialView,_that.customLat,_that.customLng,_that.maxDelayMs,_that.hideBlocked,_that.probeSort,_that.globeQuality,_that.globeTime,_that.probeIntervalSec,_that.compactNodeList,_that.sheetAnimation,_that.locale);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeMode themeMode, @JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson)  Color seedColor,  bool pureBlack, @JsonKey(name: 'variant')  DynamicSchemeVariant schemeVariant,  double textScale, @JsonKey(name: 'serverUrl')  String? serverUrl, @JsonKey(name: 'secret')  String? secret, @JsonKey(name: 'bg')  String? backgroundBase64, @JsonKey(name: 'bgPath')  String? backgroundPath, @JsonKey(name: 'bgOpacity')  double backgroundOpacity,  bool autoRotate, @JsonKey(name: 'rotSpeed')  double rotationSpeed,  double markerScale,  double globeScale,  InitialView initialView,  double customLat,  double customLng,  int maxDelayMs,  bool hideBlocked,  ProbeSort probeSort, @JsonKey(name: 'globeQuality')  GlobeTextureQuality globeQuality, @JsonKey(name: 'globeTime')  GlobeTime globeTime, @JsonKey(name: 'probeInterval')  int probeIntervalSec, @JsonKey(name: 'compact')  bool compactNodeList,  SheetAnimation sheetAnimation,  AppLocale locale)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.seedColor,_that.pureBlack,_that.schemeVariant,_that.textScale,_that.serverUrl,_that.secret,_that.backgroundBase64,_that.backgroundPath,_that.backgroundOpacity,_that.autoRotate,_that.rotationSpeed,_that.markerScale,_that.globeScale,_that.initialView,_that.customLat,_that.customLng,_that.maxDelayMs,_that.hideBlocked,_that.probeSort,_that.globeQuality,_that.globeTime,_that.probeIntervalSec,_that.compactNodeList,_that.sheetAnimation,_that.locale);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeMode themeMode, @JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson)  Color seedColor,  bool pureBlack, @JsonKey(name: 'variant')  DynamicSchemeVariant schemeVariant,  double textScale, @JsonKey(name: 'serverUrl')  String? serverUrl, @JsonKey(name: 'secret')  String? secret, @JsonKey(name: 'bg')  String? backgroundBase64, @JsonKey(name: 'bgPath')  String? backgroundPath, @JsonKey(name: 'bgOpacity')  double backgroundOpacity,  bool autoRotate, @JsonKey(name: 'rotSpeed')  double rotationSpeed,  double markerScale,  double globeScale,  InitialView initialView,  double customLat,  double customLng,  int maxDelayMs,  bool hideBlocked,  ProbeSort probeSort, @JsonKey(name: 'globeQuality')  GlobeTextureQuality globeQuality, @JsonKey(name: 'globeTime')  GlobeTime globeTime, @JsonKey(name: 'probeInterval')  int probeIntervalSec, @JsonKey(name: 'compact')  bool compactNodeList,  SheetAnimation sheetAnimation,  AppLocale locale)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.seedColor,_that.pureBlack,_that.schemeVariant,_that.textScale,_that.serverUrl,_that.secret,_that.backgroundBase64,_that.backgroundPath,_that.backgroundOpacity,_that.autoRotate,_that.rotationSpeed,_that.markerScale,_that.globeScale,_that.initialView,_that.customLat,_that.customLng,_that.maxDelayMs,_that.hideBlocked,_that.probeSort,_that.globeQuality,_that.globeTime,_that.probeIntervalSec,_that.compactNodeList,_that.sheetAnimation,_that.locale);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings extends AppSettings {
  const _AppSettings({this.themeMode = ThemeMode.system, @JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson) this.seedColor = const Color(0xFFE65100), this.pureBlack = false, @JsonKey(name: 'variant') this.schemeVariant = DynamicSchemeVariant.content, this.textScale = 1.0, @JsonKey(name: 'serverUrl') this.serverUrl, @JsonKey(name: 'secret') this.secret, @JsonKey(name: 'bg') this.backgroundBase64, @JsonKey(name: 'bgPath') this.backgroundPath, @JsonKey(name: 'bgOpacity') this.backgroundOpacity = 0.65, this.autoRotate = false, @JsonKey(name: 'rotSpeed') this.rotationSpeed = 0.01, this.markerScale = 1.0, this.globeScale = 1.0, this.initialView = InitialView.auto, this.customLat = 28, this.customLng = 100, this.maxDelayMs = 0, this.hideBlocked = false, this.probeSort = ProbeSort.delay, @JsonKey(name: 'globeQuality') this.globeQuality = GlobeTextureQuality.k8, @JsonKey(name: 'globeTime') this.globeTime = GlobeTime.day, @JsonKey(name: 'probeInterval') this.probeIntervalSec = 30, @JsonKey(name: 'compact') this.compactNodeList = false, this.sheetAnimation = SheetAnimation.slide, this.locale = AppLocale.system}): super._();
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  ThemeMode themeMode;
@override@JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson) final  Color seedColor;
@override@JsonKey() final  bool pureBlack;
@override@JsonKey(name: 'variant') final  DynamicSchemeVariant schemeVariant;
@override@JsonKey() final  double textScale;
/// Mihomo external-controller API base URL (e.g. `http://localhost:9091`);
/// null falls back to the `.env` host/port.
@override@JsonKey(name: 'serverUrl') final  String? serverUrl;
/// Bearer secret for the controller; null falls back to `.env` `secret`.
@override@JsonKey(name: 'secret') final  String? secret;
@override@JsonKey(name: 'bg') final  String? backgroundBase64;
/// File-system path of the persisted background image (native only).
@override@JsonKey(name: 'bgPath') final  String? backgroundPath;
@override@JsonKey(name: 'bgOpacity') final  double backgroundOpacity;
@override@JsonKey() final  bool autoRotate;
@override@JsonKey(name: 'rotSpeed') final  double rotationSpeed;
@override@JsonKey() final  double markerScale;
@override@JsonKey() final  double globeScale;
@override@JsonKey() final  InitialView initialView;
@override@JsonKey() final  double customLat;
@override@JsonKey() final  double customLng;
@override@JsonKey() final  int maxDelayMs;
@override@JsonKey() final  bool hideBlocked;
@override@JsonKey() final  ProbeSort probeSort;
@override@JsonKey(name: 'globeQuality') final  GlobeTextureQuality globeQuality;
@override@JsonKey(name: 'globeTime') final  GlobeTime globeTime;
/// Periodic full-probe interval in seconds; -1 disables the timer.
@override@JsonKey(name: 'probeInterval') final  int probeIntervalSec;
@override@JsonKey(name: 'compact') final  bool compactNodeList;
@override@JsonKey() final  SheetAnimation sheetAnimation;
@override@JsonKey() final  AppLocale locale;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&const DeepCollectionEquality().equals(other.seedColor, seedColor)&&(identical(other.pureBlack, pureBlack) || other.pureBlack == pureBlack)&&(identical(other.schemeVariant, schemeVariant) || other.schemeVariant == schemeVariant)&&(identical(other.textScale, textScale) || other.textScale == textScale)&&(identical(other.serverUrl, serverUrl) || other.serverUrl == serverUrl)&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.backgroundBase64, backgroundBase64) || other.backgroundBase64 == backgroundBase64)&&(identical(other.backgroundPath, backgroundPath) || other.backgroundPath == backgroundPath)&&(identical(other.backgroundOpacity, backgroundOpacity) || other.backgroundOpacity == backgroundOpacity)&&(identical(other.autoRotate, autoRotate) || other.autoRotate == autoRotate)&&(identical(other.rotationSpeed, rotationSpeed) || other.rotationSpeed == rotationSpeed)&&(identical(other.markerScale, markerScale) || other.markerScale == markerScale)&&(identical(other.globeScale, globeScale) || other.globeScale == globeScale)&&(identical(other.initialView, initialView) || other.initialView == initialView)&&(identical(other.customLat, customLat) || other.customLat == customLat)&&(identical(other.customLng, customLng) || other.customLng == customLng)&&(identical(other.maxDelayMs, maxDelayMs) || other.maxDelayMs == maxDelayMs)&&(identical(other.hideBlocked, hideBlocked) || other.hideBlocked == hideBlocked)&&(identical(other.probeSort, probeSort) || other.probeSort == probeSort)&&(identical(other.globeQuality, globeQuality) || other.globeQuality == globeQuality)&&(identical(other.globeTime, globeTime) || other.globeTime == globeTime)&&(identical(other.probeIntervalSec, probeIntervalSec) || other.probeIntervalSec == probeIntervalSec)&&(identical(other.compactNodeList, compactNodeList) || other.compactNodeList == compactNodeList)&&(identical(other.sheetAnimation, sheetAnimation) || other.sheetAnimation == sheetAnimation)&&(identical(other.locale, locale) || other.locale == locale));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,themeMode,const DeepCollectionEquality().hash(seedColor),pureBlack,schemeVariant,textScale,serverUrl,secret,backgroundBase64,backgroundPath,backgroundOpacity,autoRotate,rotationSpeed,markerScale,globeScale,initialView,customLat,customLng,maxDelayMs,hideBlocked,probeSort,globeQuality,globeTime,probeIntervalSec,compactNodeList,sheetAnimation,locale]);

@override
String toString() {
  return 'AppSettings(themeMode: $themeMode, seedColor: $seedColor, pureBlack: $pureBlack, schemeVariant: $schemeVariant, textScale: $textScale, serverUrl: $serverUrl, secret: $secret, backgroundBase64: $backgroundBase64, backgroundPath: $backgroundPath, backgroundOpacity: $backgroundOpacity, autoRotate: $autoRotate, rotationSpeed: $rotationSpeed, markerScale: $markerScale, globeScale: $globeScale, initialView: $initialView, customLat: $customLat, customLng: $customLng, maxDelayMs: $maxDelayMs, hideBlocked: $hideBlocked, probeSort: $probeSort, globeQuality: $globeQuality, globeTime: $globeTime, probeIntervalSec: $probeIntervalSec, compactNodeList: $compactNodeList, sheetAnimation: $sheetAnimation, locale: $locale)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 ThemeMode themeMode,@JsonKey(name: 'seed', fromJson: _colorFromJson, toJson: _colorToJson) Color seedColor, bool pureBlack,@JsonKey(name: 'variant') DynamicSchemeVariant schemeVariant, double textScale,@JsonKey(name: 'serverUrl') String? serverUrl,@JsonKey(name: 'secret') String? secret,@JsonKey(name: 'bg') String? backgroundBase64,@JsonKey(name: 'bgPath') String? backgroundPath,@JsonKey(name: 'bgOpacity') double backgroundOpacity, bool autoRotate,@JsonKey(name: 'rotSpeed') double rotationSpeed, double markerScale, double globeScale, InitialView initialView, double customLat, double customLng, int maxDelayMs, bool hideBlocked, ProbeSort probeSort,@JsonKey(name: 'globeQuality') GlobeTextureQuality globeQuality,@JsonKey(name: 'globeTime') GlobeTime globeTime,@JsonKey(name: 'probeInterval') int probeIntervalSec,@JsonKey(name: 'compact') bool compactNodeList, SheetAnimation sheetAnimation, AppLocale locale
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? seedColor = freezed,Object? pureBlack = null,Object? schemeVariant = null,Object? textScale = null,Object? serverUrl = freezed,Object? secret = freezed,Object? backgroundBase64 = freezed,Object? backgroundPath = freezed,Object? backgroundOpacity = null,Object? autoRotate = null,Object? rotationSpeed = null,Object? markerScale = null,Object? globeScale = null,Object? initialView = null,Object? customLat = null,Object? customLng = null,Object? maxDelayMs = null,Object? hideBlocked = null,Object? probeSort = null,Object? globeQuality = null,Object? globeTime = null,Object? probeIntervalSec = null,Object? compactNodeList = null,Object? sheetAnimation = null,Object? locale = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,seedColor: freezed == seedColor ? _self.seedColor : seedColor // ignore: cast_nullable_to_non_nullable
as Color,pureBlack: null == pureBlack ? _self.pureBlack : pureBlack // ignore: cast_nullable_to_non_nullable
as bool,schemeVariant: null == schemeVariant ? _self.schemeVariant : schemeVariant // ignore: cast_nullable_to_non_nullable
as DynamicSchemeVariant,textScale: null == textScale ? _self.textScale : textScale // ignore: cast_nullable_to_non_nullable
as double,serverUrl: freezed == serverUrl ? _self.serverUrl : serverUrl // ignore: cast_nullable_to_non_nullable
as String?,secret: freezed == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String?,backgroundBase64: freezed == backgroundBase64 ? _self.backgroundBase64 : backgroundBase64 // ignore: cast_nullable_to_non_nullable
as String?,backgroundPath: freezed == backgroundPath ? _self.backgroundPath : backgroundPath // ignore: cast_nullable_to_non_nullable
as String?,backgroundOpacity: null == backgroundOpacity ? _self.backgroundOpacity : backgroundOpacity // ignore: cast_nullable_to_non_nullable
as double,autoRotate: null == autoRotate ? _self.autoRotate : autoRotate // ignore: cast_nullable_to_non_nullable
as bool,rotationSpeed: null == rotationSpeed ? _self.rotationSpeed : rotationSpeed // ignore: cast_nullable_to_non_nullable
as double,markerScale: null == markerScale ? _self.markerScale : markerScale // ignore: cast_nullable_to_non_nullable
as double,globeScale: null == globeScale ? _self.globeScale : globeScale // ignore: cast_nullable_to_non_nullable
as double,initialView: null == initialView ? _self.initialView : initialView // ignore: cast_nullable_to_non_nullable
as InitialView,customLat: null == customLat ? _self.customLat : customLat // ignore: cast_nullable_to_non_nullable
as double,customLng: null == customLng ? _self.customLng : customLng // ignore: cast_nullable_to_non_nullable
as double,maxDelayMs: null == maxDelayMs ? _self.maxDelayMs : maxDelayMs // ignore: cast_nullable_to_non_nullable
as int,hideBlocked: null == hideBlocked ? _self.hideBlocked : hideBlocked // ignore: cast_nullable_to_non_nullable
as bool,probeSort: null == probeSort ? _self.probeSort : probeSort // ignore: cast_nullable_to_non_nullable
as ProbeSort,globeQuality: null == globeQuality ? _self.globeQuality : globeQuality // ignore: cast_nullable_to_non_nullable
as GlobeTextureQuality,globeTime: null == globeTime ? _self.globeTime : globeTime // ignore: cast_nullable_to_non_nullable
as GlobeTime,probeIntervalSec: null == probeIntervalSec ? _self.probeIntervalSec : probeIntervalSec // ignore: cast_nullable_to_non_nullable
as int,compactNodeList: null == compactNodeList ? _self.compactNodeList : compactNodeList // ignore: cast_nullable_to_non_nullable
as bool,sheetAnimation: null == sheetAnimation ? _self.sheetAnimation : sheetAnimation // ignore: cast_nullable_to_non_nullable
as SheetAnimation,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as AppLocale,
  ));
}


}

// dart format on
