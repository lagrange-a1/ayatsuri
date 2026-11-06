/*
 * Unit tests for the pure-Dart Mihomo info summarizers in
 * `lib/info/mihomo_info.dart`. Fixtures are small synthetic payloads
 * shaped like the live controller responses (no network required).
 */

import 'package:flutter_test/flutter_test.dart';

import 'package:ayatsuri/info/mihomo_info.dart';

void main() {
  group('helpers', () {
    test('sortedCounts is deterministic on ties', () {
      final sorted = sortedCounts({'b': 2, 'a': 2, 'c': 5});
      expect(sorted.map((e) => e.key), ['c', 'a', 'b']);
    });

    test('topEntries respects n and ordering', () {
      expect(topEntries({'x': 1, 'y': 9, 'z': 3}, 2).map((e) => e.key), [
        'y',
        'z',
      ]);
      expect(topEntries({'x': 1}, 5), hasLength(1));
    });

    test('formatBytes / formatRate', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatRate(2048), '2.0 KB/s');
    });

    test('parseJsonLines skips blanks and truncated lines', () {
      final lines = parseJsonLines('{"up":1}\n\n{"up":2}\n{"up":trunc\n');
      expect(lines, hasLength(2));
      expect(lines.last['up'], 2);
    });
  });

  group('version', () {
    test('parses live-shaped payload', () {
      final info = VersionInfo.fromJson({'meta': true, 'version': '1.19.33'});
      expect(info.version, '1.19.33');
      expect(info.meta, isTrue);
    });

    test('tolerates null', () {
      expect(VersionInfo.fromJson(null).version, '');
    });
  });

  group('configs', () {
    test('summarizes ports, mode and tun', () {
      final info = ConfigsInfo.fromJson({
        'port': 7892,
        'socks-port': 7891,
        'mixed-port': 7890,
        'redir-port': 0,
        'mode': 'rule',
        'log-level': 'info',
        'allow-lan': false,
        'ipv6': false,
        'sniffing': true,
        'tun': {
          'enable': true,
          'device': 'Mihomo',
          'stack': 'gVisor',
          'mtu': 1500,
        },
      });
      expect(info.mode, 'rule');
      expect(info.activePorts, {
        'port': 7892,
        'socks-port': 7891,
        'mixed-port': 7890,
      });
      expect(info.tunEnabled, isTrue);
      expect(info.tunDevice, 'Mihomo');
      expect(info.tunStack, 'gVisor');
      expect(info.tunMtu, 1500);
    });
  });

  group('proxies', () {
    Map<String, dynamic> fixture() => {
      'proxies': {
        'DIRECT': {
          'name': 'DIRECT',
          'type': 'Direct',
          'alive': true,
          'history': [],
        },
        'HK 1': {
          'name': 'HK 1',
          'type': 'Vless',
          'alive': true,
          'history': [
            {'delay': 120},
            {'delay': 200},
          ],
        },
        'US 1': {
          'name': 'US 1',
          'type': 'Vless',
          'alive': false,
          'history': [
            {'delay': 0},
          ],
        },
        'GLOBAL': {
          'name': 'GLOBAL',
          'type': 'Selector',
          'alive': true,
          'now': 'HK 1',
          'all': ['DIRECT', 'HK 1'],
          'history': [],
        },
      },
    };

    test('counts, alive split and type breakdown', () {
      final info = ProxiesInfo.fromJson(fixture());
      expect(info.total, 4);
      expect(info.aliveCount, 3);
      expect(info.deadCount, 1);
      expect(info.typeCounts, {'Direct': 1, 'Vless': 2, 'Selector': 1});
      expect(info.sortedTypes.first.key, 'Vless');
      expect(info.aliveNames, ['DIRECT', 'GLOBAL', 'HK 1']);
    });

    test('delay stats use last positive history delay', () {
      final info = ProxiesInfo.fromJson(fixture());
      expect(info.probedCount, 1);
      expect(info.minDelay, 200);
      expect(info.maxDelay, 200);
      expect(info.averageDelay, 200);
    });

    test('tolerates null and missing proxies', () {
      expect(ProxiesInfo.fromJson(null).total, 0);
      expect(ProxiesInfo.fromJson({}).total, 0);
    });
  });

  group('groups and now chains', () {
    Map<String, dynamic> fixture() => {
      'proxies': [
        {
          'name': 'leaf-group',
          'type': 'Selector',
          'alive': true,
          'now': 'HK 1',
          'all': ['HK 1', 'US 1'],
          'history': [],
        },
        {
          'name': 'top',
          'type': 'Selector',
          'alive': true,
          'now': 'leaf-group',
          'all': ['leaf-group'],
          'history': [],
        },
        {
          'name': 'auto',
          'type': 'URLTest',
          'alive': true,
          'now': 'US 1',
          'all': ['US 1'],
          'testUrl': 'https://example.com',
          'history': [
            {'delay': 88},
          ],
        },
      ],
    };

    test('type breakdown and entries', () {
      final info = GroupsInfo.fromJson(fixture());
      expect(info.total, 3);
      expect(info.typeCounts, {'Selector': 2, 'URLTest': 1});
      final auto = info.entries.firstWhere((e) => e.name == 'auto');
      expect(auto.testUrl, 'https://example.com');
      expect(auto.lastDelay, 88);
      expect(auto.allCount, 1);
    });

    test('chainFor follows group -> now -> leaf', () {
      final info = GroupsInfo.fromJson(fixture());
      expect(info.chainFor('top'), ['top', 'leaf-group', 'HK 1']);
      expect(info.chainFor('leaf-group'), ['leaf-group', 'HK 1']);
      expect(info.chainFor('missing'), ['missing']);
    });

    test('resolveNowChain is cycle-safe', () {
      final groups = {
        'a': const GroupEntry(name: 'a', type: 'Selector', now: 'b'),
        'b': const GroupEntry(name: 'b', type: 'Selector', now: 'a'),
      };
      expect(resolveNowChain('a', groups), ['a', 'b']);
    });

    test('chain stops at proxyNames leaf', () {
      final info = GroupsInfo.fromJson(fixture());
      expect(info.chainFor('top', proxyNames: {'leaf-group'}), [
        'top',
        'leaf-group',
      ]);
    });
  });

  group('rules', () {
    test('type/proxy breakdowns, hits and top rules', () {
      final info = RulesInfo.fromJson({
        'rules': [
          {
            'index': 0,
            'type': 'DomainSuffix',
            'payload': 'a.com',
            'proxy': 'DIRECT',
            'size': -1,
            'extra': {'disabled': false, 'hitCount': 5, 'missCount': 10},
          },
          {
            'index': 1,
            'type': 'DomainSuffix',
            'payload': 'b.com',
            'proxy': 'PROXY',
            'size': 42,
            'extra': {'disabled': true, 'hitCount': 9, 'missCount': 1},
          },
          {
            'index': 2,
            'type': 'IPCIDR',
            'payload': '10.0.0.0/8',
            'proxy': 'PROXY',
            'size': -1,
            'extra': {'disabled': false, 'hitCount': 0, 'missCount': 3},
          },
        ],
      });
      expect(info.total, 3);
      expect(info.typeCounts, {'DomainSuffix': 2, 'IPCIDR': 1});
      expect(info.proxyCounts, {'DIRECT': 1, 'PROXY': 2});
      expect(info.disabledCount, 1);
      expect(info.providerBackedCount, 1);
      expect(info.hitTotal, 14);
      expect(info.missTotal, 14);
      expect(info.hitRate, closeTo(0.5, 1e-9));
      expect(info.topHitRules.first.payload, 'b.com');
      expect(info.topTypes(1).first.key, 'DomainSuffix');
      expect(info.topProxies(1).first.key, 'PROXY');
    });
  });

  group('connections', () {
    test('network/inbound/rule breakdowns and top connections', () {
      final info = ConnectionsInfo.fromJson({
        'downloadTotal': 1000,
        'uploadTotal': 500,
        'memory': 12345,
        'connections': [
          {
            'id': '1',
            'metadata': {
              'network': 'tcp',
              'type': 'Tun',
              'inboundName': 'DEFAULT-TUN',
              'host': 'a.example.com',
            },
            'upload': 100,
            'download': 900,
            'rule': 'DomainSuffix',
            'rulePayload': 'example.com',
            'chains': ['leaf', 'group'],
          },
          {
            'id': '2',
            'metadata': {
              'network': 'udp',
              'type': 'Tun',
              'inboundName': 'DEFAULT-TUN',
              'host': 'b.example.com',
            },
            'upload': 10,
            'download': 20,
            'rule': 'Match',
            'chains': ['DIRECT'],
          },
        ],
      });
      expect(info.total, 2);
      expect(info.uploadTotal, 500);
      expect(info.downloadTotal, 1000);
      expect(info.memoryInuse, 12345);
      expect(info.networkCounts, {'tcp': 1, 'udp': 1});
      expect(info.inboundCounts, {'DEFAULT-TUN': 2});
      expect(info.ruleCounts, {'DomainSuffix': 1, 'Match': 1});
      expect(info.topConnections.first.id, '1');
      expect(info.topConnections.first.chainDepth, 2);
      expect(info.summedDownload, 920);
    });
  });

  group('traffic / memory streams', () {
    test('traffic summarizes latest tick and maxima', () {
      final info = TrafficInfo.fromStream([
        {'up': 10, 'down': 100, 'upTotal': 1000, 'downTotal': 2000},
        {'up': 30, 'down': 50, 'upTotal': 1030, 'downTotal': 2050},
      ]);
      expect(info.up, 30);
      expect(info.down, 50);
      expect(info.upTotal, 1030);
      expect(info.sampleCount, 2);
      expect(info.maxUp, 30);
      expect(info.maxDown, 100);
    });

    test('memory summarizes latest tick and maxima', () {
      final info = MemoryInfo.fromStream([
        {'inuse': 0, 'oslimit': 0},
        {'inuse': 140623872, 'oslimit': 0},
      ]);
      expect(info.inuse, 140623872);
      expect(info.maxInuse, 140623872);
      expect(info.sampleCount, 2);
    });

    test('empty streams degrade to zero', () {
      expect(TrafficInfo.fromStream(const []).sampleCount, 0);
      expect(MemoryInfo.fromStream(const []).inuse, 0);
    });
  });

  group('logs', () {
    test('type breakdown and latest lines', () {
      final info = LogsInfo.fromJsonLines([
        {'type': 'info', 'payload': 'hello'},
        {'type': 'warning', 'payload': 'slow'},
        {'type': 'info', 'payload': 'world'},
        {'type': 'error', 'payload': 'boom'},
      ]);
      expect(info.sampleCount, 4);
      expect(info.infoCount, 2);
      expect(info.warningCount, 1);
      expect(info.errorCount, 1);
      expect(info.latest.last.payload, 'boom');
    });
  });

  group('bundle', () {
    test('fromAll wires all nine summaries', () {
      final summary = MihomoInfoSummary.fromAll(
        version: {'version': '1.19.33', 'meta': true},
        configs: {'mode': 'rule'},
        proxies: {'proxies': {}},
        group: {'proxies': []},
        rules: {'rules': []},
        connections: {'connections': []},
        traffic: {'up': 1, 'down': 2, 'upTotal': 3, 'downTotal': 4},
        memory: {'inuse': 5, 'oslimit': 0},
        logs: {'type': 'info', 'payload': 'x'},
      );
      expect(summary.version.version, '1.19.33');
      expect(summary.configs.mode, 'rule');
      expect(summary.traffic.down, 2);
      expect(summary.memory.inuse, 5);
      expect(summary.logs.sampleCount, 1);
    });
  });
}
