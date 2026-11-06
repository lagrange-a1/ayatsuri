import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:ayatsuri/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'endpoints.dart';
import 'info/mihomo_info.dart';
import 'settings/app_settings.dart';
import 'settings/settings_page.dart';
import 'views/globe_map_page.dart';
import 'views/info_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    // .env is not bundled (dev-only asset); fall back to defaults.
  }
  final settingsController = AppSettingsController();
  await settingsController.load();
  runApp(MyApp(settingsController: settingsController));
}

class MyApp extends StatelessWidget {
  MyApp({super.key, AppSettingsController? settingsController})
    : _controller = settingsController ?? AppSettingsController();

  final AppSettingsController _controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final s = _controller.settings;
        return MaterialApp(
          title: 'ayatsuri',
          locale: s.locale.flutterLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          themeMode: s.themeMode,
          theme: buildAppTheme(s, Brightness.light),
          darkTheme: buildAppTheme(s, Brightness.dark),
          builder: (context, child) {
            // Overlay the in-app text-scale factor on top of the system
            // text scale instead of replacing it (the old code overwrote
            // the user's accessibility setting entirely). A factor of 1.0
            // passes the system scaler through untouched.
            final mq = MediaQuery.of(context);
            if (s.textScale == 1.0) return child!;
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(
                  mq.textScaler.scale(1.0) * s.textScale,
                ),
              ),
              child: child!,
            );
          },
          home: MihomoApp(settingsController: _controller),
        );
      },
    );
  }
}

/// Bottom-navigation shell wrapping the system info page and the proxy map page.
class MihomoApp extends StatefulWidget {
  const MihomoApp({super.key, required this.settingsController});

  final AppSettingsController settingsController;

  @override
  State<MihomoApp> createState() => _MihomoAppState();
}

class _MihomoAppState extends State<MihomoApp> {
  int _index = 0;
  late final MihomoAPI _api;

  /// Identity of the controller endpoint currently in use; the data pages
  /// are keyed by it so a settings change rebuilds them (refetching).
  late String _connKey;

  static String _keyOf(AppSettings s) => '${s.serverUrl}|${s.secret}';

  @override
  void initState() {
    super.initState();
    final s = widget.settingsController.settings;
    _api = MihomoAPI(baseUrl: s.serverUrl, secret: s.secret);
    _connKey = _keyOf(s);
    widget.settingsController.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    final key = _keyOf(widget.settingsController.settings);
    if (key == _connKey) return;
    _connKey = key;
    final s = widget.settingsController.settings;
    _api.reconfigure(baseUrl: s.serverUrl, secret: s.secret);
    setState(() {});
  }

  @override
  void dispose() {
    widget.settingsController.removeListener(_onSettingsChanged);
    _api.dio.close();
    super.dispose();
  }

  /// The globe page is the home tab; both pages auto-fetch controller state
  /// when they are first built (startup), so the visible page is fresh.
  List<Widget> get pages => [
    GlobeMapPage(
      key: ValueKey('globe$_connKey'),
      api: _api,
      settingsController: widget.settingsController,
    ),
    MihomoInfo(key: ValueKey('info$_connKey'), api: _api),
    SettingsPage(controller: widget.settingsController),
  ];

  List<BottomNavigationBarItem> items(AppLocalizations l10n) => [
    BottomNavigationBarItem(
      icon: const Icon(Icons.public, size: 28),
      label: l10n.navGlobe,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.info, size: 28),
      label: l10n.navInfo,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.settings, size: 28),
      label: l10n.navSettings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: items(AppLocalizations.of(context)),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class MihomoInfo extends StatefulWidget {
  const MihomoInfo({super.key, required this.api});

  final MihomoAPI api;

  @override
  State<MihomoInfo> createState() => _MihomoInfoState();
}

class _MihomoInfoState extends State<MihomoInfo> {
  late final MihomoAPI _api;
  bool _loading = false;
  String? _error;

