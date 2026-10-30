import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'endpoints.dart';
import 'views/proxy_map_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ayatsuri',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MihomoApp(),
    );
  }
}

/// Bottom-navigation shell wrapping the system info page and the proxy map page.
class MihomoApp extends StatefulWidget {
  const MihomoApp({super.key});

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

  /// The map page is the home tab; both pages auto-fetch controller state when
  /// they are first built (startup), so the visible page is always fresh.
  List<Widget> get pages => [ProxyMapPage(api: _api), MihomoInfo(api: _api)];

  List<BottomNavigationBarItem> get items => [
    BottomNavigationBarItem(
      icon: const Icon(Icons.public, size: 28),
      label: 'Map',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.info, size: 28),
      label: 'Info',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: items,
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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _api.getVersion().then(
          (r) => _version = r.data as Map<String, dynamic>,
        ),
        _api.getConfigs().then(
          (r) => _configs = r.data as Map<String, dynamic>,
        ),
        _api.getProxies().then(
          (r) => _proxies = r.data as Map<String, dynamic>,
        ),
        _api.getGroups().then((r) => _groups = r.data as Map<String, dynamic>),
        _api.getRules().then((r) => _rules = r.data as Map<String, dynamic>),
        _api.getConnections().then(
          (r) => _connections = r.data as Map<String, dynamic>,
        ),
        _api.getTraffic().then(
          (r) => _traffic = r.data as Map<String, dynamic>,
        ),
        _api.getMemory().then((r) => _memory = r.data as Map<String, dynamic>),
        _api.getLogs().then((r) => _logs = r.data as Map<String, dynamic>),
      ]);
    } on DioException catch (e) {
      _error = _formatDioError(e);
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ayatsuri · Mihomo Info'),
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
            tooltip: 'Fetch all',
          ),
        ],
      ),
      floatingActionButton: _version != null && !_loading
          ? FloatingActionButton(
              onPressed: _fetchEverything,
              tooltip: 'Fetch all',
              child: const Icon(Icons.refresh),
            )
          : null,
      body: _error != null
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
                    const Text(
                      'Request failed',
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
                      child: const Text('Retry'),
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
                  Text('No data yet'),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the button below to query the Mihomo core.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _fetchEverything,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Fetch All Data'),
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
                _section('Version', _version),
                _section('Configs', _configs),
                _section('Proxies', _proxies),
                _section('Groups', _groups),
                _section('Rules', _rules),
                _section('Connections', _connections),
                _section('Traffic', _traffic),
                _section('Memory', _memory),
                _section('Logs', _logs),
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
  static const _kIndent = '  ';

  String _pretty(Map<String, dynamic> json, {int depth = 0}) {
    final pad = _kIndent * depth;
    final buf = StringBuffer('{\n');
    final entries = json.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      buf.writeln('$pad  "${e.key}": ${_prettyValue(e.value, depth + 1)}');
      if (i < entries.length - 1) buf.write(',');
      buf.writeln();
    }
    buf.write('$pad}');
    return buf.toString();
  }

  String _prettyValue(dynamic v, int depth) {
    final pad = _kIndent * depth;
    if (v is Map<String, dynamic>) {
      if (v.isEmpty) return '{}';
      final buf = StringBuffer('{\n');
      final entries = v.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        buf.writeln('$pad  "${e.key}": ${_prettyValue(e.value, depth + 1)}');
        if (i < entries.length - 1) buf.write(',');
        buf.writeln();
      }
      buf.write('$pad}');
      return buf.toString();
    }
    if (v is List) {
      if (v.isEmpty) return '[]';
      final buf = StringBuffer('[\n');
      for (var i = 0; i < v.length; i++) {
        buf.writeln('$pad  ${_prettyValue(v[i], depth + 1)}');
        if (i < v.length - 1) buf.write(',');
        buf.writeln();
      }
      buf.write('$pad]');
      return buf.toString();
    }
    if (v is String) return jsonEncode(v);
    if (v is bool) return v.toString();
    if (v is num) return v.toString();
    if (v == null) return 'null';
    return jsonEncode(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final text = _pretty(widget.data);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
