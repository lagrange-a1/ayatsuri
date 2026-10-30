/// Country name -> proxy name matching for the interactive map page.
///
/// The Mihomo external controller never reports the country of a node. Nodes
/// in this project's configuration look like `🇭🇰 香港 | HKG 2` (flag + native
/// name + alpha-3 code), so regions are inferred from a proxy name.
///
/// Map IDs from `interactive_world_map` are mostly ISO alpha-2 codes and are
/// passed through `defaultMapIdResolver`, which turns e.g. `FR` into `X_FRA`,
/// so every entry here lists both forms in `patterns`.
library;

class CountryPattern {
  const CountryPattern({
    required this.alpha2,
    required this.alpha3,
    required this.flag,
    required this.name,
    required this.patterns,
  });

  /// ISO alpha-2 map ID (`HK`, `US`, `DE`, ...).
  final String alpha2;

  /// The code used in proxy names (`HKG`, `USA`, `DEU`, ...).
  final String alpha3;

  final String flag;
  final String name;
  final List<String> patterns;
}

const Map<String, CountryPattern> kCountries = {
  'HK': CountryPattern(
    alpha2: 'HK',
    alpha3: 'HKG',
    flag: '🇭🇰',
    name: '香港',
    patterns: ['🇭🇰', 'HK', 'HKG', '香港', 'Hong Kong'],
  ),
  'TW': CountryPattern(
    alpha2: 'TW',
    alpha3: 'TWN',
    flag: '🇹🇼',
    name: '台湾',
    patterns: ['🇹🇼', 'TW', 'TWN', '台湾', 'Taiwan'],
  ),
  'CN': CountryPattern(
    alpha2: 'CN',
    alpha3: 'CHN',
    flag: '🇨🇳',
    name: '中国',
    patterns: ['🇨🇳', 'CN', 'CHN', '中国', 'China'],
  ),
  'US': CountryPattern(
    alpha2: 'US',
    alpha3: 'USA',
    flag: '🇺🇸',
    name: '美国',
    patterns: ['🇺🇸', 'US', 'USA', '美国', 'United States', 'America'],
  ),
  'JP': CountryPattern(
    alpha2: 'JP',
    alpha3: 'JPN',
    flag: '🇯🇵',
    name: '日本',
    patterns: ['🇯🇵', 'JP', 'JPN', '日本', 'Japan'],
  ),
  'SG': CountryPattern(
    alpha2: 'SG',
    alpha3: 'SGP',
    flag: '🇸🇬',
    name: '新加坡',
    patterns: ['🇸🇬', 'SG', 'SGP', '新加坡', 'Singapore'],
  ),
  'KR': CountryPattern(
    alpha2: 'KR',
    alpha3: 'KOR',
    flag: '🇰🇷',
    name: '韩国',
    patterns: ['🇰🇷', 'KR', 'KOR', '韩国', 'Korea', 'South Korea'],
  ),
  'DE': CountryPattern(
    alpha2: 'DE',
    alpha3: 'DEU',
    flag: '🇩🇪',
    name: '德国',
    patterns: ['🇩🇪', 'DE', 'DEU', '德国', 'Germany'],
  ),
  'GB': CountryPattern(
    alpha2: 'GB',
    alpha3: 'GBR',
    flag: '🇬🇧',
    name: '英国',
    patterns: ['🇬🇧', 'GB', 'GBR', '英国', 'UK', 'United Kingdom'],
  ),
  'ES': CountryPattern(
    alpha2: 'ES',
    alpha3: 'ESP',
    flag: '🇪🇸',
    name: '西班牙',
    patterns: ['🇪🇸', 'ES', 'ESP', '西班牙', 'Spain'],
  ),
  'IT': CountryPattern(
    alpha2: 'IT',
    alpha3: 'ITA',
    flag: '🇮🇹',
    name: '意大利',
    patterns: ['🇮🇹', 'IT', 'ITA', '意大利', 'Italy'],
  ),
  'NL': CountryPattern(
    alpha2: 'NL',
    alpha3: 'NLD',
    flag: '🇳🇱',
    name: '荷兰',
    patterns: ['🇳🇱', 'NL', 'NLD', '荷兰', 'Netherlands'],
  ),
  'SE': CountryPattern(
    alpha2: 'SE',
    alpha3: 'SWE',
    flag: '🇸🇪',
    name: '瑞典',
    patterns: ['🇸🇪', 'SE', 'SWE', '瑞典', 'Sweden'],
  ),
  'RU': CountryPattern(
    alpha2: 'RU',
    alpha3: 'RUS',
    flag: '🇷🇺',
    name: '俄罗斯',
    patterns: ['🇷🇺', 'RU', 'RUS', '俄罗斯', 'Russia'],
  ),
  'FR': CountryPattern(
    alpha2: 'FR',
    alpha3: 'FRA',
    flag: '🇫🇷',
    name: '法国',
    patterns: ['🇫🇷', 'FR', 'FRA', '法国', 'France'],
  ),
  'BE': CountryPattern(
    alpha2: 'BE',
    alpha3: 'BEL',
    flag: '🇧🇪',
    name: '比利时',
    patterns: ['🇧🇪', 'BE', 'BEL', '比利时', 'Belgium'],
  ),
  'RO': CountryPattern(
    alpha2: 'RO',
    alpha3: 'ROU',
    flag: '🇷🇴',
    name: '罗马尼亚',
    patterns: ['🇷🇴', 'RO', 'ROU', '罗马尼亚', 'Romania'],
  ),
  'IR': CountryPattern(
    alpha2: 'IR',
    alpha3: 'IRN',
    flag: '🇮🇷',
    name: '伊朗',
    patterns: ['🇮🇷', 'IR', 'IRN', '伊朗', 'Iran'],
  ),
  'IE': CountryPattern(
    alpha2: 'IE',
    alpha3: 'IRE',
    flag: '🇮🇪',
    name: '爱尔兰',
    patterns: ['🇮🇪', 'IE', 'IRE', 'IRL', '爱尔兰', 'Ireland'],
  ),
  'IN': CountryPattern(
    alpha2: 'IN',
    alpha3: 'IND',
    flag: '🇮🇳',
    name: '印度',
    patterns: ['🇮🇳', 'IN', 'IND', '印度', 'India'],
  ),
  'PL': CountryPattern(
    alpha2: 'PL',
    alpha3: 'POL',
    flag: '🇵🇱',
    name: '波兰',
    patterns: ['🇵🇱', 'PL', 'POL', '波兰', 'Poland'],
  ),
  'CZ': CountryPattern(
    alpha2: 'CZ',
    alpha3: 'CZE',
    flag: '🇨🇿',
    name: '捷克',
    patterns: ['🇨🇿', 'CZ', 'CZE', '捷克', 'Czech'],
  ),
  'AT': CountryPattern(
    alpha2: 'AT',
    alpha3: 'AUT',
    flag: '🇦🇹',
    name: '奥地利',
    patterns: ['🇦🇹', 'AT', 'AUT', '奥地利', 'Austria'],
  ),
  'BG': CountryPattern(
    alpha2: 'BG',
    alpha3: 'BGR',
    flag: '🇧🇬',
    name: '保加利亚',
    patterns: ['🇧🇬', 'BG', 'BGR', '保加利亚', 'Bulgaria'],
  ),
  'EE': CountryPattern(
    alpha2: 'EE',
    alpha3: 'EST',
    flag: '🇪🇪',
    name: '爱沙尼亚',
    patterns: ['🇪🇪', 'EE', 'EST', '爱沙尼亚', 'Estonia'],
  ),
  'AU': CountryPattern(
    alpha2: 'AU',
    alpha3: 'AUS',
    flag: '🇦🇺',
    name: '澳大利亚',
    patterns: ['🇦🇺', 'AU', 'AUS', '澳大利亚', 'Australia'],
  ),
  'CA': CountryPattern(
    alpha2: 'CA',
    alpha3: 'CAN',
    flag: '🇨🇦',
    name: '加拿大',
    patterns: ['🇨🇦', 'CA', 'CAN', '加拿大', 'Canada'],
  ),
  'BR': CountryPattern(
    alpha2: 'BR',
    alpha3: 'BRA',
    flag: '🇧🇷',
    name: '巴西',
    patterns: ['🇧🇷', 'BR', 'BRA', '巴西', 'Brazil'],
  ),
  'VN': CountryPattern(
    alpha2: 'VN',
    alpha3: 'VNM',
    flag: '🇻🇳',
    name: '越南',
    patterns: ['🇻🇳', 'VN', 'VNM', '越南', 'Vietnam'],
  ),
  'AM': CountryPattern(
    alpha2: 'AM',
    alpha3: 'AM_24',
    flag: '🇦🇲',
    name: '亚美尼亚',
    patterns: ['🇦🇲', 'AM', 'AM24', 'AM_24', '亚美尼亚', 'Armenia'],
  ),
};