  // ── Collected data ──────────────────────────────────────────────────
  /// The nine info sections, in display order.
  List<Map<String, dynamic>?> get _sections => [
    _version,
    _configs,
    _proxies,
    _groups,
    _rules,
    _connections,
    _traffic,
    _memory,
    _logs,
  ];

  bool get _hasAnyData => _sections.any((d) => d != null);

  Map<String, dynamic>? _version;
  Map<String, dynamic>? _configs;
  Map<String, dynamic>? _proxies;
  Map<String, dynamic>? _groups;
  Map<String, dynamic>? _rules;
  Map<String, dynamic>? _connections;
  Map<String, dynamic>? _traffic;
  Map<String, dynamic>? _memory;
  Map<String, dynamic>? _logs;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    // Fetch the controller state as soon as the page starts.
    _fetchEverything();
  }

  Future<void> _fetchEverything() async {
    if (!mounted || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    // Each endpoint is fetched independently: one slow/flaky endpoint
    // (e.g. the streaming /traffic, /memory, /logs) must not fail the
    // whole page. Transient connection failures are retried every 0.5s
    // in the background and degrade to an empty section; only
    // non-transient failures surface the error page.
    // (fetch, assign) pairs — one table instead of nine near-identical
    // closures.
    final fetchers =
        <(Future<dynamic> Function(), void Function(Map<String, dynamic>))>[
          (_api.getVersion, (d) => _version = d),
          (_api.getConfigs, (d) => _configs = d),
          (_api.getProxies, (d) => _proxies = d),
          (_api.getGroups, (d) => _groups = d),
          (_api.getRules, (d) => _rules = d),
          (_api.getConnections, (d) => _connections = d),
          (_api.getTraffic, (d) => _traffic = d),
          (_api.getMemory, (d) => _memory = d),
          (_api.getLogs, (d) => _logs = d),
        ];

    var pending = fetchers.length;
    for (final (fetch, assign) in fetchers) {
      retryTransient(fetch)
          .then((r) {
            if (r != null) assign(r.data as Map<String, dynamic>);
          })
          .catchError((Object e) {
            // Non-transient failure: remember the first one; the error
            // page only shows when nothing loaded at all.
            _error ??= _formatError(e);
          })
          .whenComplete(() {
            pending--;
            if (mounted) {
              setState(() {
                _loading = pending > 0;
                if (pending == 0 && _version == null && _error != null) {
                  // Keep the error so the page can show it.
                }
              });
            }
          });
    }
  }

  String _formatError(Object e) => e.toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(l10n.infoTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : _fetchEverything,
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: l10n.fetchAll,
          ),
        ],
      ),
      floatingActionButton: _version != null && !_loading
          ? FloatingActionButton(
              onPressed: _fetchEverything,
              tooltip: l10n.fetchAll,
              child: const Icon(Icons.refresh),
            )
          : null,
      // Loading takes precedence over the empty/error states while a fetch
      // is in flight (initial load, nothing to show yet): show a spinner,
      // not the "no data" placeholder. With data already loaded a refresh
      // keeps the dashboard visible underneath.
      body: _version == null && _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _version == null && !_hasAnyData
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: .center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.requestFailed,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: .center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _fetchEverything,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            )
          : _version == null
          ? Center(
              child: Column(
                mainAxisAlignment: .center,
                children: [
                  const Icon(
                    Icons.storage_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noDataYet),
                  const SizedBox(height: 8),
                  Text(l10n.noDataHint, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _loading ? null : _fetchEverything,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.fetchAllData),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : InfoDashboard(
              summary: MihomoInfoSummary.fromAll(
                version: _version,
                configs: _configs,
                proxies: _proxies,
                group: _groups,
                rules: _rules,
                connections: _connections,
                traffic: _traffic,
                memory: _memory,
                logs: _logs,
              ),
              rawBySection: {
                'version': _version,
                'configs': _configs,
                'proxies': _proxies,
                'groups': _groups,
                'rules': _rules,
                'connections': _connections,
                'traffic': _traffic,
                'memory': _memory,
                'logs': _logs,
              },
            ),
    );
  }
}
