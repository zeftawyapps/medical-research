import 'package:flutter/material.dart';
import '../../models/patient_record_brd.dart';

enum TimeFramePreset {
  allTime,
  last7Days,
  last30Days,
  last90Days,
  lastYear,
  customRange,
}

enum PodFilter { allPod, pod0To3, pod4To7, pod8To30, pod30Plus }

class SearchMatchResult {
  final CompleteClinicalCase clinicalCase;
  final List<String> matchedFields;

  const SearchMatchResult({
    required this.clinicalCase,
    required this.matchedFields,
  });
}

class TimeFrameStats {
  final int totalCases;
  final int casesWithComplications;
  final double complicationRate;
  final double meanAge;
  final int garmentUsageCount;
  final double garmentUsageRate;
  final Map<String, int> gradeDistribution;
  final Map<String, int> surgeryTypeDistribution;

  const TimeFrameStats({
    required this.totalCases,
    required this.casesWithComplications,
    required this.complicationRate,
    required this.meanAge,
    this.garmentUsageCount = 0,
    this.garmentUsageRate = 0.0,
    required this.gradeDistribution,
    required this.surgeryTypeDistribution,
  });
}

class ResearchSearchEngine {
  /// Filter cases by Time Frame
  static List<CompleteClinicalCase> filterByTimeFrame(
    List<CompleteClinicalCase> allCases, {
    required TimeFramePreset preset,
    DateTimeRange? customRange,
  }) {
    final now = DateTime.now();

    DateTime? startDate;
    DateTime? endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case TimeFramePreset.allTime:
        startDate = null;
        endDate = null;
        break;
      case TimeFramePreset.last7Days:
        final d = now.subtract(const Duration(days: 7));
        startDate = DateTime(d.year, d.month, d.day, 0, 0, 0);
        break;
      case TimeFramePreset.last30Days:
        final d = now.subtract(const Duration(days: 30));
        startDate = DateTime(d.year, d.month, d.day, 0, 0, 0);
        break;
      case TimeFramePreset.last90Days:
        final d = now.subtract(const Duration(days: 90));
        startDate = DateTime(d.year, d.month, d.day, 0, 0, 0);
        break;
      case TimeFramePreset.lastYear:
        final d = now.subtract(const Duration(days: 365));
        startDate = DateTime(d.year, d.month, d.day, 0, 0, 0);
        break;
      case TimeFramePreset.customRange:
        if (customRange != null) {
          final s = customRange.start.isBefore(customRange.end)
              ? customRange.start
              : customRange.end;
          final e = customRange.start.isBefore(customRange.end)
              ? customRange.end
              : customRange.start;
          startDate = DateTime(
            s.year,
            s.month,
            s.day,
            s.hour,
            s.minute,
            s.second,
          );
          final hasExplicitEndTime =
              e.hour != 0 || e.minute != 0 || e.second != 0;
          endDate = hasExplicitEndTime
              ? DateTime(e.year, e.month, e.day, e.hour, e.minute, e.second)
              : DateTime(e.year, e.month, e.day, 23, 59, 59);
        }
        break;
    }

    if (startDate == null) return allCases;

