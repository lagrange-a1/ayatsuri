import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/re_highlight.dart';

import 'package:ayatsuri/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'endpoints.dart';
import 'settings/app_settings.dart';
import 'settings/settings_page.dart';
import 'views/globe_map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(s.textScale)),
            child: child!,
          ),
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
    if (!mounted) return;
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
        <(Future<Response> Function(), void Function(Map<String, dynamic>))>[
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
            _error ??= e is DioException ? _formatDioError(e) : e.toString();
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

  String _formatDioError(DioException e) {
    final buf = StringBuffer('DioException: ${e.type}\n');
    if (e.message != null) buf.writeln('message: ${e.message}');
    if (e.response != null) {
      buf.writeln('status: ${e.response?.statusCode}');
      buf.writeln('data: ${e.response?.data}');
    }
    return buf.toString().trim();
  }

  // ── Builders ────────────────────────────────────────────────────────

  Widget _section(String title, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(
          data.isEmpty ? Icons.info_outline : Icons.expand_more,
          size: 20,
        ),
        children: [_JsonView(data: data)],
      ),
    );
  }

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
      // Error page only when nothing loaded at all; partial data (or
      // transient failures degraded to empty) keeps the list/empty state.
      body: _error != null && _version == null && !_hasAnyData
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
                      onPressed: _fetchEverything,
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
                    onPressed: _fetchEverything,
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
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final (title, data) in <(String, Map<String, dynamic>?)>[
                  (l10n.sectionVersion, _version),
                  (l10n.sectionConfigs, _configs),
                  (l10n.sectionProxies, _proxies),
                  (l10n.sectionGroups, _groups),
                  (l10n.sectionRules, _rules),
                  (l10n.sectionConnections, _connections),
                  (l10n.sectionTraffic, _traffic),
                  (l10n.sectionMemory, _memory),
                  (l10n.sectionLogs, _logs),
                ])
                  _section(title, data),
              ],
            ),
    );
  }
}

// ── Pretty JSON tree ────────────────────────────────────────────────────

class _JsonView extends StatefulWidget {
  const _JsonView({required this.data});

  final Map<String, dynamic> data;

  @override
  State<_JsonView> createState() => _JsonViewState();
}

class _JsonViewState extends State<_JsonView> {
  static final Highlight _highlighter = Highlight()
    ..registerLanguages({'json': langJson});

  // Standard pretty JSON (commas terminate the preceding line) via
  // jsonEncode with indent; the old hand-rolled printer wrote ',' after
  // writeln() so commas started the next line.
  static String prettyJson(Map<String, dynamic> json) =>
      const JsonEncoder.withIndent('  ').convert(json);

  // bat-style palette derived from the app ColorScheme: keys, strings,
  // numbers, literals (true/false/null) and punctuation each get a
  // distinct color. re_highlight's JSON grammar emits classes: attr,
  // string, number, literal, punctuation.
  static Map<String, TextStyle> _batTheme(ColorScheme scheme) {
    final base = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: scheme.onSurfaceVariant,
    );
    return {
      'attr': base.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
      'string': base.copyWith(color: scheme.secondary),
      'number': base.copyWith(color: scheme.tertiary),
      // re_highlight's keyword matcher may report the class as 'keyword'
      // instead of 'literal'; cover both so true/false/null highlight.
      'literal': base.copyWith(
        color: scheme.error,
        fontWeight: FontWeight.w600,
      ),
      'keyword': base.copyWith(
        color: scheme.error,
        fontWeight: FontWeight.w600,
      ),
      'punctuation': base.copyWith(color: scheme.onSurfaceVariant),
    };
  }

  TextSpan _highlight(String code, ColorScheme scheme) {
    final result = _highlighter.highlight(code: code, language: 'json');
    final renderer = TextSpanRenderer(
      TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: scheme.onSurfaceVariant,
      ),
      _batTheme(scheme),
    );
    result.render(renderer);
    return renderer.span ??
        TextSpan(
          text: code,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final span = _highlight(prettyJson(widget.data), scheme);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SelectableText.rich(span),
    );
  }
}
