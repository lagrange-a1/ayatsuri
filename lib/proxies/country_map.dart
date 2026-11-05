/// Country name -> proxy name matching for the globe page.
///
/// The Mihomo external controller never reports the country of a node. Nodes
/// in this project's configuration look like `🇭🇰 香港 | HKG 2` (flag + native
/// name + alpha-3 code), so regions are inferred from a proxy name.
///
/// Table coverage is generated from the bundled Natural Earth 110m GeoJSON
/// (`assets/globe/countries.geojson`, 177 features): every tappable globe
/// polygon has an entry. The ~30 entries with Chinese names / provider-style
/// tokens (e.g. `AM_24`) are hand-tuned overlays on top of the generated
/// alpha2/alpha3/English pattern.
library;

class CountryPattern {
  const CountryPattern({
    required this.alpha2,
    required this.alpha3,
    required this.flag,
    required this.name,
    required this.patterns,
  });

  /// ISO alpha-2 map ID (`HK`, `US`, `DE`, ...). For the globe this is the
  /// `ISO_A2` of the tapped polygon (see [alpha2ForGlobeFeature]).
  final String alpha2;

  /// The code used in proxy names (`HKG`, `USA`, `DEU`, ...).
  final String alpha3;

  final String flag;
  final String name;
  final List<String> patterns;
}

