/// World countries data with ISO 2-letter codes, English & Arabic names, and Flag Emojis.
/// Streamlined to the primary countries (Egypt, Saudi Arabia, UAE, Kuwait) and
/// frequently encountered regions (Qatar, Bahrain, USA, Europe, Other).
class CountryItem {
  final String code;
  final String nameEn;
  final String nameAr;
  final bool isPrimary;

  const CountryItem({
    required this.code,
    required this.nameEn,
    this.nameAr = '',
    this.isPrimary = false,
  });

  /// Converts ISO 3166-1 alpha-2 code to Unicode Flag Emoji
  String get flag {
    if (code == 'OTHER' || code == 'OT') return '🌐';
    if (code.length != 2) return '🌐';
    final upper = code.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  /// Format: flag + English name + Arabic name (e.g. "🇪🇬  Egypt (مصر)")
  String get label => nameAr.isNotEmpty ? '$flag  $nameEn ($nameAr)' : '$flag  $nameEn';

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.trim().toLowerCase();
    return nameEn.toLowerCase().contains(q) ||
        nameAr.toLowerCase().contains(q) ||
        code.toLowerCase().contains(q);
  }
}

/// Streamlined list of active countries requested:
/// - 4 Primary / الأساسية: Egypt, Saudi Arabia, UAE, Kuwait
/// - Additional frequent / دول أخرى: Qatar, Bahrain, USA, Europe, Other
const List<CountryItem> worldCountries = [
  // Primary (الأكثر استخداماً)
  CountryItem(code: 'EG', nameEn: 'Egypt', nameAr: 'مصر', isPrimary: true),
  CountryItem(code: 'SA', nameEn: 'Saudi Arabia', nameAr: 'السعودية', isPrimary: true),
  CountryItem(code: 'AE', nameEn: 'United Arab Emirates', nameAr: 'الإمارات', isPrimary: true),
  CountryItem(code: 'KW', nameEn: 'Kuwait', nameAr: 'الكويت', isPrimary: true),

  // Additional common countries / دول أخرى شائعة
  CountryItem(code: 'QA', nameEn: 'Qatar', nameAr: 'قطر'),
  CountryItem(code: 'BH', nameEn: 'Bahrain', nameAr: 'البحرين'),
  CountryItem(code: 'US', nameEn: 'United States', nameAr: 'أمريكا'),
  CountryItem(code: 'EU', nameEn: 'Europe', nameAr: 'أوروبا'),
  CountryItem(code: 'OTHER', nameEn: 'Other', nameAr: 'أخرى'),
];

/// Helper to get a country by code, English name, or Arabic name
CountryItem? findCountry(String? query) {
  if (query == null || query.trim().isEmpty) return null;
  final clean = query.trim().toLowerCase();

  // 1. Check streamlined active countries first
  for (final c in worldCountries) {
    if (c.nameEn.toLowerCase() == clean ||
        c.nameAr.toLowerCase() == clean ||
        c.code.toLowerCase() == clean ||
        c.label.toLowerCase() == clean) {
      return c;
    }
  }

  // Common aliases in Arabic and English
  if (clean == 'uae' || clean == 'امارات' || clean == 'الامارات' || clean == 'دولة الإمارات العربية المتحدة') {
    return worldCountries.firstWhere((c) => c.code == 'AE');
  }
  if (clean == 'ksa' || clean == 'سعودية' || clean == 'السعودية' || clean == 'المملكة العربية السعودية') {
    return worldCountries.firstWhere((c) => c.code == 'SA');
  }
  if (clean == 'مصر' || clean == 'جمهورية مصر العربية') {
    return worldCountries.firstWhere((c) => c.code == 'EG');
  }
  if (clean == 'كويت' || clean == 'الكويت' || clean == 'دولة الكويت') {
    return worldCountries.firstWhere((c) => c.code == 'KW');
  }
  if (clean == 'قطر' || clean == 'دولة قطر') {
    return worldCountries.firstWhere((c) => c.code == 'QA');
  }
  if (clean == 'بحرين' || clean == 'البحرين' || clean == 'مملكة البحرين') {
    return worldCountries.firstWhere((c) => c.code == 'BH');
  }
  if (clean == 'usa' || clean == 'امريكا' || clean == 'أمريكا' || clean == 'الولايات المتحدة' || clean == 'الولايات المتحدة الأمريكية') {
    return worldCountries.firstWhere((c) => c.code == 'US');
  }
  if (clean == 'اوروبا' || clean == 'أوروبا' || clean == 'الاتحاد الأوروبي' || clean == 'europe') {
    return worldCountries.firstWhere((c) => c.code == 'EU');
  }
  if (clean == 'اخري' || clean == 'أخرى' || clean == 'اخرى' || clean == 'other') {
    return worldCountries.firstWhere((c) => c.code == 'OTHER');
  }

  // 2. Check extended world countries for fallback/legacy records
  for (final c in extendedWorldCountries) {
    if (c.nameEn.toLowerCase() == clean ||
        c.code.toLowerCase() == clean ||
        c.label.toLowerCase() == clean) {
      return c;
    }
  }

  return CountryItem(code: 'OTHER', nameEn: query.trim(), nameAr: query.trim());
}