/// Map IDs returned by `interactive_world_map` are alpha-2 codes for most
/// countries; `defaultMapIdResolver` maps some to `X_<alpha-3>`. This collapses
/// them back to the alpha-2 used as the table key.
String? countryAlpha2FromMapId(String mapId) {
  String id = mapId.trim().toUpperCase();
  id = id.replaceAll(RegExp(r'^X_'), '');
  if (kCountries.containsKey(id)) return id;
  // alpha-3 form -> alpha-2 (e.g. `FRA` -> `FR`).
  for (final entry in kCountries.entries) {
    if (entry.value.alpha3.toUpperCase() == id) return entry.key;
  }
  return null;
}

/// Does a proxy name belong to this country?
bool isProxyInCountry(String proxyName, CountryPattern country) {
  final name = proxyName.toUpperCase();
  for (final pattern in country.patterns) {
    if (RegExp(r'(?<!\w)' + pattern.toUpperCase() + r'(?!\w)').hasMatch(name)) {
      return true;
    }
  }
  return false;
}

/// Collapse a proxy name (e.g. `🇭🇰 香港 | HKG 2`) to its alpha-2 map ID.
///
/// Two honest signals in these names: the alpha-3 code after the `|` separator
/// (that is the closest thing to a country label the controller gives you), and
/// the flag / native name itself. Substring matching a two-letter code is
/// deferred entirely, because it turns common token words like `COMPATIBLE` into
/// false positives (`COMP**AT**IBLE` -> `AT`).
String? nameToFrontAlpha2(String proxyName) {
  final name = proxyName.toUpperCase().trim();
  // Case 1: `🇭🇰 香港 | HKG 2` or `🇭🇰 香港 | HKG`.
  final sep = name.indexOf('|');
  if (sep >= 0) {
    final tail = name.substring(sep + 1);
    final match = RegExp(r'[A-Z]{3}').firstMatch(tail);
    if (match != null) {
      for (final entry in kCountries.entries) {
        if (entry.value.alpha3.toUpperCase() == match.group(0))
          return entry.key;
      }
    }
  }
  // Case 2: flag / native name / alpha-2 code, e.g. `🇭🇰`, `香港`, `HKG`.
  for (final entry in kCountries.entries) {
    for (final pattern in entry.value.patterns) {
      if (RegExp(
        r'(?<!\w)' + pattern.toUpperCase() + r'(?!\w)',
      ).hasMatch(name)) {
        return entry.key;
      }
    }
  }
  return null;
}