const Map<String, CountryPattern> kCountries = {
  'AE': CountryPattern(
    alpha2: 'AE',
    alpha3: 'ARE',
    flag: '🇦🇪',
    name: 'United Arab Emirates',
    patterns: ['🇦🇪', 'AE', 'ARE', 'United Arab Emirates'],
  ),
  'AF': CountryPattern(
    alpha2: 'AF',
    alpha3: 'AFG',
    flag: '🇦🇫',
    name: 'Afghanistan',
    patterns: ['🇦🇫', 'AF', 'AFG', 'Afghanistan'],
  ),
  'AL': CountryPattern(
    alpha2: 'AL',
    alpha3: 'ALB',
    flag: '🇦🇱',
    name: 'Albania',
    patterns: ['🇦🇱', 'AL', 'ALB', 'Albania'],
  ),
  'AM': CountryPattern(
    alpha2: 'AM',
    alpha3: 'ARM',
    flag: '🇦🇲',
    name: '亚美尼亚',
    patterns: ['🇦🇲', 'AM', 'AM24', 'AM_24', '亚美尼亚', 'Armenia'],
  ),
  'AO': CountryPattern(
    alpha2: 'AO',
    alpha3: 'AGO',
    flag: '🇦🇴',
    name: 'Angola',
    patterns: ['🇦🇴', 'AO', 'AGO', 'Angola'],
  ),
  'AQ': CountryPattern(
    alpha2: 'AQ',
    alpha3: 'ATA',
    flag: '🇦🇶',
    name: 'Antarctica',
    patterns: ['🇦🇶', 'AQ', 'ATA', 'Antarctica'],
  ),
  'AR': CountryPattern(
    alpha2: 'AR',
    alpha3: 'ARG',
    flag: '🇦🇷',
    name: 'Argentina',
    patterns: ['🇦🇷', 'AR', 'ARG', 'Argentina'],
  ),
  'AT': CountryPattern(
    alpha2: 'AT',
    alpha3: 'AUT',
    flag: '🇦🇹',
    name: '奥地利',
    patterns: ['🇦🇹', 'AT', 'AUT', '奥地利', 'Austria'],
  ),
  'AU': CountryPattern(
    alpha2: 'AU',
    alpha3: 'AUS',
    flag: '🇦🇺',
    name: '澳大利亚',
    patterns: ['🇦🇺', 'AU', 'AUS', '澳大利亚', 'Australia'],
  ),
  'AZ': CountryPattern(
    alpha2: 'AZ',
    alpha3: 'AZE',
    flag: '🇦🇿',
    name: 'Azerbaijan',
    patterns: ['🇦🇿', 'AZ', 'AZE', 'Azerbaijan'],
  ),
  'BA': CountryPattern(
    alpha2: 'BA',
    alpha3: 'BIH',
    flag: '🇧🇦',
    name: 'Bosnia and Herzegovina',
    patterns: ['🇧🇦', 'BA', 'BIH', 'Bosnia and Herzegovina'],
  ),
  'BD': CountryPattern(
    alpha2: 'BD',
    alpha3: 'BGD',
    flag: '🇧🇩',
    name: 'Bangladesh',
    patterns: ['🇧🇩', 'BD', 'BGD', 'Bangladesh'],
  ),
  'BE': CountryPattern(
    alpha2: 'BE',
    alpha3: 'BEL',
    flag: '🇧🇪',
    name: '比利时',
    patterns: ['🇧🇪', 'BE', 'BEL', '比利时', 'Belgium'],
  ),
  'BF': CountryPattern(
    alpha2: 'BF',
    alpha3: 'BFA',
    flag: '🇧🇫',
    name: 'Burkina Faso',
    patterns: ['🇧🇫', 'BF', 'BFA', 'Burkina Faso'],
  ),
  'BG': CountryPattern(
    alpha2: 'BG',
    alpha3: 'BGR',
    flag: '🇧🇬',
    name: '保加利亚',
    patterns: ['🇧🇬', 'BG', 'BGR', '保加利亚', 'Bulgaria'],
  ),
  'BI': CountryPattern(
    alpha2: 'BI',
    alpha3: 'BDI',
    flag: '🇧🇮',
    name: 'Burundi',
    patterns: ['🇧🇮', 'BI', 'BDI', 'Burundi'],
  ),
  'BJ': CountryPattern(
    alpha2: 'BJ',
    alpha3: 'BEN',
    flag: '🇧🇯',
    name: 'Benin',
    patterns: ['🇧🇯', 'BJ', 'BEN', 'Benin'],
  ),
  'BN': CountryPattern(
    alpha2: 'BN',
    alpha3: 'BRN',
    flag: '🇧🇳',
    name: 'Brunei',
    patterns: ['🇧🇳', 'BN', 'BRN', 'Brunei'],
  ),
  'BO': CountryPattern(
    alpha2: 'BO',
    alpha3: 'BOL',
    flag: '🇧🇴',
    name: 'Bolivia',
    patterns: ['🇧🇴', 'BO', 'BOL', 'Bolivia'],
  ),
  'BR': CountryPattern(
    alpha2: 'BR',
    alpha3: 'BRA',
    flag: '🇧🇷',
    name: '巴西',
    patterns: ['🇧🇷', 'BR', 'BRA', '巴西', 'Brazil'],
  ),
  'BS': CountryPattern(
    alpha2: 'BS',
    alpha3: 'BHS',
    flag: '🇧🇸',
    name: 'The Bahamas',
    patterns: ['🇧🇸', 'BS', 'BHS', 'The Bahamas'],
  ),
  'BT': CountryPattern(
    alpha2: 'BT',
    alpha3: 'BTN',
    flag: '🇧🇹',
    name: 'Bhutan',
    patterns: ['🇧🇹', 'BT', 'BTN', 'Bhutan'],
  ),
  'BW': CountryPattern(
    alpha2: 'BW',
    alpha3: 'BWA',
    flag: '🇧🇼',
    name: 'Botswana',
    patterns: ['🇧🇼', 'BW', 'BWA', 'Botswana'],
  ),
  'BY': CountryPattern(
    alpha2: 'BY',
    alpha3: 'BLR',
    flag: '🇧🇾',
    name: 'Belarus',
    patterns: ['🇧🇾', 'BY', 'BLR', 'Belarus'],
  ),
  'BZ': CountryPattern(
    alpha2: 'BZ',
    alpha3: 'BLZ',
    flag: '🇧🇿',
    name: 'Belize',
    patterns: ['🇧🇿', 'BZ', 'BLZ', 'Belize'],
  ),
  'CA': CountryPattern(
    alpha2: 'CA',
    alpha3: 'CAN',
    flag: '🇨🇦',
    name: '加拿大',
    patterns: ['🇨🇦', 'CA', 'CAN', '加拿大', 'Canada'],
  ),
  'CD': CountryPattern(
    alpha2: 'CD',
    alpha3: 'COD',
    flag: '🇨🇩',
    name: 'Democratic Republic of the Congo',
    patterns: ['🇨🇩', 'CD', 'COD', 'Democratic Republic of the Congo'],
  ),
  'CF': CountryPattern(
    alpha2: 'CF',
    alpha3: 'CAF',
    flag: '🇨🇫',
    name: 'Central African Republic',
    patterns: ['🇨🇫', 'CF', 'CAF', 'Central African Republic'],
  ),
  'CG': CountryPattern(
    alpha2: 'CG',
    alpha3: 'COG',
    flag: '🇨🇬',
    name: 'Republic of the Congo',
    patterns: ['🇨🇬', 'CG', 'COG', 'Republic of the Congo'],
  ),
  'CH': CountryPattern(
    alpha2: 'CH',
    alpha3: 'CHE',
    flag: '🇨🇭',
    name: 'Switzerland',
    patterns: ['🇨🇭', 'CH', 'CHE', 'Switzerland'],
  ),
  'CI': CountryPattern(
    alpha2: 'CI',
    alpha3: 'CIV',
    flag: '🇨🇮',
    name: 'Ivory Coast',
    patterns: ['🇨🇮', 'CI', 'CIV', 'Ivory Coast'],
  ),
  'CL': CountryPattern(
    alpha2: 'CL',
    alpha3: 'CHL',
    flag: '🇨🇱',
    name: 'Chile',
    patterns: ['🇨🇱', 'CL', 'CHL', 'Chile'],
  ),
  'CM': CountryPattern(
    alpha2: 'CM',
    alpha3: 'CMR',
    flag: '🇨🇲',
    name: 'Cameroon',
    patterns: ['🇨🇲', 'CM', 'CMR', 'Cameroon'],
  ),
  'CN': CountryPattern(
    alpha2: 'CN',
    alpha3: 'CHN',
    flag: '🇨🇳',
    name: '中国',
    patterns: ['🇨🇳', 'CN', 'CHN', '中国', 'China'],
  ),
  'CO': CountryPattern(
    alpha2: 'CO',
    alpha3: 'COL',
    flag: '🇨🇴',
    name: 'Colombia',
    patterns: ['🇨🇴', 'CO', 'COL', 'Colombia'],
  ),
  'CR': CountryPattern(
    alpha2: 'CR',
    alpha3: 'CRI',
    flag: '🇨🇷',
    name: 'Costa Rica',
    patterns: ['🇨🇷', 'CR', 'CRI', 'Costa Rica'],
  ),
  'CU': CountryPattern(
    alpha2: 'CU',
    alpha3: 'CUB',
    flag: '🇨🇺',
    name: 'Cuba',
    patterns: ['🇨🇺', 'CU', 'CUB', 'Cuba'],
  ),
  'CY': CountryPattern(
    alpha2: 'CY',
    alpha3: 'CYP',
    flag: '🇨🇾',
    name: 'Cyprus',
    patterns: ['🇨🇾', 'CY', 'CYP', 'Cyprus'],
  ),
  'CZ': CountryPattern(
    alpha2: 'CZ',
    alpha3: 'CZE',
    flag: '🇨🇿',
    name: '捷克',
    patterns: ['🇨🇿', 'CZ', 'CZE', '捷克', 'Czech'],
  ),
  'DE': CountryPattern(
    alpha2: 'DE',
    alpha3: 'DEU',
    flag: '🇩🇪',
    name: '德国',
    patterns: ['🇩🇪', 'DE', 'DEU', '德国', 'Germany'],
  ),
  'DJ': CountryPattern(
    alpha2: 'DJ',
    alpha3: 'DJI',
    flag: '🇩🇯',
    name: 'Djibouti',
    patterns: ['🇩🇯', 'DJ', 'DJI', 'Djibouti'],
  ),
  'DK': CountryPattern(
    alpha2: 'DK',
    alpha3: 'DNK',
    flag: '🇩🇰',
    name: 'Denmark',
    patterns: ['🇩🇰', 'DK', 'DNK', 'Denmark'],
  ),
  'DO': CountryPattern(
    alpha2: 'DO',
    alpha3: 'DOM',
    flag: '🇩🇴',
    name: 'Dominican Republic',
    patterns: ['🇩🇴', 'DO', 'DOM', 'Dominican Republic'],
  ),
  'DZ': CountryPattern(
    alpha2: 'DZ',
    alpha3: 'DZA',
    flag: '🇩🇿',
    name: 'Algeria',
    patterns: ['🇩🇿', 'DZ', 'DZA', 'Algeria'],
  ),
  'EC': CountryPattern(
    alpha2: 'EC',
    alpha3: 'ECU',
    flag: '🇪🇨',
    name: 'Ecuador',
    patterns: ['🇪🇨', 'EC', 'ECU', 'Ecuador'],
  ),
  'EE': CountryPattern(
    alpha2: 'EE',
    alpha3: 'EST',
    flag: '🇪🇪',
    name: '爱沙尼亚',
    patterns: ['🇪🇪', 'EE', 'EST', '爱沙尼亚', 'Estonia'],
  ),
  'EG': CountryPattern(
    alpha2: 'EG',
    alpha3: 'EGY',
    flag: '🇪🇬',
    name: 'Egypt',
    patterns: ['🇪🇬', 'EG', 'EGY', 'Egypt'],
  ),
  'EH': CountryPattern(
    alpha2: 'EH',
    alpha3: 'ESH',
    flag: '🇪🇭',
    name: 'Western Sahara',
    patterns: ['🇪🇭', 'EH', 'ESH', 'Western Sahara'],
  ),
  'ER': CountryPattern(
    alpha2: 'ER',
    alpha3: 'ERI',
    flag: '🇪🇷',
    name: 'Eritrea',
    patterns: ['🇪🇷', 'ER', 'ERI', 'Eritrea'],
  ),
  'ES': CountryPattern(
    alpha2: 'ES',
    alpha3: 'ESP',
    flag: '🇪🇸',
    name: '西班牙',
    patterns: ['🇪🇸', 'ES', 'ESP', '西班牙', 'Spain'],
  ),
  'ET': CountryPattern(
    alpha2: 'ET',
    alpha3: 'ETH',
    flag: '🇪🇹',
    name: 'Ethiopia',
    patterns: ['🇪🇹', 'ET', 'ETH', 'Ethiopia'],
  ),
  'FI': CountryPattern(
    alpha2: 'FI',
    alpha3: 'FIN',
    flag: '🇫🇮',
    name: 'Finland',
    patterns: ['🇫🇮', 'FI', 'FIN', 'Finland'],
  ),
  'FJ': CountryPattern(
    alpha2: 'FJ',
    alpha3: 'FJI',
    flag: '🇫🇯',
    name: 'Fiji',
    patterns: ['🇫🇯', 'FJ', 'FJI', 'Fiji'],
  ),
  'FK': CountryPattern(
    alpha2: 'FK',
    alpha3: 'FLK',
    flag: '🇫🇰',
    name: 'Falkland Islands',
    patterns: ['🇫🇰', 'FK', 'FLK', 'Falkland Islands'],
  ),
  'FR': CountryPattern(
    alpha2: 'FR',
    alpha3: 'FRA',
    flag: '🇫🇷',
    name: '法国',
    patterns: ['🇫🇷', 'FR', 'FRA', '法国', 'France'],
  ),
  'GA': CountryPattern(
    alpha2: 'GA',
    alpha3: 'GAB',
    flag: '🇬🇦',
    name: 'Gabon',
    patterns: ['🇬🇦', 'GA', 'GAB', 'Gabon'],
  ),
  'GB': CountryPattern(
    alpha2: 'GB',
    alpha3: 'GBR',
    flag: '🇬🇧',
    name: '英国',
    patterns: ['🇬🇧', 'GB', 'GBR', '英国', 'UK', 'United Kingdom'],
  ),
  'GE': CountryPattern(
    alpha2: 'GE',
    alpha3: 'GEO',
    flag: '🇬🇪',
    name: 'Georgia',
    patterns: ['🇬🇪', 'GE', 'GEO', 'Georgia'],
  ),
  'GH': CountryPattern(
    alpha2: 'GH',
    alpha3: 'GHA',
    flag: '🇬🇭',
    name: 'Ghana',
    patterns: ['🇬🇭', 'GH', 'GHA', 'Ghana'],
  ),
  'GL': CountryPattern(
    alpha2: 'GL',
    alpha3: 'GRL',
    flag: '🇬🇱',
    name: 'Greenland',
    patterns: ['🇬🇱', 'GL', 'GRL', 'Greenland'],
  ),
  'GM': CountryPattern(
    alpha2: 'GM',
    alpha3: 'GMB',
    flag: '🇬🇲',
    name: 'Gambia',
    patterns: ['🇬🇲', 'GM', 'GMB', 'Gambia'],
  ),
  'GN': CountryPattern(
    alpha2: 'GN',
    alpha3: 'GIN',
    flag: '🇬🇳',
    name: 'Guinea',
    patterns: ['🇬🇳', 'GN', 'GIN', 'Guinea'],
  ),
  'GQ': CountryPattern(
    alpha2: 'GQ',
    alpha3: 'GNQ',
    flag: '🇬🇶',
    name: 'Equatorial Guinea',
    patterns: ['🇬🇶', 'GQ', 'GNQ', 'Equatorial Guinea'],
  ),
  'GR': CountryPattern(
    alpha2: 'GR',
    alpha3: 'GRC',
    flag: '🇬🇷',
    name: 'Greece',
    patterns: ['🇬🇷', 'GR', 'GRC', 'Greece'],
  ),
  'GT': CountryPattern(
    alpha2: 'GT',
    alpha3: 'GTM',
    flag: '🇬🇹',
    name: 'Guatemala',
    patterns: ['🇬🇹', 'GT', 'GTM', 'Guatemala'],
  ),
  'GW': CountryPattern(
    alpha2: 'GW',
    alpha3: 'GNB',
    flag: '🇬🇼',
    name: 'Guinea-Bissau',
    patterns: ['🇬🇼', 'GW', 'GNB', 'Guinea-Bissau'],
  ),
  'GY': CountryPattern(
    alpha2: 'GY',
    alpha3: 'GUY',
    flag: '🇬🇾',
    name: 'Guyana',
    patterns: ['🇬🇾', 'GY', 'GUY', 'Guyana'],
  ),
  'HK': CountryPattern(
    alpha2: 'HK',
    alpha3: 'HKG',
    flag: '🇭🇰',
    name: '香港',
    patterns: ['🇭🇰', 'HK', 'HKG', '香港', 'Hong Kong'],
  ),
  'HN': CountryPattern(
    alpha2: 'HN',
    alpha3: 'HND',
    flag: '🇭🇳',
    name: 'Honduras',
    patterns: ['🇭🇳', 'HN', 'HND', 'Honduras'],
  ),
  'HR': CountryPattern(
    alpha2: 'HR',
    alpha3: 'HRV',
    flag: '🇭🇷',
    name: 'Croatia',
    patterns: ['🇭🇷', 'HR', 'HRV', 'Croatia'],
  ),
  'HT': CountryPattern(
    alpha2: 'HT',
    alpha3: 'HTI',
    flag: '🇭🇹',
    name: 'Haiti',
    patterns: ['🇭🇹', 'HT', 'HTI', 'Haiti'],
  ),
  'HU': CountryPattern(
    alpha2: 'HU',
    alpha3: 'HUN',
    flag: '🇭🇺',
    name: 'Hungary',
    patterns: ['🇭🇺', 'HU', 'HUN', 'Hungary'],
  ),
  'ID': CountryPattern(
    alpha2: 'ID',
    alpha3: 'IDN',
    flag: '🇮🇩',
    name: 'Indonesia',
    patterns: ['🇮🇩', 'ID', 'IDN', 'Indonesia'],
  ),
  'IE': CountryPattern(
    alpha2: 'IE',
    alpha3: 'IRL',
    flag: '🇮🇪',
    name: '爱尔兰',
    patterns: ['🇮🇪', 'IE', 'IRE', 'IRL', '爱尔兰', 'Ireland'],
  ),
  'IL': CountryPattern(
    alpha2: 'IL',
    alpha3: 'ISR',
    flag: '🇮🇱',
    name: 'Israel',
    patterns: ['🇮🇱', 'IL', 'ISR', 'Israel'],
  ),
  'IN': CountryPattern(
    alpha2: 'IN',
    alpha3: 'IND',
    flag: '🇮🇳',
    name: '印度',
    patterns: ['🇮🇳', 'IN', 'IND', '印度', 'India'],
  ),
  'IQ': CountryPattern(
    alpha2: 'IQ',
    alpha3: 'IRQ',
    flag: '🇮🇶',
    name: 'Iraq',
    patterns: ['🇮🇶', 'IQ', 'IRQ', 'Iraq'],
  ),
  'IR': CountryPattern(
    alpha2: 'IR',
    alpha3: 'IRN',
    flag: '🇮🇷',
    name: '伊朗',
    patterns: ['🇮🇷', 'IR', 'IRN', '伊朗', 'Iran'],
  ),
  'IS': CountryPattern(
    alpha2: 'IS',
    alpha3: 'ISL',
    flag: '🇮🇸',
    name: 'Iceland',
    patterns: ['🇮🇸', 'IS', 'ISL', 'Iceland'],
  ),
  'IT': CountryPattern(
    alpha2: 'IT',
    alpha3: 'ITA',
    flag: '🇮🇹',
    name: '意大利',
    patterns: ['🇮🇹', 'IT', 'ITA', '意大利', 'Italy'],
  ),
  'JM': CountryPattern(
    alpha2: 'JM',
    alpha3: 'JAM',
    flag: '🇯🇲',
    name: 'Jamaica',
    patterns: ['🇯🇲', 'JM', 'JAM', 'Jamaica'],
  ),
  'JO': CountryPattern(
    alpha2: 'JO',
    alpha3: 'JOR',
    flag: '🇯🇴',
    name: 'Jordan',
    patterns: ['🇯🇴', 'JO', 'JOR', 'Jordan'],
  ),
  'JP': CountryPattern(
    alpha2: 'JP',
    alpha3: 'JPN',
    flag: '🇯🇵',
    name: '日本',
    patterns: ['🇯🇵', 'JP', 'JPN', '日本', 'Japan'],
  ),
  'KE': CountryPattern(
    alpha2: 'KE',
    alpha3: 'KEN',
    flag: '🇰🇪',
    name: 'Kenya',
    patterns: ['🇰🇪', 'KE', 'KEN', 'Kenya'],
  ),
  'KG': CountryPattern(
    alpha2: 'KG',
    alpha3: 'KGZ',
    flag: '🇰🇬',
    name: 'Kyrgyzstan',
    patterns: ['🇰🇬', 'KG', 'KGZ', 'Kyrgyzstan'],
  ),
  'KH': CountryPattern(
    alpha2: 'KH',
    alpha3: 'KHM',
    flag: '🇰🇭',
    name: 'Cambodia',
    patterns: ['🇰🇭', 'KH', 'KHM', 'Cambodia'],
  ),
  'KP': CountryPattern(
    alpha2: 'KP',
    alpha3: 'PRK',
    flag: '🇰🇵',
    name: 'North Korea',
    patterns: ['🇰🇵', 'KP', 'PRK', 'North Korea'],
  ),
  'KR': CountryPattern(
    alpha2: 'KR',
    alpha3: 'KOR',
    flag: '🇰🇷',
    name: '韩国',
    patterns: ['🇰🇷', 'KR', 'KOR', '韩国', 'Korea', 'South Korea'],
  ),
  'KW': CountryPattern(
    alpha2: 'KW',
    alpha3: 'KWT',
    flag: '🇰🇼',
    name: 'Kuwait',
    patterns: ['🇰🇼', 'KW', 'KWT', 'Kuwait'],
  ),
  'KZ': CountryPattern(
    alpha2: 'KZ',
    alpha3: 'KAZ',
    flag: '🇰🇿',
    name: 'Kazakhstan',
    patterns: ['🇰🇿', 'KZ', 'KAZ', 'Kazakhstan'],
  ),
  'LA': CountryPattern(
    alpha2: 'LA',
    alpha3: 'LAO',
    flag: '🇱🇦',
    name: 'Laos',
    patterns: ['🇱🇦', 'LA', 'LAO', 'Laos'],
  ),
  'LB': CountryPattern(
    alpha2: 'LB',
    alpha3: 'LBN',
    flag: '🇱🇧',
    name: 'Lebanon',
    patterns: ['🇱🇧', 'LB', 'LBN', 'Lebanon'],
  ),
  'LK': CountryPattern(
    alpha2: 'LK',
    alpha3: 'LKA',
    flag: '🇱🇰',
    name: 'Sri Lanka',
    patterns: ['🇱🇰', 'LK', 'LKA', 'Sri Lanka'],
  ),
  'LR': CountryPattern(
    alpha2: 'LR',
    alpha3: 'LBR',
    flag: '🇱🇷',
    name: 'Liberia',
    patterns: ['🇱🇷', 'LR', 'LBR', 'Liberia'],
  ),
  'LS': CountryPattern(
    alpha2: 'LS',
    alpha3: 'LSO',
    flag: '🇱🇸',
    name: 'Lesotho',
    patterns: ['🇱🇸', 'LS', 'LSO', 'Lesotho'],
  ),
  'LT': CountryPattern(
    alpha2: 'LT',
    alpha3: 'LTU',
    flag: '🇱🇹',
    name: 'Lithuania',
    patterns: ['🇱🇹', 'LT', 'LTU', 'Lithuania'],
  ),
  'LU': CountryPattern(
    alpha2: 'LU',
    alpha3: 'LUX',
    flag: '🇱🇺',
    name: 'Luxembourg',
    patterns: ['🇱🇺', 'LU', 'LUX', 'Luxembourg'],
  ),
  'LV': CountryPattern(
    alpha2: 'LV',
    alpha3: 'LVA',
    flag: '🇱🇻',
    name: 'Latvia',
    patterns: ['🇱🇻', 'LV', 'LVA', 'Latvia'],
  ),
  'LY': CountryPattern(
    alpha2: 'LY',
    alpha3: 'LBY',
    flag: '🇱🇾',
    name: 'Libya',
    patterns: ['🇱🇾', 'LY', 'LBY', 'Libya'],
  ),
  'MA': CountryPattern(
    alpha2: 'MA',
    alpha3: 'MAR',
    flag: '🇲🇦',
    name: 'Morocco',
    patterns: ['🇲🇦', 'MA', 'MAR', 'Morocco'],
  ),
  'MD': CountryPattern(
    alpha2: 'MD',
    alpha3: 'MDA',
    flag: '🇲🇩',
    name: 'Moldova',
    patterns: ['🇲🇩', 'MD', 'MDA', 'Moldova'],
  ),
  'ME': CountryPattern(
    alpha2: 'ME',
    alpha3: 'MNE',
    flag: '🇲🇪',
    name: 'Montenegro',
    patterns: ['🇲🇪', 'ME', 'MNE', 'Montenegro'],
  ),
  'MG': CountryPattern(
    alpha2: 'MG',
    alpha3: 'MDG',
    flag: '🇲🇬',
    name: 'Madagascar',
    patterns: ['🇲🇬', 'MG', 'MDG', 'Madagascar'],
  ),
  'MK': CountryPattern(
    alpha2: 'MK',
    alpha3: 'MKD',
    flag: '🇲🇰',
    name: 'Macedonia',
    patterns: ['🇲🇰', 'MK', 'MKD', 'Macedonia'],
  ),
  'ML': CountryPattern(
    alpha2: 'ML',
    alpha3: 'MLI',
    flag: '🇲🇱',
    name: 'Mali',
    patterns: ['🇲🇱', 'ML', 'MLI', 'Mali'],
  ),
  'MM': CountryPattern(
    alpha2: 'MM',
    alpha3: 'MMR',
    flag: '🇲🇲',
    name: 'Myanmar',
    patterns: ['🇲🇲', 'MM', 'MMR', 'Myanmar'],
  ),
  'MN': CountryPattern(
    alpha2: 'MN',
    alpha3: 'MNG',
    flag: '🇲🇳',
    name: 'Mongolia',
    patterns: ['🇲🇳', 'MN', 'MNG', 'Mongolia'],
  ),
  'MR': CountryPattern(
    alpha2: 'MR',
    alpha3: 'MRT',
    flag: '🇲🇷',
    name: 'Mauritania',
    patterns: ['🇲🇷', 'MR', 'MRT', 'Mauritania'],
  ),
  'MW': CountryPattern(
    alpha2: 'MW',
    alpha3: 'MWI',
    flag: '🇲🇼',
    name: 'Malawi',
    patterns: ['🇲🇼', 'MW', 'MWI', 'Malawi'],
  ),
  'MX': CountryPattern(
    alpha2: 'MX',
    alpha3: 'MEX',
    flag: '🇲🇽',
    name: 'Mexico',
    patterns: ['🇲🇽', 'MX', 'MEX', 'Mexico'],
  ),
  'MY': CountryPattern(
    alpha2: 'MY',
    alpha3: 'MYS',
    flag: '🇲🇾',
    name: 'Malaysia',
    patterns: ['🇲🇾', 'MY', 'MYS', 'Malaysia'],
  ),
  'MZ': CountryPattern(
    alpha2: 'MZ',
    alpha3: 'MOZ',
    flag: '🇲🇿',
    name: 'Mozambique',
    patterns: ['🇲🇿', 'MZ', 'MOZ', 'Mozambique'],
  ),
  'NA': CountryPattern(
    alpha2: 'NA',
    alpha3: 'NAM',
    flag: '🇳🇦',
    name: 'Namibia',
    patterns: ['🇳🇦', 'NA', 'NAM', 'Namibia'],
  ),
  'NC': CountryPattern(
    alpha2: 'NC',
    alpha3: 'NCL',
    flag: '🇳🇨',
    name: 'New Caledonia',
    patterns: ['🇳🇨', 'NC', 'NCL', 'New Caledonia'],
  ),
  'NE': CountryPattern(
    alpha2: 'NE',
    alpha3: 'NER',
    flag: '🇳🇪',
    name: 'Niger',
    patterns: ['🇳🇪', 'NE', 'NER', 'Niger'],
  ),
  'NG': CountryPattern(
    alpha2: 'NG',
    alpha3: 'NGA',
    flag: '🇳🇬',
    name: 'Nigeria',
    patterns: ['🇳🇬', 'NG', 'NGA', 'Nigeria'],
  ),
  'NI': CountryPattern(
    alpha2: 'NI',
    alpha3: 'NIC',
    flag: '🇳🇮',
    name: 'Nicaragua',
    patterns: ['🇳🇮', 'NI', 'NIC', 'Nicaragua'],
  ),
  'NL': CountryPattern(
    alpha2: 'NL',
    alpha3: 'NLD',
    flag: '🇳🇱',
    name: '荷兰',
    patterns: ['🇳🇱', 'NL', 'NLD', '荷兰', 'Netherlands'],
  ),
  'NO': CountryPattern(
    alpha2: 'NO',
    alpha3: 'NOR',
    flag: '🇳🇴',
    name: 'Norway',
    patterns: ['🇳🇴', 'NO', 'NOR', 'Norway'],
  ),
  'NP': CountryPattern(
    alpha2: 'NP',
    alpha3: 'NPL',
    flag: '🇳🇵',
    name: 'Nepal',
    patterns: ['🇳🇵', 'NP', 'NPL', 'Nepal'],
  ),
  'NZ': CountryPattern(
    alpha2: 'NZ',
    alpha3: 'NZL',
    flag: '🇳🇿',
    name: 'New Zealand',
    patterns: ['🇳🇿', 'NZ', 'NZL', 'New Zealand'],
  ),
  'OM': CountryPattern(
    alpha2: 'OM',
    alpha3: 'OMN',
    flag: '🇴🇲',
    name: 'Oman',
    patterns: ['🇴🇲', 'OM', 'OMN', 'Oman'],
  ),
  'PA': CountryPattern(
    alpha2: 'PA',
    alpha3: 'PAN',
    flag: '🇵🇦',
    name: 'Panama',
    patterns: ['🇵🇦', 'PA', 'PAN', 'Panama'],
  ),
  'PE': CountryPattern(
    alpha2: 'PE',
    alpha3: 'PER',
    flag: '🇵🇪',
    name: 'Peru',
    patterns: ['🇵🇪', 'PE', 'PER', 'Peru'],
  ),
  'PG': CountryPattern(
    alpha2: 'PG',
    alpha3: 'PNG',
    flag: '🇵🇬',
    name: 'Papua New Guinea',
    patterns: ['🇵🇬', 'PG', 'PNG', 'Papua New Guinea'],
  ),
  'PH': CountryPattern(
    alpha2: 'PH',
    alpha3: 'PHL',
    flag: '🇵🇭',
    name: 'Philippines',
    patterns: ['🇵🇭', 'PH', 'PHL', 'Philippines'],
  ),
  'PK': CountryPattern(
    alpha2: 'PK',
    alpha3: 'PAK',
    flag: '🇵🇰',
    name: 'Pakistan',
    patterns: ['🇵🇰', 'PK', 'PAK', 'Pakistan'],
  ),
  'PL': CountryPattern(
    alpha2: 'PL',
    alpha3: 'POL',
    flag: '🇵🇱',
    name: '波兰',
    patterns: ['🇵🇱', 'PL', 'POL', '波兰', 'Poland'],
  ),
  'PR': CountryPattern(
    alpha2: 'PR',
    alpha3: 'PRI',
    flag: '🇵🇷',
    name: 'Puerto Rico',
    patterns: ['🇵🇷', 'PR', 'PRI', 'Puerto Rico'],
  ),
  'PS': CountryPattern(
    alpha2: 'PS',
    alpha3: 'PSE',
    flag: '🇵🇸',
    name: 'Palestine',
    patterns: ['🇵🇸', 'PS', 'PSE', 'Palestine'],
  ),
  'PT': CountryPattern(
    alpha2: 'PT',
    alpha3: 'PRT',
    flag: '🇵🇹',
    name: 'Portugal',
    patterns: ['🇵🇹', 'PT', 'PRT', 'Portugal'],
  ),
  'PY': CountryPattern(
    alpha2: 'PY',
    alpha3: 'PRY',
    flag: '🇵🇾',
    name: 'Paraguay',
    patterns: ['🇵🇾', 'PY', 'PRY', 'Paraguay'],
  ),
  'QA': CountryPattern(
    alpha2: 'QA',
    alpha3: 'QAT',
    flag: '🇶🇦',
    name: 'Qatar',
    patterns: ['🇶🇦', 'QA', 'QAT', 'Qatar'],
  ),
  'RO': CountryPattern(
    alpha2: 'RO',
    alpha3: 'ROU',
    flag: '🇷🇴',
    name: '罗马尼亚',
    patterns: ['🇷🇴', 'RO', 'ROU', '罗马尼亚', 'Romania'],
  ),
  'RS': CountryPattern(
    alpha2: 'RS',
    alpha3: 'SRB',
    flag: '🇷🇸',
    name: 'Republic of Serbia',
    patterns: ['🇷🇸', 'RS', 'SRB', 'Republic of Serbia'],
  ),
  'RU': CountryPattern(
    alpha2: 'RU',
    alpha3: 'RUS',
    flag: '🇷🇺',
    name: '俄罗斯',
    patterns: ['🇷🇺', 'RU', 'RUS', '俄罗斯', 'Russia'],
  ),
  'RW': CountryPattern(
    alpha2: 'RW',
    alpha3: 'RWA',
    flag: '🇷🇼',
    name: 'Rwanda',
    patterns: ['🇷🇼', 'RW', 'RWA', 'Rwanda'],
  ),
  'SA': CountryPattern(
    alpha2: 'SA',
    alpha3: 'SAU',
    flag: '🇸🇦',
    name: 'Saudi Arabia',
    patterns: ['🇸🇦', 'SA', 'SAU', 'Saudi Arabia'],
  ),
  'SB': CountryPattern(
    alpha2: 'SB',
    alpha3: 'SLB',
    flag: '🇸🇧',
    name: 'Solomon Islands',
    patterns: ['🇸🇧', 'SB', 'SLB', 'Solomon Islands'],
  ),
  'SD': CountryPattern(
    alpha2: 'SD',
    alpha3: 'SDN',
    flag: '🇸🇩',
    name: 'Sudan',
    patterns: ['🇸🇩', 'SD', 'SDN', 'Sudan'],
  ),
  'SE': CountryPattern(
    alpha2: 'SE',
    alpha3: 'SWE',
    flag: '🇸🇪',
    name: '瑞典',
    patterns: ['🇸🇪', 'SE', 'SWE', '瑞典', 'Sweden'],
  ),
  'SG': CountryPattern(
    alpha2: 'SG',
    alpha3: 'SGP',
    flag: '🇸🇬',
    name: '新加坡',
    patterns: ['🇸🇬', 'SG', 'SGP', '新加坡', 'Singapore'],
  ),
  'SI': CountryPattern(
    alpha2: 'SI',
    alpha3: 'SVN',
    flag: '🇸🇮',
    name: 'Slovenia',
    patterns: ['🇸🇮', 'SI', 'SVN', 'Slovenia'],
  ),
  'SK': CountryPattern(
    alpha2: 'SK',
    alpha3: 'SVK',
    flag: '🇸🇰',
    name: 'Slovakia',
    patterns: ['🇸🇰', 'SK', 'SVK', 'Slovakia'],
  ),
  'SL': CountryPattern(
    alpha2: 'SL',
    alpha3: 'SLE',
    flag: '🇸🇱',
    name: 'Sierra Leone',
    patterns: ['🇸🇱', 'SL', 'SLE', 'Sierra Leone'],
  ),
  'SN': CountryPattern(
    alpha2: 'SN',
    alpha3: 'SEN',
    flag: '🇸🇳',
    name: 'Senegal',
    patterns: ['🇸🇳', 'SN', 'SEN', 'Senegal'],
  ),
  'SO': CountryPattern(
    alpha2: 'SO',
    alpha3: 'SOM',
    flag: '🇸🇴',
    name: 'Somalia',
    patterns: ['🇸🇴', 'SO', 'SOM', 'Somalia'],
  ),
  'SR': CountryPattern(
    alpha2: 'SR',
    alpha3: 'SUR',
    flag: '🇸🇷',
    name: 'Suriname',
    patterns: ['🇸🇷', 'SR', 'SUR', 'Suriname'],
  ),
  'SS': CountryPattern(
    alpha2: 'SS',
    alpha3: 'SSD',
    flag: '🇸🇸',
    name: 'South Sudan',
    patterns: ['🇸🇸', 'SS', 'SSD', 'South Sudan'],
  ),
  'SV': CountryPattern(
    alpha2: 'SV',
    alpha3: 'SLV',
    flag: '🇸🇻',
    name: 'El Salvador',
    patterns: ['🇸🇻', 'SV', 'SLV', 'El Salvador'],
  ),
  'SY': CountryPattern(
    alpha2: 'SY',
    alpha3: 'SYR',
    flag: '🇸🇾',
    name: 'Syria',
    patterns: ['🇸🇾', 'SY', 'SYR', 'Syria'],
  ),
  'SZ': CountryPattern(
    alpha2: 'SZ',
    alpha3: 'SWZ',
    flag: '🇸🇿',
    name: 'Swaziland',
    patterns: ['🇸🇿', 'SZ', 'SWZ', 'Swaziland'],
  ),
  'TD': CountryPattern(
    alpha2: 'TD',
    alpha3: 'TCD',
    flag: '🇹🇩',
    name: 'Chad',
    patterns: ['🇹🇩', 'TD', 'TCD', 'Chad'],
  ),
  'TF': CountryPattern(
    alpha2: 'TF',
    alpha3: 'ATF',
    flag: '🇹🇫',
    name: 'French Southern and Antarctic Lands',
    patterns: ['🇹🇫', 'TF', 'ATF', 'French Southern and Antarctic Lands'],
  ),
  'TG': CountryPattern(
    alpha2: 'TG',
    alpha3: 'TGO',
    flag: '🇹🇬',
    name: 'Togo',
    patterns: ['🇹🇬', 'TG', 'TGO', 'Togo'],
  ),
  'TH': CountryPattern(
    alpha2: 'TH',
    alpha3: 'THA',
    flag: '🇹🇭',
    name: 'Thailand',
    patterns: ['🇹🇭', 'TH', 'THA', 'Thailand'],
  ),
  'TJ': CountryPattern(
    alpha2: 'TJ',
    alpha3: 'TJK',
    flag: '🇹🇯',
    name: 'Tajikistan',
    patterns: ['🇹🇯', 'TJ', 'TJK', 'Tajikistan'],
  ),
  'TL': CountryPattern(
    alpha2: 'TL',
    alpha3: 'TLS',
    flag: '🇹🇱',
    name: 'East Timor',
    patterns: ['🇹🇱', 'TL', 'TLS', 'East Timor'],
  ),
  'TM': CountryPattern(
    alpha2: 'TM',
    alpha3: 'TKM',
    flag: '🇹🇲',
    name: 'Turkmenistan',
    patterns: ['🇹🇲', 'TM', 'TKM', 'Turkmenistan'],
  ),
  'TN': CountryPattern(
    alpha2: 'TN',
    alpha3: 'TUN',
    flag: '🇹🇳',
    name: 'Tunisia',
    patterns: ['🇹🇳', 'TN', 'TUN', 'Tunisia'],
  ),
  'TR': CountryPattern(
    alpha2: 'TR',
    alpha3: 'TUR',
    flag: '🇹🇷',
    name: 'Turkey',
    patterns: ['🇹🇷', 'TR', 'TUR', 'Turkey'],
  ),
  'TT': CountryPattern(
    alpha2: 'TT',
    alpha3: 'TTO',
    flag: '🇹🇹',
    name: 'Trinidad and Tobago',
    patterns: ['🇹🇹', 'TT', 'TTO', 'Trinidad and Tobago'],
  ),
  'TW': CountryPattern(
    alpha2: 'TW',
    alpha3: 'TWN',
    flag: '🇹🇼',
    name: '台湾',
    patterns: ['🇹🇼', 'TW', 'TWN', '台湾', 'Taiwan'],
  ),
  'TZ': CountryPattern(
    alpha2: 'TZ',
    alpha3: 'TZA',
    flag: '🇹🇿',
    name: 'United Republic of Tanzania',
    patterns: ['🇹🇿', 'TZ', 'TZA', 'United Republic of Tanzania'],
  ),
  'UA': CountryPattern(
    alpha2: 'UA',
    alpha3: 'UKR',
    flag: '🇺🇦',
    name: 'Ukraine',
    patterns: ['🇺🇦', 'UA', 'UKR', 'Ukraine'],
  ),
  'UG': CountryPattern(
    alpha2: 'UG',
    alpha3: 'UGA',
    flag: '🇺🇬',
    name: 'Uganda',
    patterns: ['🇺🇬', 'UG', 'UGA', 'Uganda'],
  ),
  'US': CountryPattern(
    alpha2: 'US',
    alpha3: 'USA',
    flag: '🇺🇸',
    name: '美国',
    patterns: ['🇺🇸', 'US', 'USA', '美国', 'United States', 'America'],
  ),
  'UY': CountryPattern(
    alpha2: 'UY',
    alpha3: 'URY',
    flag: '🇺🇾',
    name: 'Uruguay',
    patterns: ['🇺🇾', 'UY', 'URY', 'Uruguay'],
  ),
  'UZ': CountryPattern(
    alpha2: 'UZ',
    alpha3: 'UZB',
    flag: '🇺🇿',
    name: 'Uzbekistan',
    patterns: ['🇺🇿', 'UZ', 'UZB', 'Uzbekistan'],
  ),
  'VE': CountryPattern(
    alpha2: 'VE',
    alpha3: 'VEN',
    flag: '🇻🇪',
    name: 'Venezuela',
    patterns: ['🇻🇪', 'VE', 'VEN', 'Venezuela'],
  ),
  'VN': CountryPattern(
    alpha2: 'VN',
    alpha3: 'VNM',
    flag: '🇻🇳',
    name: '越南',
    patterns: ['🇻🇳', 'VN', 'VNM', '越南', 'Vietnam'],
  ),
  'VU': CountryPattern(
    alpha2: 'VU',
    alpha3: 'VUT',
    flag: '🇻🇺',
    name: 'Vanuatu',
    patterns: ['🇻🇺', 'VU', 'VUT', 'Vanuatu'],
  ),
  'XK': CountryPattern(
    alpha2: 'XK',
    alpha3: 'KOS',
    flag: '🇽🇰',
    name: 'Kosovo',
    patterns: ['🇽🇰', 'XK', 'KOS', 'Kosovo'],
  ),
  'YE': CountryPattern(
    alpha2: 'YE',
    alpha3: 'YEM',
    flag: '🇾🇪',
    name: 'Yemen',
    patterns: ['🇾🇪', 'YE', 'YEM', 'Yemen'],
  ),
  'ZA': CountryPattern(
    alpha2: 'ZA',
    alpha3: 'ZAF',
    flag: '🇿🇦',
    name: 'South Africa',
    patterns: ['🇿🇦', 'ZA', 'ZAF', 'South Africa'],
  ),
  'ZM': CountryPattern(
    alpha2: 'ZM',
    alpha3: 'ZMB',
    flag: '🇿🇲',
    name: 'Zambia',
    patterns: ['🇿🇲', 'ZM', 'ZMB', 'Zambia'],
  ),
  'ZW': CountryPattern(
    alpha2: 'ZW',
    alpha3: 'ZWE',
    flag: '🇿🇼',
    name: 'Zimbabwe',
    patterns: ['🇿🇼', 'ZW', 'ZWE', 'Zimbabwe'],
  ),
};