/// Comprehensive extended list of world countries for backward compatibility & fallbacks
const List<CountryItem> extendedWorldCountries = [
  CountryItem(code: 'AF', nameEn: 'Afghanistan'),
  CountryItem(code: 'AL', nameEn: 'Albania'),
  CountryItem(code: 'DZ', nameEn: 'Algeria'),
  CountryItem(code: 'AD', nameEn: 'Andorra'),
  CountryItem(code: 'AO', nameEn: 'Angola'),
  CountryItem(code: 'AG', nameEn: 'Antigua and Barbuda'),
  CountryItem(code: 'AR', nameEn: 'Argentina'),
  CountryItem(code: 'AM', nameEn: 'Armenia'),
  CountryItem(code: 'AU', nameEn: 'Australia'),
  CountryItem(code: 'AT', nameEn: 'Austria'),
  CountryItem(code: 'AZ', nameEn: 'Azerbaijan'),
  CountryItem(code: 'BS', nameEn: 'Bahamas'),
  CountryItem(code: 'BH', nameEn: 'Bahrain'),
  CountryItem(code: 'BD', nameEn: 'Bangladesh'),
  CountryItem(code: 'BB', nameEn: 'Barbados'),
  CountryItem(code: 'BY', nameEn: 'Belarus'),
  CountryItem(code: 'BE', nameEn: 'Belgium'),
  CountryItem(code: 'BZ', nameEn: 'Belize'),
  CountryItem(code: 'BJ', nameEn: 'Benin'),
  CountryItem(code: 'BT', nameEn: 'Bhutan'),
  CountryItem(code: 'BO', nameEn: 'Bolivia'),
  CountryItem(code: 'BA', nameEn: 'Bosnia and Herzegovina'),
  CountryItem(code: 'BW', nameEn: 'Botswana'),
  CountryItem(code: 'BR', nameEn: 'Brazil'),
  CountryItem(code: 'BN', nameEn: 'Brunei'),
  CountryItem(code: 'BG', nameEn: 'Bulgaria'),
  CountryItem(code: 'BF', nameEn: 'Burkina Faso'),
  CountryItem(code: 'BI', nameEn: 'Burundi'),
  CountryItem(code: 'CV', nameEn: 'Cabo Verde'),
  CountryItem(code: 'KH', nameEn: 'Cambodia'),
  CountryItem(code: 'CM', nameEn: 'Cameroon'),
  CountryItem(code: 'CA', nameEn: 'Canada'),
  CountryItem(code: 'CF', nameEn: 'Central African Republic'),
  CountryItem(code: 'TD', nameEn: 'Chad'),
  CountryItem(code: 'CL', nameEn: 'Chile'),
  CountryItem(code: 'CN', nameEn: 'China'),
  CountryItem(code: 'CO', nameEn: 'Colombia'),
  CountryItem(code: 'KM', nameEn: 'Comoros'),
  CountryItem(code: 'CG', nameEn: 'Congo'),
  CountryItem(code: 'CR', nameEn: 'Costa Rica'),
  CountryItem(code: 'CI', nameEn: "Côte d'Ivoire"),
  CountryItem(code: 'HR', nameEn: 'Croatia'),
  CountryItem(code: 'CU', nameEn: 'Cuba'),
  CountryItem(code: 'CY', nameEn: 'Cyprus'),
  CountryItem(code: 'CZ', nameEn: 'Czech Republic'),
  CountryItem(code: 'DK', nameEn: 'Denmark'),
  CountryItem(code: 'DJ', nameEn: 'Djibouti'),
  CountryItem(code: 'DM', nameEn: 'Dominica'),
  CountryItem(code: 'DO', nameEn: 'Dominican Republic'),
  CountryItem(code: 'CD', nameEn: 'DR Congo'),
  CountryItem(code: 'EC', nameEn: 'Ecuador'),
  CountryItem(code: 'EG', nameEn: 'Egypt'),
  CountryItem(code: 'SV', nameEn: 'El Salvador'),
  CountryItem(code: 'GQ', nameEn: 'Equatorial Guinea'),
  CountryItem(code: 'ER', nameEn: 'Eritrea'),
  CountryItem(code: 'EE', nameEn: 'Estonia'),
  CountryItem(code: 'SZ', nameEn: 'Eswatini'),
  CountryItem(code: 'ET', nameEn: 'Ethiopia'),
  CountryItem(code: 'FJ', nameEn: 'Fiji'),
  CountryItem(code: 'FI', nameEn: 'Finland'),
  CountryItem(code: 'FR', nameEn: 'France'),
  CountryItem(code: 'GA', nameEn: 'Gabon'),
  CountryItem(code: 'GM', nameEn: 'Gambia'),
  CountryItem(code: 'GE', nameEn: 'Georgia'),
  CountryItem(code: 'DE', nameEn: 'Germany'),
  CountryItem(code: 'GH', nameEn: 'Ghana'),
  CountryItem(code: 'GR', nameEn: 'Greece'),
  CountryItem(code: 'GD', nameEn: 'Grenada'),
  CountryItem(code: 'GT', nameEn: 'Guatemala'),
  CountryItem(code: 'GN', nameEn: 'Guinea'),
  CountryItem(code: 'GW', nameEn: 'Guinea-Bissau'),
  CountryItem(code: 'GY', nameEn: 'Guyana'),
  CountryItem(code: 'HT', nameEn: 'Haiti'),
  CountryItem(code: 'HN', nameEn: 'Honduras'),
  CountryItem(code: 'HU', nameEn: 'Hungary'),
  CountryItem(code: 'IS', nameEn: 'Iceland'),
  CountryItem(code: 'IN', nameEn: 'India'),
  CountryItem(code: 'ID', nameEn: 'Indonesia'),
  CountryItem(code: 'IR', nameEn: 'Iran'),
  CountryItem(code: 'IQ', nameEn: 'Iraq'),
  CountryItem(code: 'IE', nameEn: 'Ireland'),
  CountryItem(code: 'IT', nameEn: 'Italy'),
  CountryItem(code: 'JM', nameEn: 'Jamaica'),
  CountryItem(code: 'JP', nameEn: 'Japan'),
  CountryItem(code: 'JO', nameEn: 'Jordan'),
  CountryItem(code: 'KZ', nameEn: 'Kazakhstan'),
  CountryItem(code: 'KE', nameEn: 'Kenya'),
  CountryItem(code: 'KI', nameEn: 'Kiribati'),
  CountryItem(code: 'KW', nameEn: 'Kuwait'),
  CountryItem(code: 'KG', nameEn: 'Kyrgyzstan'),
  CountryItem(code: 'LA', nameEn: 'Laos'),
  CountryItem(code: 'LV', nameEn: 'Latvia'),
  CountryItem(code: 'LB', nameEn: 'Lebanon'),
  CountryItem(code: 'LS', nameEn: 'Lesotho'),
  CountryItem(code: 'LR', nameEn: 'Liberia'),
  CountryItem(code: 'LY', nameEn: 'Libya'),
  CountryItem(code: 'LI', nameEn: 'Liechtenstein'),
  CountryItem(code: 'LT', nameEn: 'Lithuania'),
  CountryItem(code: 'LU', nameEn: 'Luxembourg'),
  CountryItem(code: 'MG', nameEn: 'Madagascar'),
  CountryItem(code: 'MW', nameEn: 'Malawi'),
  CountryItem(code: 'MY', nameEn: 'Malaysia'),
  CountryItem(code: 'MV', nameEn: 'Maldives'),
  CountryItem(code: 'ML', nameEn: 'Mali'),
  CountryItem(code: 'MT', nameEn: 'Malta'),
  CountryItem(code: 'MH', nameEn: 'Marshall Islands'),
  CountryItem(code: 'MR', nameEn: 'Mauritania'),
  CountryItem(code: 'MU', nameEn: 'Mauritius'),
  CountryItem(code: 'MX', nameEn: 'Mexico'),
  CountryItem(code: 'FM', nameEn: 'Micronesia'),
  CountryItem(code: 'MD', nameEn: 'Moldova'),
  CountryItem(code: 'MC', nameEn: 'Monaco'),
  CountryItem(code: 'MN', nameEn: 'Mongolia'),
  CountryItem(code: 'ME', nameEn: 'Montenegro'),
  CountryItem(code: 'MA', nameEn: 'Morocco'),
  CountryItem(code: 'MZ', nameEn: 'Mozambique'),
  CountryItem(code: 'MM', nameEn: 'Myanmar'),
  CountryItem(code: 'NA', nameEn: 'Namibia'),
  CountryItem(code: 'NR', nameEn: 'Nauru'),
  CountryItem(code: 'NP', nameEn: 'Nepal'),
  CountryItem(code: 'NL', nameEn: 'Netherlands'),
  CountryItem(code: 'NZ', nameEn: 'New Zealand'),
  CountryItem(code: 'NI', nameEn: 'Nicaragua'),
  CountryItem(code: 'NE', nameEn: 'Niger'),
  CountryItem(code: 'NG', nameEn: 'Nigeria'),
  CountryItem(code: 'KP', nameEn: 'North Korea'),
  CountryItem(code: 'MK', nameEn: 'North Macedonia'),
  CountryItem(code: 'NO', nameEn: 'Norway'),
  CountryItem(code: 'OM', nameEn: 'Oman'),
  CountryItem(code: 'PK', nameEn: 'Pakistan'),
  CountryItem(code: 'PW', nameEn: 'Palau'),
  CountryItem(code: 'PS', nameEn: 'Palestine'),
  CountryItem(code: 'PA', nameEn: 'Panama'),
  CountryItem(code: 'PG', nameEn: 'Papua New Guinea'),
  CountryItem(code: 'PY', nameEn: 'Paraguay'),
  CountryItem(code: 'PE', nameEn: 'Peru'),
  CountryItem(code: 'PH', nameEn: 'Philippines'),
  CountryItem(code: 'PL', nameEn: 'Poland'),
  CountryItem(code: 'PT', nameEn: 'Portugal'),
  CountryItem(code: 'QA', nameEn: 'Qatar'),
  CountryItem(code: 'RO', nameEn: 'Romania'),
  CountryItem(code: 'RU', nameEn: 'Russia'),
  CountryItem(code: 'RW', nameEn: 'Rwanda'),
  CountryItem(code: 'KN', nameEn: 'Saint Kitts and Nevis'),
  CountryItem(code: 'LC', nameEn: 'Saint Lucia'),
  CountryItem(code: 'VC', nameEn: 'Saint Vincent and the Grenadines'),
  CountryItem(code: 'WS', nameEn: 'Samoa'),
  CountryItem(code: 'SM', nameEn: 'San Marino'),
  CountryItem(code: 'ST', nameEn: 'Sao Tome and Principe'),
  CountryItem(code: 'SA', nameEn: 'Saudi Arabia'),
  CountryItem(code: 'SN', nameEn: 'Senegal'),
  CountryItem(code: 'RS', nameEn: 'Serbia'),
  CountryItem(code: 'SC', nameEn: 'Seychelles'),
  CountryItem(code: 'SL', nameEn: 'Sierra Leone'),
  CountryItem(code: 'SG', nameEn: 'Singapore'),
  CountryItem(code: 'SK', nameEn: 'Slovakia'),
  CountryItem(code: 'SI', nameEn: 'Slovenia'),
  CountryItem(code: 'SB', nameEn: 'Solomon Islands'),
  CountryItem(code: 'SO', nameEn: 'Somalia'),
  CountryItem(code: 'ZA', nameEn: 'South Africa'),
  CountryItem(code: 'KR', nameEn: 'South Korea'),
  CountryItem(code: 'SS', nameEn: 'South Sudan'),
  CountryItem(code: 'ES', nameEn: 'Spain'),
  CountryItem(code: 'LK', nameEn: 'Sri Lanka'),
  CountryItem(code: 'SD', nameEn: 'Sudan'),
  CountryItem(code: 'SR', nameEn: 'Suriname'),
  CountryItem(code: 'SE', nameEn: 'Sweden'),
  CountryItem(code: 'CH', nameEn: 'Switzerland'),
  CountryItem(code: 'SY', nameEn: 'Syria'),
  CountryItem(code: 'TJ', nameEn: 'Tajikistan'),
  CountryItem(code: 'TZ', nameEn: 'Tanzania'),
  CountryItem(code: 'TH', nameEn: 'Thailand'),
  CountryItem(code: 'TL', nameEn: 'Timor-Leste'),
  CountryItem(code: 'TG', nameEn: 'Togo'),
  CountryItem(code: 'TO', nameEn: 'Tonga'),
  CountryItem(code: 'TT', nameEn: 'Trinidad and Tobago'),
  CountryItem(code: 'TN', nameEn: 'Tunisia'),
  CountryItem(code: 'TR', nameEn: 'Turkey'),
  CountryItem(code: 'TM', nameEn: 'Turkmenistan'),
  CountryItem(code: 'TV', nameEn: 'Tuvalu'),
  CountryItem(code: 'UG', nameEn: 'Uganda'),
  CountryItem(code: 'UA', nameEn: 'Ukraine'),
  CountryItem(code: 'AE', nameEn: 'United Arab Emirates'),
  CountryItem(code: 'GB', nameEn: 'United Kingdom'),
  CountryItem(code: 'US', nameEn: 'United States'),
  CountryItem(code: 'UY', nameEn: 'Uruguay'),
  CountryItem(code: 'UZ', nameEn: 'Uzbekistan'),
  CountryItem(code: 'VU', nameEn: 'Vanuatu'),
  CountryItem(code: 'VA', nameEn: 'Vatican City'),
  CountryItem(code: 'VE', nameEn: 'Venezuela'),
  CountryItem(code: 'VN', nameEn: 'Vietnam'),
  CountryItem(code: 'YE', nameEn: 'Yemen'),
  CountryItem(code: 'ZM', nameEn: 'Zambia'),
  CountryItem(code: 'ZW', nameEn: 'Zimbabwe'),
];
