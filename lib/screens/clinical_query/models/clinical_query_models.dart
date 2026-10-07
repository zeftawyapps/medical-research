import 'package:flutter/material.dart';

/// Encapsulates all criteria for the Advanced Clinical Search & Filter
class AdvancedFilterCriteria {
  final String? procedure;
  final String? gender;
  final RangeValues? ageRange;
  final String? complicationGrade;
  final bool? garmentRequired;
  final RangeValues? bmiRange;
  final String? medicalHistoryQuery;
  final RangeValues? fatVolumeRange;

  final String? patientNameQuery;
  final String? operativeProcedureQuery;
  final String? procedureTechniqueQuery;

  const AdvancedFilterCriteria({
    this.procedure,
    this.gender,
    this.ageRange,
    this.complicationGrade,
    this.garmentRequired,
    this.bmiRange,
    this.medicalHistoryQuery,
    this.fatVolumeRange,
    this.patientNameQuery,
    this.operativeProcedureQuery,
    this.procedureTechniqueQuery,
  });

  bool get isActive =>
      procedure != null ||
      gender != null ||
      ageRange != null ||
      complicationGrade != null ||
      garmentRequired != null ||
      bmiRange != null ||
      (medicalHistoryQuery != null && medicalHistoryQuery!.trim().isNotEmpty) ||
      fatVolumeRange != null ||
      (patientNameQuery != null && patientNameQuery!.trim().isNotEmpty) ||
      (operativeProcedureQuery != null && operativeProcedureQuery!.trim().isNotEmpty) ||
      (procedureTechniqueQuery != null && procedureTechniqueQuery!.trim().isNotEmpty);

  int get activeFiltersCount {
    int count = 0;
    if (procedure != null) count++;
    if (gender != null) count++;
    if (ageRange != null) count++;
    if (complicationGrade != null) count++;
    if (garmentRequired != null) count++;
    if (bmiRange != null) count++;
    if (medicalHistoryQuery != null && medicalHistoryQuery!.trim().isNotEmpty) {
      count++;
    }
    if (fatVolumeRange != null) count++;
    if (patientNameQuery != null && patientNameQuery!.trim().isNotEmpty) {
      count++;
    }
    if (operativeProcedureQuery != null && operativeProcedureQuery!.trim().isNotEmpty) {
      count++;
    }
    if (procedureTechniqueQuery != null && procedureTechniqueQuery!.trim().isNotEmpty) {
      count++;
    }
    return count;
  }

  AdvancedFilterCriteria copyWith({
    String? procedure,
    String? gender,
    RangeValues? ageRange,
    String? complicationGrade,
    bool? garmentRequired,
    RangeValues? bmiRange,
    String? medicalHistoryQuery,
    RangeValues? fatVolumeRange,
    String? patientNameQuery,
    String? operativeProcedureQuery,
    String? procedureTechniqueQuery,
    bool clearProcedure = false,
    bool clearGender = false,
    bool clearAgeRange = false,
    bool clearComplicationGrade = false,
    bool clearGarmentRequired = false,
    bool clearBmiRange = false,
    bool clearMedicalHistoryQuery = false,
    bool clearFatVolumeRange = false,
    bool clearPatientNameQuery = false,
    bool clearOperativeProcedureQuery = false,
    bool clearProcedureTechniqueQuery = false,
  }) {
    return AdvancedFilterCriteria(
      procedure: clearProcedure ? null : (procedure ?? this.procedure),
      gender: clearGender ? null : (gender ?? this.gender),
      ageRange: clearAgeRange ? null : (ageRange ?? this.ageRange),
      complicationGrade: clearComplicationGrade
          ? null
          : (complicationGrade ?? this.complicationGrade),
      garmentRequired: clearGarmentRequired
          ? null
          : (garmentRequired ?? this.garmentRequired),
      bmiRange: clearBmiRange ? null : (bmiRange ?? this.bmiRange),
      medicalHistoryQuery: clearMedicalHistoryQuery
          ? null
          : (medicalHistoryQuery ?? this.medicalHistoryQuery),
      fatVolumeRange: clearFatVolumeRange
          ? null
          : (fatVolumeRange ?? this.fatVolumeRange),
      patientNameQuery: clearPatientNameQuery
          ? null
          : (patientNameQuery ?? this.patientNameQuery),
      operativeProcedureQuery: clearOperativeProcedureQuery
          ? null
          : (operativeProcedureQuery ?? this.operativeProcedureQuery),
      procedureTechniqueQuery: clearProcedureTechniqueQuery
          ? null
          : (procedureTechniqueQuery ?? this.procedureTechniqueQuery),
    );
  }
}
