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

  @override
  void initState() {
    super.initState();
    _api = MihomoAPI();
  }

  /// The globe page is the home tab; both pages auto-fetch controller state
  /// when they are first built (startup), so the visible page is fresh.
  List<Widget> get pages => [
    GlobeMapPage(api: _api, settingsController: widget.settingsController),
    MihomoInfo(api: _api),
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
  bool get _hasAnyData =>
      _version != null ||
      _configs != null ||
      _proxies != null ||
      _groups != null ||
      _rules != null ||
      _connections != null ||
      _traffic != null ||
      _memory != null ||
      _logs != null;

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
    final fetchers = <Future<void> Function()>[
      () async {
        final r = await retryTransient(() => _api.getVersion());
        if (r != null) _version = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getConfigs());
        if (r != null) _configs = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getProxies());
        if (r != null) _proxies = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getGroups());
        if (r != null) _groups = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getRules());
        if (r != null) _rules = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getConnections());
        if (r != null) _connections = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getTraffic());
        if (r != null) _traffic = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getMemory());
        if (r != null) _memory = r.data as Map<String, dynamic>;
      },
      () async {
        final r = await retryTransient(() => _api.getLogs());
        if (r != null) _logs = r.data as Map<String, dynamic>;
      },
    ];

    var pending = fetchers.length;
    for (final fetch in fetchers) {
      fetch()
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
                _section(l10n.sectionVersion, _version),
                _section(l10n.sectionConfigs, _configs),
                _section(l10n.sectionProxies, _proxies),
                _section(l10n.sectionGroups, _groups),
                _section(l10n.sectionRules, _rules),
                _section(l10n.sectionConnections, _connections),
                _section(l10n.sectionTraffic, _traffic),
                _section(l10n.sectionMemory, _memory),
                _section(l10n.sectionLogs, _logs),
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
