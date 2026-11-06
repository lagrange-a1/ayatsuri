// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ayatsuri';

  @override
  String get navGlobe => '地球';

  @override
  String get navInfo => '信息';

  @override
  String get navSettings => '设置';

  @override
  String get infoTitle => 'ayatsuri · Mihomo 信息';

  @override
  String get fetchAll => '全部获取';

  @override
  String get requestFailed => '请求失败';

  @override
  String get retry => '重试';

  @override
  String get noDataYet => '暂无数据';

  @override
  String get noDataHint => '点击下方按钮查询 Mihomo 核心。';

  @override
  String get fetchAllData => '获取全部数据';

  @override
  String get sectionVersion => '版本';

  @override
  String get sectionConfigs => '配置';

  @override
  String get sectionProxies => '代理';

  @override
  String get sectionGroups => '策略组';

  @override
  String get sectionRules => '规则';

  @override
  String get sectionConnections => '连接';

  @override
  String get sectionTraffic => '流量';

  @override
  String get sectionMemory => '内存';

  @override
  String get sectionLogs => '日志';

  @override
  String get globeTitle => '选择节点 · 地球';

  @override
  String get reloadProxies => '重新加载代理';

  @override
  String get globeTestPlaceholder => '地球（测试中不可用）';

  @override
  String get tapCountry => '点击一个国家';

  @override
  String selectedCountry(String flag, String name) {
    return '已选择：$flag $name';
  }

  @override
  String selectedSnack(String proxy, String group) {
    return '已在 $group 中选择 $proxy';
  }

  @override
  String failed(String error) {
    return '失败：$error';
  }

  @override
  String get close => '关闭';

  @override
  String nodesCount(String alpha2, int count) {
    return '$alpha2 · $count 个节点';
  }

  @override
  String failedToLoadProxies(String error) {
    return '加载代理失败：\n$error';
  }

  @override
  String get noMatchingNode => '本国暂无匹配节点。';

  @override
  String globeDataFailed(String error) {
    return '地球数据加载失败：$error';
  }

  @override
  String get blocked => '已屏蔽';

  @override
  String delayMs(int delay) {
    return '$delay 毫秒';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get appearance => '外观';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeColor => '主题颜色';

  @override
  String get pureBlack => '纯黑（OLED）';

  @override
  String get pureBlackSub => '深色模式下使用纯黑表面';

  @override
  String get colorStyle => '配色风格';

  @override
  String get textSize => '文字大小';

  @override
  String get connection => '连接';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get serverUrlHint => 'http://localhost:9091';

  @override
  String get secret => '密钥';

  @override
  String get secretHint => 'foobar';

  @override
  String get background => '背景';

  @override
  String get noCustomBackground => '无自定义背景';

  @override
  String get pickImage => '选择图片';

  @override
  String get remove => '移除';

  @override
  String get backgroundDimming => '背景调暗';

  @override
  String get globeHeader => '地球';

  @override
  String get autoRotate => '自动旋转';

  @override
  String get rotationSpeed => '旋转速度';

  @override
  String get markerSize => '标记大小';

  @override
  String get initialView => '初始视角';

  @override
  String get asiaView => '亚洲 (28°, 100°)';

  @override
  String get globalView => '全球 (0°, 0°)';

  @override
  String get customView => '自定义';

  @override
  String get latitude => '纬度';

  @override
  String get longitude => '经度';

  @override
  String get nodeProbe => '节点 ping';

  @override
  String get maxDelayShown => '最大显示延迟';

  @override
  String get unlimited => '不限';

  @override
  String maxDelayMs(int value) {
    return '$value 毫秒';
  }

  @override
  String get hideBlocked => '隐藏已屏蔽节点';

  @override
  String get byDelay => '按延迟';

  @override
  String get byName => '按名称';

  @override
  String get compactNodeList => '紧凑节点列表';

  @override
  String get animation => '动画';

  @override
  String get animationSlide => '上滑';

  @override
  String get animationFade => '淡入';

  @override
  String get animationScale => '缩放';

  @override
  String get animationSpring => '弹性';

  @override
  String get animationNone => '无';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get globeScale => '地球大小';

  @override
  String get globeQuality => '地球贴图清晰度';

  @override
  String get globeQuality2k => '2K (2048×1024)';

  @override
  String get globeQuality8k => '8K (8192×4096)';

  @override
  String get globeTime => '地球时间';

  @override
  String get globeTimeSystem => '跟随系统';

  @override
  String get globeTimeDay => '白天';

  @override
  String get globeTimeNight => '夜晚';

  @override
  String get initialViewAuto => '自动（当前节点）';

  @override
  String get timeout => '超时';

  @override
  String get probeInterval => '定期 ping（全部节点）';

  @override
  String get probeIntervalOff => '关闭';

  @override
  String probeIntervalSec(int seconds) {
    return '每 $seconds 秒';
  }

  @override
  String get currentNode => '当前节点';
}
