// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ayatsuri';

  @override
  String get navGlobe => 'Globe';

  @override
  String get navInfo => 'Info';

  @override
  String get navSettings => 'Settings';

  @override
  String get infoTitle => 'ayatsuri · Mihomo Info';

  @override
  String get fetchAll => 'Fetch all';

  @override
  String get requestFailed => 'Request failed';

  @override
  String get retry => 'Retry';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get noDataHint => 'Tap the button below to query the Mihomo core.';

  @override
  String get fetchAllData => 'Fetch All Data';

  @override
  String get sectionVersion => 'Version';

  @override
  String get sectionConfigs => 'Configs';

  @override
  String get sectionProxies => 'Proxies';

  @override
  String get sectionGroups => 'Groups';

  @override
  String get sectionRules => 'Rules';

  @override
  String get sectionConnections => 'Connections';

  @override
  String get sectionTraffic => 'Traffic';

  @override
  String get sectionMemory => 'Memory';

  @override
  String get sectionLogs => 'Logs';

  @override
  String get globeTitle => 'Select a node · Globe';

  @override
  String get reloadProxies => 'Reload proxies';

  @override
  String get globeTestPlaceholder => 'Globe (3D unavailable in tests)';

  @override
  String get tapCountry => 'Tap a country';

  @override
  String selectedCountry(String flag, String name) {
    return 'Selected: $flag $name';
  }

  @override
  String selectedSnack(String proxy, String group) {
    return 'Selected $proxy in $group';
  }

  @override
  String failed(String error) {
    return 'Failed: $error';
  }

  @override
  String get close => 'Close';

  @override
  String nodesCount(String alpha2, int count) {
    return '$alpha2 · $count node(s)';
  }

  @override
  String failedToLoadProxies(String error) {
    return 'Failed to load proxies:\n$error';
  }

  @override
  String get noMatchingNode => 'No matching node for this country.';

  @override
  String globeDataFailed(String error) {
    return 'Globe data failed: $error';
  }

  @override
  String get blocked => 'blocked';

  @override
  String delayMs(int delay) {
    return '$delay ms';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeColor => 'Theme color';

  @override
  String get pureBlack => 'Pure black (OLED)';

  @override
  String get pureBlackSub => 'Pure-black surfaces in dark mode';

  @override
  String get colorStyle => 'Color style';

  @override
  String get textSize => 'Text size';

  @override
  String get connection => 'Connection';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'http://localhost:9091';

  @override
  String get secret => 'Secret';

  @override
  String get secretHint => 'foobar';

  @override
  String get background => 'Background';

  @override
  String get noCustomBackground => 'No custom background';

  @override
  String get pickImage => 'Pick image';

  @override
  String get remove => 'Remove';

  @override
  String get backgroundDimming => 'Background dimming';

  @override
  String get globeHeader => 'Globe';

  @override
  String get autoRotate => 'Auto-rotate';

  @override
  String get rotationSpeed => 'Rotation speed';

  @override
  String get markerSize => 'Marker size';

  @override
  String get initialView => 'Initial view';

  @override
  String get asiaView => 'Asia (28°, 100°)';

  @override
  String get globalView => 'Global (0°, 0°)';

  @override
  String get customView => 'Custom';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get nodeProbe => 'Node probe';

  @override
  String get maxDelayShown => 'Max delay shown';

  @override
  String get unlimited => 'Unlimited';

  @override
  String maxDelayMs(int value) {
    return '$value ms';
  }

  @override
  String get hideBlocked => 'Hide blocked nodes';

  @override
  String get byDelay => 'By delay';

  @override
  String get byName => 'By name';

  @override
  String get compactNodeList => 'Compact node list';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get globeScale => 'Globe size';

  @override
  String get initialViewAuto => 'Auto (current proxy)';

  @override
  String get timeout => 'TIMEOUT';

  @override
  String get probeInterval => 'Probe all nodes periodically';

  @override
  String get probeIntervalOff => 'Off';

  @override
  String probeIntervalSec(int seconds) {
    return 'Every $seconds s';
  }

  @override
  String get currentNode => 'current node';
}
