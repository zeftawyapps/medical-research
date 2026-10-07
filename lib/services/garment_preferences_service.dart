import 'package:shared_preferences/shared_preferences.dart';

/// Service managing custom Garment Types and Brands stored in SharedPreferences
class GarmentPreferencesService {
  static const String keyCustomTypes = 'custom_garment_types_prefs';
  static const String keyCustomBrands = 'custom_garment_brands_prefs';

  // Standard initial English medical compression garment types
  static const List<String> defaultTypes = [
    'Abdomen',
    'Chest',
    'Arms',
    'Thighs & Flanks',
    'Full Body Suit',
    'Face & Neck',
    'Knee & Calf',
    'Chin & Neck Band',
  ];

  // Standard initial English medical compression garment brands
  static const List<String> defaultBrands = [
    'Marena',
    'Lipoelastic',
    'VOE',
    'Leonisa',
    'Contour',
    'Isavela',
    'Cerecare',
    'ClearPoint',
    'Design Veronique',
  ];

  /// Get custom types saved in SharedPreferences
  static Future<List<String>> getCustomTypes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keyCustomTypes) ?? [];
  }

  /// Add a new custom type to SharedPreferences
  static Future<void> saveCustomType(String type) async {
    final trimmed = type.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(keyCustomTypes) ?? [];
    if (!list.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
      list.add(trimmed);
      await prefs.setStringList(keyCustomTypes, list);
    }
  }

  /// Get custom brands saved in SharedPreferences
  static Future<List<String>> getCustomBrands() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(keyCustomBrands) ?? [];
  }

  /// Add a new custom brand to SharedPreferences
  static Future<void> saveCustomBrand(String brand) async {
    final trimmed = brand.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(keyCustomBrands) ?? [];
    if (!list.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
      list.add(trimmed);
      await prefs.setStringList(keyCustomBrands, list);
    }
  }

  /// Get all combined types (default + SharedPreferences custom)
  static Future<List<String>> getAllTypes() async {
    final custom = await getCustomTypes();
    final combined = <String>[...defaultTypes];
    for (final c in custom) {
      if (!combined.any((e) => e.toLowerCase() == c.toLowerCase())) {
        combined.add(c);
      }
    }
    return combined;
  }

  /// Get all combined brands (default + SharedPreferences custom)
  static Future<List<String>> getAllBrands() async {
    final custom = await getCustomBrands();
    final combined = <String>[...defaultBrands];
    for (final c in custom) {
      if (!combined.any((e) => e.toLowerCase() == c.toLowerCase())) {
        combined.add(c);
      }
    }
    return combined;
  }
}