    return allCases.where((c) {
      // STRICTLY: Filter by Date of Operation (operation.operationDate)
      // Disregards patient intake/registration date, complication dates, or lab dates
      final opDate = c.operation.operationDate;
      if (startDate != null && opDate.isBefore(startDate)) return false;
      if (endDate != null && opDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  /// Filter cases strictly between two specific cases' operation dates
  static List<CompleteClinicalCase> filterBetweenCases(
    List<CompleteClinicalCase> allCases, {
    required CompleteClinicalCase startCase,
    required CompleteClinicalCase endCase,
  }) {
    final s = startCase.operation.operationDate;
    final e = endCase.operation.operationDate;
    final minDate = s.isBefore(e) ? s : e;
    final maxDate = s.isBefore(e) ? e : s;

    final startDate = DateTime(
      minDate.year,
      minDate.month,
      minDate.day,
      0,
      0,
      0,
    );
    final endDate = DateTime(
      maxDate.year,
      maxDate.month,
      maxDate.day,
      23,
      59,
      59,
    );

    return allCases.where((c) {
      final opDate = c.operation.operationDate;
      if (opDate.isBefore(startDate)) return false;
      if (opDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  /// Filter cases by POD Day
  static List<CompleteClinicalCase> filterByPod(
    List<CompleteClinicalCase> cases,
    PodFilter filter,
  ) {
    if (filter == PodFilter.allPod) return cases;

    return cases.where((c) {
      if (c.complications.isEmpty) return false;
      return c.complications.any((comp) {
        switch (filter) {
          case PodFilter.pod0To3:
            return comp.podDay >= 0 && comp.podDay <= 3;
          case PodFilter.pod4To7:
            return comp.podDay >= 4 && comp.podDay <= 7;
          case PodFilter.pod8To30:
            return comp.podDay >= 8 && comp.podDay <= 30;
          case PodFilter.pod30Plus:
            return comp.podDay > 30;
          case PodFilter.allPod:
            return true;
        }
      });
    }).toList();
  }

  /// Universal Deep Multi-Field Search Engine
  static List<SearchMatchResult> searchAllFields(
    List<CompleteClinicalCase> cases,
    String query, {
    String? patientNameQuery,
    String? medicalHistoryQuery,
    String? operativeProcedureQuery,
    String? procedureTechniqueQuery,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final cleanPatient = patientNameQuery?.trim().toLowerCase() ?? '';
    final cleanHistory = medicalHistoryQuery?.trim().toLowerCase() ?? '';
    final cleanProcedure = operativeProcedureQuery?.trim().toLowerCase() ?? '';
    final cleanTechnique = procedureTechniqueQuery?.trim().toLowerCase() ?? '';

    final hasSpecificFilters = cleanPatient.isNotEmpty ||
        cleanHistory.isNotEmpty ||
        cleanProcedure.isNotEmpty ||
        cleanTechnique.isNotEmpty;

    if (cleanQuery.isEmpty && !hasSpecificFilters) {
      return cases
          .map((c) => SearchMatchResult(clinicalCase: c, matchedFields: []))
          .toList();
    }

    final List<SearchMatchResult> results = [];

    for (var c in cases) {
      final List<String> matches = [];
      bool passesSpecificFilters = true;

      // 1. Specific Filter: Patient Name
      if (cleanPatient.isNotEmpty) {
        if (c.patient.medicalRecordNumber.toLowerCase().contains(cleanPatient) ||
            c.patient.name.toLowerCase().contains(cleanPatient)) {
          matches.add('Patient: ${c.patient.name}');
        } else {
          passesSpecificFilters = false;
        }
      }

      // 2. Specific Filter: Medical History
      if (cleanHistory.isNotEmpty) {
        if ((c.preOp?.pastMedicalHistory.toLowerCase().contains(cleanHistory) ?? false) ||
            (c.operation.diagnosisDetails.toLowerCase().contains(cleanHistory)) ||
            (c.preOp?.caseDescription.toLowerCase().contains(cleanHistory) ?? false)) {
          matches.add('History: $cleanHistory');
        } else {
          passesSpecificFilters = false;
        }
      }

      // 3. Specific Filter: Operative Procedure
      if (cleanProcedure.isNotEmpty) {
        if (c.operation.operationType.toLowerCase().contains(cleanProcedure) ||
            c.operation.diagnosisDetails.toLowerCase().contains(cleanProcedure)) {
          matches.add('Procedure: ${c.operation.operationType}');
        } else {
          passesSpecificFilters = false;
        }
      }

      // 4. Specific Filter: Procedure Technique
      if (cleanTechnique.isNotEmpty) {
        if ((c.intraOp?.operativeNotes.toLowerCase().contains(cleanTechnique) ?? false) ||
            (c.intraOp?.operationDescription.toLowerCase().contains(cleanTechnique) ?? false)) {
          matches.add('Technique Matched');
        } else {
          passesSpecificFilters = false;
        }
      }

      if (!passesSpecificFilters) {
        continue;
      }

      bool hasGenericMatch = false;

      if (cleanQuery.isNotEmpty) {
        // Generic Patient MRN & Name
        if (c.patient.medicalRecordNumber.toLowerCase().contains(cleanQuery)) {
          matches.add('MRN: ${c.patient.medicalRecordNumber}');
          hasGenericMatch = true;
        }
        if (c.patient.name.toLowerCase().contains(cleanQuery)) {
          matches.add('Patient: ${c.patient.name}');
          hasGenericMatch = true;
        }
        if (c.patient.demographics.values.any(
          (v) => v.toString().toLowerCase().contains(cleanQuery),
        )) {
          matches.add('Demographics');
          hasGenericMatch = true;
        }

        // Generic Operation Type & Diagnosis
        if (c.operation.operationType.toLowerCase().contains(cleanQuery)) {
          matches.add('Procedure: ${c.operation.operationType}');
          hasGenericMatch = true;
        }
        if (c.operation.diagnosisDetails.toLowerCase().contains(cleanQuery)) {
          matches.add('Diagnosis');
          hasGenericMatch = true;
        }
        if (c.operation.hospital.toLowerCase().contains(cleanQuery)) {
          matches.add('Hospital: ${c.operation.hospital}');
          hasGenericMatch = true;
        }

        // Generic Pre-Op Case Description & Investigations
        if (c.preOp != null) {
          if (c.preOp!.caseDescription.toLowerCase().contains(cleanQuery)) {
            matches.add('Pre-Op Notes');
            hasGenericMatch = true;
          }
          if (c.preOp!.radiologyReports.toLowerCase().contains(cleanQuery)) {
            matches.add('Radiology Reports');
            hasGenericMatch = true;
          }
          if (c.preOp!.pastMedicalHistory.toLowerCase().contains(cleanQuery)) {
            matches.add('Past Medical History');
            hasGenericMatch = true;
          }
          if (c.preOp!.occupation.toLowerCase().contains(cleanQuery)) {
            matches.add('Occupation');
            hasGenericMatch = true;
          }
        }

        // Generic Intra-Op Description
        if (c.intraOp != null) {
          if (c.intraOp!.operationDescription.toLowerCase().contains(cleanQuery)) {
            matches.add('Intra-Op Steps');
            hasGenericMatch = true;
          }
        }

        // Generic Post-Op Description
        if (c.postOp != null) {
          if (c.postOp!.postOpDescription.toLowerCase().contains(cleanQuery)) {
            matches.add('Post-Op Progress');
            hasGenericMatch = true;
          }
        }

        // Generic Complications (POD, Grade, Management)
        for (var comp in c.complications) {
          if (comp.grade.toLowerCase().contains(cleanQuery) ||
              comp.management.toLowerCase().contains(cleanQuery) ||
              'pod ${comp.podDay}'.contains(cleanQuery)) {
            matches.add('Complication (${comp.grade}, POD ${comp.podDay})');
            hasGenericMatch = true;
          }
        }

        // Generic Blood & Labs
        for (var lab in c.bloodLabs) {
          if (lab.testName.toLowerCase().contains(cleanQuery) ||
              lab.resultValue.toLowerCase().contains(cleanQuery)) {
            matches.add('Lab: ${lab.testName} (${lab.resultValue})');
            hasGenericMatch = true;
          }
        }

        // Generic Surveys
        for (var surv in c.surveys) {
          if (surv.surveyType.toLowerCase().contains(cleanQuery) ||
              surv.evaluationQuestions.values.any(
                (v) => v.toString().toLowerCase().contains(cleanQuery),
              )) {
            matches.add('Survey: ${surv.surveyType}');
            hasGenericMatch = true;
          }
        }
      } else {
        // If cleanQuery is empty, but it passed specific filters, it's a match.
        hasGenericMatch = true;
      }

      if (hasGenericMatch && matches.isNotEmpty) {
        // De-duplicate matches
        final uniqueMatches = matches.toSet().toList();
        results.add(SearchMatchResult(clinicalCase: c, matchedFields: uniqueMatches));
      } else if (hasGenericMatch && cleanQuery.isEmpty && hasSpecificFilters) {
        results.add(SearchMatchResult(clinicalCase: c, matchedFields: matches.toSet().toList()));
      }
    }

    return results;
  }

  /// Calculate Aggregate Statistics for a filtered case list
  static TimeFrameStats calculateStats(List<CompleteClinicalCase> cases) {
    if (cases.isEmpty) {
      return const TimeFrameStats(
        totalCases: 0,
        casesWithComplications: 0,
        complicationRate: 0.0,
        meanAge: 0.0,
        gradeDistribution: {},
        surgeryTypeDistribution: {},
      );
    }

    int compCases = 0;
    double totalAge = 0;
    int garmentCases = 0;
    final Map<String, int> gradeDist = {};
    final Map<String, int> surgeryDist = {};

    for (var c in cases) {
      totalAge += c.patient.age;
      surgeryDist[c.operation.operationType] =
          (surgeryDist[c.operation.operationType] ?? 0) + 1;

      if (c.intraOp != null && c.intraOp!.isGarmentRequired) {
        garmentCases++;
      }

      if (c.hasComplications) {
        compCases++;
        for (var comp in c.complications) {
          gradeDist[comp.grade] = (gradeDist[comp.grade] ?? 0) + 1;
        }
      }
    }

    return TimeFrameStats(
      totalCases: cases.length,
      casesWithComplications: compCases,
      complicationRate: (compCases / cases.length) * 100,
      meanAge: totalAge / cases.length,
      garmentUsageCount: garmentCases,
      garmentUsageRate: (garmentCases / cases.length) * 100,
      gradeDistribution: gradeDist,
      surgeryTypeDistribution: surgeryDist,
    );
  }
}
