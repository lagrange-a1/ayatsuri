import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ayatsuri'**
  String get appTitle;

  /// No description provided for @navGlobe.
  ///
  /// In en, this message translates to:
  /// **'Globe'**
  String get navGlobe;

  /// No description provided for @navInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get navInfo;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @infoTitle.
  ///
  /// In en, this message translates to:
  /// **'ayatsuri · Mihomo Info'**
  String get infoTitle;

  /// No description provided for @fetchAll.
  ///
  /// In en, this message translates to:
  /// **'Fetch all'**
  String get fetchAll;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get requestFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @noDataHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to query the Mihomo core.'**
  String get noDataHint;

  /// No description provided for @fetchAllData.
  ///
  /// In en, this message translates to:
  /// **'Fetch All Data'**
  String get fetchAllData;

  /// No description provided for @sectionVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get sectionVersion;

  /// No description provided for @sectionConfigs.
  ///
  /// In en, this message translates to:
  /// **'Configs'**
  String get sectionConfigs;

  /// No description provided for @sectionProxies.
  ///
  /// In en, this message translates to:
  /// **'Proxies'**
  String get sectionProxies;

  /// No description provided for @sectionGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get sectionGroups;

  /// No description provided for @sectionRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get sectionRules;

  /// No description provided for @sectionConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get sectionConnections;

  /// No description provided for @sectionTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get sectionTraffic;

  /// No description provided for @sectionMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get sectionMemory;

  /// No description provided for @sectionLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get sectionLogs;

  /// No description provided for @globeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a node · Globe'**
  String get globeTitle;

  /// No description provided for @reloadProxies.
  ///
  /// In en, this message translates to:
  /// **'Reload proxies'**
  String get reloadProxies;

  /// No description provided for @globeTestPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Globe (3D unavailable in tests)'**
  String get globeTestPlaceholder;

  /// No description provided for @tapCountry.
  ///
  /// In en, this message translates to:
  /// **'Tap a country'**
  String get tapCountry;

  /// No description provided for @selectedCountry.
  ///
  /// In en, this message translates to:
  /// **'Selected: {flag} {name}'**
  String selectedCountry(String flag, String name);

  /// No description provided for @selectedSnack.
  ///
  /// In en, this message translates to:
  /// **'Selected {proxy} in {group}'**
  String selectedSnack(String proxy, String group);

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failed(String error);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @nodesCount.
  ///
  /// In en, this message translates to:
  /// **'{alpha2} · {count} node(s)'**
  String nodesCount(String alpha2, int count);

  /// No description provided for @failedToLoadProxies.
  ///
  /// In en, this message translates to:
  /// **'Failed to load proxies:\n{error}'**
  String failedToLoadProxies(String error);

  /// No description provided for @noMatchingNode.
  ///
  /// In en, this message translates to:
  /// **'No matching node for this country.'**
  String get noMatchingNode;

  /// No description provided for @globeDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Globe data failed: {error}'**
  String globeDataFailed(String error);

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'blocked'**
  String get blocked;

  /// No description provided for @delayMs.
  ///
  /// In en, this message translates to:
  /// **'{delay} ms'**
  String delayMs(int delay);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeColor.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get themeColor;

  /// No description provided for @pureBlack.
  ///
  /// In en, this message translates to:
  /// **'Pure black (OLED)'**
  String get pureBlack;

  /// No description provided for @pureBlackSub.
  ///
  /// In en, this message translates to:
  /// **'Pure-black surfaces in dark mode'**
  String get pureBlackSub;

  /// No description provided for @colorStyle.
  ///
  /// In en, this message translates to:
  /// **'Color style'**
  String get colorStyle;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @background.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get background;

  /// No description provided for @noCustomBackground.
  ///
  /// In en, this message translates to:
  /// **'No custom background'**
  String get noCustomBackground;

  /// No description provided for @pickImage.
  ///
  /// In en, this message translates to:
  /// **'Pick image'**
  String get pickImage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @backgroundDimming.
  ///
  /// In en, this message translates to:
  /// **'Background dimming'**
  String get backgroundDimming;

  /// No description provided for @globeHeader.
  ///
  /// In en, this message translates to:
  /// **'Globe'**
  String get globeHeader;

  /// No description provided for @autoRotate.
  ///
  /// In en, this message translates to:
  /// **'Auto-rotate'**
  String get autoRotate;

  /// No description provided for @rotationSpeed.
  ///
  /// In en, this message translates to:
  /// **'Rotation speed'**
  String get rotationSpeed;

  /// No description provided for @markerSize.
  ///
  /// In en, this message translates to:
  /// **'Marker size'**
  String get markerSize;

  /// No description provided for @initialView.
  ///
  /// In en, this message translates to:
  /// **'Initial view'**
  String get initialView;

  /// No description provided for @asiaView.
  ///
  /// In en, this message translates to:
  /// **'Asia (28°, 100°)'**
  String get asiaView;

  /// No description provided for @globalView.
  ///
  /// In en, this message translates to:
  /// **'Global (0°, 0°)'**
  String get globalView;

  /// No description provided for @customView.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customView;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @nodeProbe.
  ///
  /// In en, this message translates to:
  /// **'Node probe'**
  String get nodeProbe;

  /// No description provided for @maxDelayShown.
  ///
  /// In en, this message translates to:
  /// **'Max delay shown'**
  String get maxDelayShown;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @maxDelayMs.
  ///
  /// In en, this message translates to:
  /// **'{value} ms'**
  String maxDelayMs(int value);

  /// No description provided for @hideBlocked.
  ///
  /// In en, this message translates to:
  /// **'Hide blocked nodes'**
  String get hideBlocked;

  /// No description provided for @byDelay.
  ///
  /// In en, this message translates to:
  /// **'By delay'**
  String get byDelay;

  /// No description provided for @byName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get byName;

  /// No description provided for @compactNodeList.
  ///
  /// In en, this message translates to:
  /// **'Compact node list'**
  String get compactNodeList;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @globeScale.
  ///
  /// In en, this message translates to:
  /// **'Globe size'**
  String get globeScale;

  /// No description provided for @initialViewAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (current proxy)'**
  String get initialViewAuto;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'TIMEOUT'**
  String get timeout;

  /// No description provided for @probeInterval.
  ///
  /// In en, this message translates to:
  /// **'Probe all nodes periodically'**
  String get probeInterval;

  /// No description provided for @probeIntervalOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get probeIntervalOff;

  /// No description provided for @probeIntervalSec.
  ///
  /// In en, this message translates to:
  /// **'Every {seconds} s'**
  String probeIntervalSec(int seconds);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
