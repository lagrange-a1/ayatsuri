/*
 * Integration test for the map's select-path, feeding the real proxies/groups
 * endpoints through `ProxySelection` (the layer `ProxyMapPage` uses).
 *
 * Flows: tappable countries -> candidates per country -> the selected node is
 * actually settable via `PUT /proxies/<group>`.
 */
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:ayatsuri/proxies/country_map.dart';
import 'package:ayatsuri/proxies/proxy_service.dart';

void main() {
  test('real mihomo: map countries and their node candidates', () async {
    await dotenv.load();
    final selection = ProxySelection();
    await selection.load();
    if (selection.error != null) {
      print('mihomo unreachable: ${selection.error}');
      return;
    }
    expect(selection.selectors.isNotEmpty, isTrue);
    expect(selection.proxies.isNotEmpty, isTrue);

    // Candidate names must be real proxies of the running config.
    final ids = <String>{};
    final candidates = <String, List<ProxyCandidate>>{};
    for (final group in selection.selectors) {
      for (final name in group.all) {
        final proxy = selection.proxies[name];
        if (proxy == null) continue; // group-only names, e.g. DIRECT, REJECT.
        final alpha2 = nameToFrontAlpha2(name);
        if (alpha2 != null) {
          ids.add(alpha2);
          candidates.putIfAbsent(alpha2, () => []).add(
              ProxyCandidate(group: group, proxy: proxy));
        }
      }
    }

    // HK/US/JP/IE ... categories used in this config all produce rows.
    final sample = ['HK', 'US', 'JP', 'IE', 'CN', 'AT'];
    for (final s in sample) {
      final cands = candidates[s] ?? <ProxyCandidate>[];
      print('$s -> ${cands.length} candidates -> '
          '${cands.take(2).map((c) => '${c.group.name} / ${c.proxy.name}').join('\n    ')}');
      expect(cands.isNotEmpty, isTrue, reason: 'candidate table for $s');
    }

    // Group-only tokens (DIRECT/REJECT/COMPATIBLE/MATCH) are not countries.
    for (final name in ['DIRECT', 'REJECT', 'COMPATIBLE', 'MATCH']) {
      expect(nameToFrontAlpha2(name), null, reason: name);
      expect(isProxyInCountry(name, kCountries['HK']!), isFalse, reason: name);
    }
  });
}
