import 'package:JoDija_tamplites/util/cell_models/cell.dart';
import 'package:JoDija_tamplites/util/cell_models/cell_data_type.dart';
import 'package:JoDija_tamplites/util/cell_models/modul_screateor.dart';
import 'pre_op_model.dart';
import 'intra_op_model.dart';
import 'complication_model.dart';

/// Clinical cell model for pre-operative assessment and intra-operative details using JoDija Cell Engine
class PreOpAndOperativeCellModel extends CellModel {
  // 1/ Past Medical History **
  final pastMedicalHistory = Cell<String>(
    'pastMedicalHistory',
    caption: 'Past Medical History *',
    type: CellDataType.multilineText,
    isRequired: true,
    hint: 'Previous surgical procedures, chronic diseases, allergies...',
  );

  // 2/ Occupation **
  final occupation = Cell<String>(
    'occupation',
    caption: 'Occupation *',
    type: CellDataType.text,
    isRequired: true,
    hint: 'e.g., Field Engineer, Office Worker, Teacher...',
  );

  // 3/ Smoking: Y or N **
  final isSmoker = Cell<bool>(
    'isSmoker',
    caption: 'Smoking: Y or N *',
    type: CellDataType.boolean,
    isRequired: true,
    defaultValue: false,
  );

  final cigarettesPerDay = Cell<int>(
    'cigarettesPerDay',
    caption: 'Cigarettes / Day',
    type: CellDataType.integer,
    hint: 'e.g., 20',
  );

  final smokingYears = Cell<int>(
    'smokingYears',
    caption: 'Smoking Years',
    type: CellDataType.integer,
    hint: 'e.g., 8',
  );

  // 4/ Weight (Kg)
  final weightKg = Cell<double>(
    'weightKg',
    caption: 'Weight',
    type: CellDataType.decimal,
    unit: 'Kg',
    isRequired: true,
    hint: 'e.g., 82.5',
  );

  // 5/ Height (metre)
  final heightM = Cell<double>(
    'heightM',
    caption: 'Height',
    type: CellDataType.decimal,
    unit: 'm',
    isRequired: true,
    hint: 'e.g., 1.75',
  );

  // 6/ Investigations:
  final hemoglobin = Cell<double>(
    'hemoglobin',
    caption: 'Hemoglobin (Hb)',
    type: CellDataType.decimal,
    unit: 'g/dL',
    hint: 'Normal range: 13.5 - 17.5',
  );

  final t3 = Cell<double>(
    't3',
    caption: 'Thyroid Hormone T3 (Triiodothyronine)',
    type: CellDataType.decimal,
    unit: 'ng/dL',
    hint: 'e.g., 120',
  );

  final t4 = Cell<double>(
    't4',
    caption: 'Thyroid Hormone T4 (Thyroxine)',
    type: CellDataType.decimal,
    unit: 'µg/dL',
    hint: 'e.g., 8.5',
  );

  final scanPictures = Cell<List<String>>(
    'scanPictures',
    caption: 'Scan & Radiology Pictures',
    type: CellDataType.image,
    defaultValue: [],
  );

  // 7) Pre-operative picture
  final preOpPictures = Cell<List<String>>(
    'preOpPictures',
    caption: 'Pre-operative Clinical Pictures',
    type: CellDataType.image,
    defaultValue: [],
  );

  // --- Operative Details ---
  final operativeNotes = Cell<String>(
    'operativeNotes',
    caption: 'Operative Notes & Procedure Steps',
    type: CellDataType.multilineText,
    hint: 'Surgical details, technique, anesthesia, target anatomical areas...',
  );

  final operativePictures = Cell<List<String>>(
    'operativePictures',
    caption: 'Operative Field Pictures',
    type: CellDataType.image,
    defaultValue: [],
  );

  final amountOfFatLiters = Cell<double>(
    'amountOfFatLiters',
    caption: 'Amount of Fat Removed',
    type: CellDataType.decimal,
    unit: 'Litre',
    hint: 'e.g., 3.8',
  );

  final corsetType = Cell<String>(
    'corsetType',
    caption: 'Compression Garment / Corset Type',
    type: CellDataType.dropdown,
    options: [
      'Abdominal Garment',
      'Chest Vest',
      'Thigh & Hip Garment',
      'Arm Sleeves',
      'Full Body Suit',
      'Custom Tailored Corset',
    ],
  );

  @override
  List<Cell> toCells() {
    return [
      pastMedicalHistory,
      occupation,
      isSmoker,
      cigarettesPerDay,
      smokingYears,
      weightKg,
      heightM,
      hemoglobin,
      t3,
      t4,
      scanPictures,
      preOpPictures,
      operativeNotes,
      operativePictures,
      amountOfFatLiters,
      corsetType,
    ];
  }

  /// Automatic BMI calculation
  double? get calculatedBmi {
    final w = weightKg.value;
    final h = heightM.value;
    if (w == null || h == null || h <= 0 || w <= 0) return null;
    final res = w / (h * h);
    return double.parse(res.toStringAsFixed(2));
  }