/// Flag emoji for an ISO alpha-2 code (regional indicator symbols).
String flagForAlpha2(String alpha2) {
  final a2 = alpha2.trim().toUpperCase();
  if (a2.length != 2) return '';
  return String.fromCharCodes(a2.codeUnits.map((c) => 0x1F1E6 + c - 0x41));
}

/// ISO_A2 for a globe.gl polygon feature.
///
/// Natural Earth 110m uses `-99` for France, Norway, Northern Cyprus and
/// Somaliland (disputed / special status); resolve those by admin name.
String alpha2ForGlobeFeature({required String isoA2, required String name}) {
  final a2 = isoA2.trim().toUpperCase();
  if (a2 != '-99' && a2.isNotEmpty) return a2;
  return switch (name.trim()) {
    'France' => 'FR',
    'Norway' => 'NO',
    'Northern Cyprus' => 'CY',
    'Somaliland' => 'SO',
    _ => a2,
  };
}

/// Map IDs returned by the old 2D `interactive_world_map` were alpha-2 codes
/// for most countries; `defaultMapIdResolver` mapped some to `X_<alpha-3>`.
/// This collapses them back to the alpha-2 used as the table key. Kept for
/// compatibility; the globe page sends plain alpha-2 already.
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

/// Escape only regex metacharacters; leave emoji/CJK/spaces untouched
/// ([RegExp.escape] would backslash-escape them and break matching).
String _escapeRegExp(String s) => s.replaceAllMapped(
  RegExp(r'[.*+?^${}()|\[\]\\]'),
  (m) => '\\${m.group(0)}',
);

final Map<String, RegExp> _patternRegexCache = {};

RegExp _patternRegex(String pattern) => _patternRegexCache.putIfAbsent(
  pattern,
  () => RegExp(r'(?<!\w)' + _escapeRegExp(pattern.toUpperCase()) + r'(?!\w)'),
);

/// Does a proxy name belong to this country?
bool isProxyInCountry(String proxyName, CountryPattern country) {
  final name = proxyName.toUpperCase();
  for (final pattern in country.patterns) {
    if (_patternRegex(pattern).hasMatch(name)) return true;
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
        if (entry.value.alpha3.toUpperCase() == match.group(0)) {
          return entry.key;
        }
      }
    }
  }
  // Case 2: flag / native name / alpha-2 code, e.g. `🇭🇰`, `香港`, `HKG`.
  for (final entry in kCountries.entries) {
    for (final pattern in entry.value.patterns) {
      if (_patternRegex(pattern).hasMatch(name)) return entry.key;
    }
  }
  return null;
}
