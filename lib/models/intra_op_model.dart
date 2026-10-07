import 'dart:convert';
import 'base/data_model.dart';
import 'operation_model.dart';

/// Database Table Constants for Intra-Op / Operative Details Table
class IntraOpTable {
  static const String tableName = 'intra_op_details';

  static const String columnIntraOpId = 'intra_op_id';
  static const String columnOperationId = 'operation_id';
  static const String columnOperativeNotes = 'operative_notes';
  static const String columnOperativePictures = 'operative_pictures';
  static const String columnAmountOfFatLiters = 'amount_of_fat_liters';
  static const String columnCorsetType = 'corset_type';
  static const String columnIsGarmentRequired = 'is_garment_required';
  static const String columnGarmentType = 'garment_type';
  static const String columnGarmentBrandModel = 'garment_brand_model';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnIntraOpId TEXT PRIMARY KEY,
      $columnOperationId TEXT NOT NULL,
      $columnOperativeNotes TEXT,
      $columnOperativePictures TEXT,
      $columnAmountOfFatLiters REAL,
      $columnCorsetType TEXT,
      $columnIsGarmentRequired INTEGER DEFAULT 0,
      $columnGarmentType TEXT,
      $columnGarmentBrandModel TEXT,
      FOREIGN KEY ($columnOperationId) REFERENCES ${OperationTable.tableName} (${OperationTable.columnOperationId}) ON DELETE CASCADE
    )
  ''';
}

/// 4. Operative Details (Intra-Op Table)
class IntraOpModel extends DataModel {
  final String intraOpId; // UUID (PK)
  final String operationId; // UUID (FK)
  
  // 1/ Operative notes
  final String operativeNotes;
  
  // 2/ Operative picture (Photo paths/URLs)
  final List<String> operativePictures;
  
  // 3/ Amount of fat (in litre)
  final double? amountOfFatLiters;
  
  // 4/ Compression Garment Section (Conditional)
  final bool isGarmentRequired;
  final String garmentType; // Area / Type (e.g. Abdomen, Chest...)
  final String garmentBrandModel; // Manufacturer / Brand & Model
  final String corsetType; // Legacy compatibility

  // Compatibility getters for legacy code
  String get operationDescription => operativeNotes;
  List<String> get intraOpImages => operativePictures;

  /// Structured JSON representation of garment info
  Map<String, dynamic> get garmentInfo => {
    'is_required': isGarmentRequired,
    'garment_type': garmentType,
    'brand_model': garmentBrandModel,
  };

  IntraOpModel({
    required this.intraOpId,
    required this.operationId,
    String? operativeNotes,
    String? operationDescription,
    List<String>? operativePictures,
    List<String>? intraOpImages,
    this.amountOfFatLiters,
    this.isGarmentRequired = false,
    this.garmentType = '',
    this.garmentBrandModel = '',
    String? corsetType,
  })  : operativeNotes = operativeNotes ?? operationDescription ?? '',
        operativePictures = operativePictures ?? intraOpImages ?? const [],
        corsetType = corsetType ?? (isGarmentRequired ? garmentType : '');

  @override
  String get tableName => IntraOpTable.tableName;

  @override
  String get primaryKeyColumn => IntraOpTable.columnIntraOpId;

  @override
  dynamic get primaryKeyValue => intraOpId;

  static String get createTableSql => IntraOpTable.createTableSql;

  @override
  Map<String, dynamic> toMap() {
    return {
      IntraOpTable.columnIntraOpId: intraOpId,
      IntraOpTable.columnOperationId: operationId,
      IntraOpTable.columnOperativeNotes: operativeNotes,
      IntraOpTable.columnOperativePictures: jsonEncode(operativePictures),
      IntraOpTable.columnAmountOfFatLiters: amountOfFatLiters,
      IntraOpTable.columnCorsetType: corsetType.isNotEmpty ? corsetType : (isGarmentRequired ? garmentType : ''),
      IntraOpTable.columnIsGarmentRequired: isGarmentRequired ? 1 : 0,
      IntraOpTable.columnGarmentType: garmentType,
      IntraOpTable.columnGarmentBrandModel: garmentBrandModel,
    };
  }

  factory IntraOpModel.fromMap(Map<String, dynamic> map) {
    final legacyCorset = map[IntraOpTable.columnCorsetType] as String? ?? '';
    final isReqRaw = map[IntraOpTable.columnIsGarmentRequired];
    final bool isReq = isReqRaw == 1 ||
        isReqRaw == true ||
        (isReqRaw == null &&
            legacyCorset.isNotEmpty &&
            legacyCorset.toLowerCase() != 'no' &&
            legacyCorset.toLowerCase() != 'none');
    final gType = map[IntraOpTable.columnGarmentType] as String? ?? legacyCorset;
    final gBrand = map[IntraOpTable.columnGarmentBrandModel] as String? ?? '';

    return IntraOpModel(
      intraOpId: map[IntraOpTable.columnIntraOpId] as String,
      operationId: map[IntraOpTable.columnOperationId] as String,
      operativeNotes: map[IntraOpTable.columnOperativeNotes] as String? ??
          map['operation_description'] as String? ??
          '',
      operativePictures: _parseStringList(map[IntraOpTable.columnOperativePictures] ?? map['intra_op_images']),
      amountOfFatLiters: (map[IntraOpTable.columnAmountOfFatLiters] as num?)?.toDouble(),
      isGarmentRequired: isReq,
      garmentType: gType,
      garmentBrandModel: gBrand,
      corsetType: legacyCorset.isNotEmpty ? legacyCorset : gType,
    );
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {
        if (raw.isNotEmpty) return [raw];
      }
    }
    return [];
  }

  IntraOpModel copyWith({
    String? intraOpId,
    String? operationId,
    String? operativeNotes,
    List<String>? operativePictures,
    double? amountOfFatLiters,
    bool? isGarmentRequired,
    String? garmentType,
    String? garmentBrandModel,
    String? corsetType,
  }) {
    return IntraOpModel(
      intraOpId: intraOpId ?? this.intraOpId,
      operationId: operationId ?? this.operationId,
      operativeNotes: operativeNotes ?? this.operativeNotes,
      operativePictures: operativePictures ?? this.operativePictures,
      amountOfFatLiters: amountOfFatLiters ?? this.amountOfFatLiters,
      isGarmentRequired: isGarmentRequired ?? this.isGarmentRequired,
      garmentType: garmentType ?? this.garmentType,
      garmentBrandModel: garmentBrandModel ?? this.garmentBrandModel,
      corsetType: corsetType ?? this.corsetType,
    );
  }
}