  /// Populate cells from clinical models
  void populateFromModels(PreOpModel? preOp, IntraOpModel? intraOp) {
    if (preOp != null) {
      pastMedicalHistory.value = preOp.pastMedicalHistory;
      occupation.value = preOp.occupation;
      isSmoker.value = preOp.isSmoker;
      cigarettesPerDay.value = preOp.cigarettesPerDay;
      smokingYears.value = preOp.smokingYears;
      weightKg.value = preOp.weightKg;
      heightM.value = preOp.heightM;
      hemoglobin.value = preOp.hemoglobin;
      t3.value = preOp.t3;
      t4.value = preOp.t4;
      scanPictures.value = List<String>.from(preOp.scanPictures);
      preOpPictures.value = List<String>.from(preOp.preOpPictures);
    }
    if (intraOp != null) {
      operativeNotes.value = intraOp.operativeNotes;
      operativePictures.value = List<String>.from(intraOp.operativePictures);
      amountOfFatLiters.value = intraOp.amountOfFatLiters;
      corsetType.value = intraOp.corsetType;
    }
  }

  /// Convert cells to PreOpModel
  PreOpModel toPreOpModel({required String preOpId, required String operationId}) {
    return PreOpModel(
      preOpId: preOpId,
      operationId: operationId,
      pastMedicalHistory: pastMedicalHistory.value ?? '',
      occupation: occupation.value ?? '',
      isSmoker: isSmoker.value ?? false,
      cigarettesPerDay: cigarettesPerDay.value,
      smokingYears: smokingYears.value,
      weightKg: weightKg.value,
      heightM: heightM.value,
      hemoglobin: hemoglobin.value,
      t3: t3.value,
      t4: t4.value,
      scanPictures: List<String>.from(scanPictures.value ?? []),
      preOpPictures: List<String>.from(preOpPictures.value ?? []),
    );
  }

  /// Convert cells to IntraOpModel
  IntraOpModel toIntraOpModel({required String intraOpId, required String operationId}) {
    return IntraOpModel(
      intraOpId: intraOpId,
      operationId: operationId,
      operativeNotes: operativeNotes.value ?? '',
      operativePictures: List<String>.from(operativePictures.value ?? []),
      amountOfFatLiters: amountOfFatLiters.value,
      corsetType: corsetType.value ?? '',
    );
  }

  /// Clear all cell values
  void clear() {
    for (final c in toCells()) {
      c.value = c.defaultValue;
    }
    scanPictures.value = [];
    preOpPictures.value = [];
    operativePictures.value = [];
  }
}

/// Cell model for a single complication entry
class ComplicationCellModel extends CellModel {
  final description = Cell<String>(
    'description',
    caption: 'Complication Description *',
    type: CellDataType.multilineText,
    isRequired: true,
    hint: 'e.g., Seroma, Hematoma, Superficial infection...',
  );

  final dateOfComplication = Cell<String>(
    'dateOfComplication',
    caption: 'Date of Complication *',
    type: CellDataType.date,
    isRequired: true,
  );

  final treatment = Cell<String>(
    'treatment',
    caption: 'Treatment Protocol & Action Plan *',
    type: CellDataType.multilineText,
    isRequired: true,
    hint: 'e.g., Needle aspiration, antibiotics, garment pressure adjustment...',
  );

  final grade = Cell<String>(
    'grade',
    caption: 'Severity Grade (Clavien-Dindo Classification)',
    type: CellDataType.dropdown,
    options: [
      'Grade I (Minor, no specific treatment required)',
      'Grade II (Pharmacological treatment/antibiotics)',
      'Grade III (Surgical, endoscopic, or radiological intervention)',
      'Grade IV (Life-threatening complication)',
    ],
    defaultValue: 'Grade I (Minor, no specific treatment required)',
  );

  @override
  List<Cell> toCells() {
    return [
      description,
      dateOfComplication,
      treatment,
      grade,
    ];
  }

  /// Automatic POD calculation
  int calculatePod(DateTime operationDate) {
    final rawDate = dateOfComplication.value;
    if (rawDate == null || rawDate.isEmpty) return 0;
    final compDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    return ComplicationModel.computePod(operationDate, compDate);
  }

  /// Build ComplicationModel
  ComplicationModel toModel({
    required String complicationId,
    required String operationId,
    required DateTime operationDate,
  }) {
    final rawDate = dateOfComplication.value;
    final compDate = DateTime.tryParse(rawDate ?? '') ?? DateTime.now();
    final pod = ComplicationModel.computePod(operationDate, compDate);

    return ComplicationModel(
      complicationId: complicationId,
      operationId: operationId,
      description: description.value ?? '',
      dateOfComplication: compDate,
      podDay: pod,
      treatment: treatment.value ?? '',
      grade: grade.value ?? 'Grade I',
    );
  }

  /// Populate from existing model
  void populateFromModel(ComplicationModel model) {
    description.value = model.description;
    dateOfComplication.value = model.dateOfComplication.toIso8601String().split('T').first;
    treatment.value = model.treatment;
    grade.value = model.grade;
  }

  void clear() {
    for (final c in toCells()) {
      c.value = c.defaultValue;
    }
    dateOfComplication.value = DateTime.now().toIso8601String().split('T').first;
  }
}
