import 'package:flutter_test/flutter_test.dart';

import 'package:ayatsuri/proxies/country_map.dart';

void main() {
  test('map id -> alpha-2', () {
    expect(countryAlpha2FromMapId('DE'), 'DE');
    expect(countryAlpha2FromMapId('X_FRA'), 'FR');
    expect(countryAlpha2FromMapId('gb'), 'GB');
    expect(countryAlpha2FromMapId('DEU'), 'DE');
    expect(countryAlpha2FromMapId('XX_3'), null);
  });

  test('proxy names match their country', () {
    for (final e in kCountries.entries) {
      final name = e.value.name;
      expect(isProxyInCountry(name, e.value), isTrue);
      final country = kCountries[name] ?? e.value;
      expect(isProxyInCountry(name, country), isTrue);
    }
  });

  test('no false positives for random names', () {
    expect(isProxyInCountry('DIRECT', kCountries['US']!), isFalse);
    expect(isProxyInCountry('REJECT', kCountries['US']!), isFalse);
    expect(isProxyInCountry('COMPATIBLE', kCountries['HK']!), isFalse);
  });

  test('alpha-2 codes are recognized', () {
    expect(nameToFrontAlpha2('HK'), 'HK');
    expect(nameToFrontAlpha2('HK 2'), 'HK');
    expect(nameToFrontAlpha2('DE | Germany 3'), 'DE');
    // Real proxy-name formats: flag + native name + pipe + alpha-3.
    expect(nameToFrontAlpha2('🇭🇰 香港 | HKG 2'), 'HK');
    expect(nameToFrontAlpha2('🇯🇵 日本 | JPN'), 'JP');
    expect(nameToFrontAlpha2('🇺🇸 美国 | USA 1'), 'US');
    expect(nameToFrontAlpha2('香港 | HKG 1'), 'HK');
    // `|` absent: native names are still matched.
    expect(nameToFrontAlpha2('香港 2'), 'HK');
    expect(nameToFrontAlpha2('Germany 3'), 'DE');
    // Group tokens must not be falsely collapsed to alpha-2 codes.
    expect(nameToFrontAlpha2('COMPATIBLE'), null);
    expect(nameToFrontAlpha2('DIRECT'), null);
    expect(nameToFrontAlpha2('REJECT'), null);
    expect(nameToFrontAlpha2('MATCH'), null);
  });

  test('maps ids are recognized', () {
    for (final e in kCountries.entries) {
      expect(countryAlpha2FromMapId(e.value.alpha3), e.key);
    }
  });
}
