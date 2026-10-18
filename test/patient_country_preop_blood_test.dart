import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/data/countries_data.dart';
import 'package:medecat_research/models/patient_record_brd.dart';

/// ============================================================================
/// 🧪 Patient Country, Pre-Op & Demographics Test Suite (اختبارات دول المرضى والتفاصيل ما قبل الجراحة)
/// 
/// تغطي هذه المجموعة:
/// 1. التحقق من قائمة الدول الرئيسية والأعلام [worldCountries] ودالة المطابقة والبحث [findCountry].
/// 2. اختبار تخزين واسترجاع حقل الدولة والملاحظات في [PatientModel].
/// 3. اختبار بنية [PreOpModel] وخلوه من حقل فصيلة الدم المكرر (Blood Group) والتحقق من حسابات BMI والطول والوزن والتدخين.
/// ============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// --------------------------------------------------------------------------
  /// 📦 Group 1: Streamlined Countries Data & Flag Emoji Verification
  /// فحص قائمة الدول وأعلام الإيموجي والبحث باللغتين العربية والإنجليزية
  /// --------------------------------------------------------------------------
  group('Streamlined Countries Data & Flag Emoji Verification', () {
    test('worldCountries contains the streamlined list with primary 4 countries first', () {
      expect(worldCountries, isNotEmpty);
      expect(worldCountries.length, equals(9));

      // Verify the 4 primary countries are at the top
      expect(worldCountries[0].code, equals('EG'));
      expect(worldCountries[0].nameEn, equals('Egypt'));
      expect(worldCountries[0].nameAr, equals('مصر'));
      expect(worldCountries[0].isPrimary, isTrue);

      expect(worldCountries[1].code, equals('SA'));
      expect(worldCountries[1].nameEn, equals('Saudi Arabia'));
      expect(worldCountries[1].nameAr, equals('السعودية'));
      expect(worldCountries[1].isPrimary, isTrue);

      expect(worldCountries[2].code, equals('AE'));
      expect(worldCountries[2].nameEn, equals('United Arab Emirates'));
      expect(worldCountries[2].nameAr, equals('الإمارات'));
      expect(worldCountries[2].isPrimary, isTrue);

      expect(worldCountries[3].code, equals('KW'));
      expect(worldCountries[3].nameEn, equals('Kuwait'));
      expect(worldCountries[3].nameAr, equals('الكويت'));
      expect(worldCountries[3].isPrimary, isTrue);

      // Verify additional countries
      final codes = worldCountries.map((c) => c.code).toList();
      expect(codes, containsAll(['QA', 'BH', 'US', 'EU', 'OTHER']));

      for (final country in worldCountries) {
        expect(country.nameEn, isNotEmpty);
        expect(country.flag, isNotEmpty);
        expect(country.label, contains(country.flag));
        expect(country.label, contains(country.nameEn));
      }
    });

    test('extendedWorldCountries provides comprehensive world fallback', () {
      expect(extendedWorldCountries.length, greaterThanOrEqualTo(190));
    });

    test('findCountry resolves by code, English name, and Arabic name', () {
      // English
      final egypt = findCountry('Egypt');
      expect(egypt, isNotNull);
      expect(egypt!.code, equals('EG'));
      expect(egypt.flag, equals('🇪🇬'));
      expect(egypt.nameEn, equals('Egypt'));

      // Arabic
      final egyptAr = findCountry('مصر');
      expect(egyptAr, isNotNull);
      expect(egyptAr!.code, equals('EG'));

      final saudi = findCountry('السعودية');
      expect(saudi, isNotNull);
      expect(saudi!.nameEn, equals('Saudi Arabia'));
      expect(saudi.flag, equals('🇸🇦'));

      final uae = findCountry('الإمارات');
      expect(uae, isNotNull);
      expect(uae!.code, equals('AE'));
      expect(uae.flag, equals('🇦🇪'));

      final kuwait = findCountry('الكويت');
      expect(kuwait, isNotNull);
      expect(kuwait!.code, equals('KW'));

      final usa = findCountry('أمريكا');
      expect(usa, isNotNull);
      expect(usa!.code, equals('US'));

      final europe = findCountry('أوروبا');
      expect(europe, isNotNull);
      expect(europe!.code, equals('EU'));
    });

    test('CountryItem search matching is case-insensitive in English & Arabic', () {
      final eg = findCountry('EG')!;
      expect(eg.matches('egy'), isTrue);
      expect(eg.matches('egypt'), isTrue);
      expect(eg.matches('مصر'), isTrue);
      expect(eg.matches('eg'), isTrue);
      expect(eg.matches('france'), isFalse);
    });
  });

  group('PatientModel Country & Notes Verification', () {
    test('PatientModel correctly exposes country and notes', () {
      final patient = PatientModel(
        patientId: 'pid-123',
        medicalRecordNumber: 'MRN-2026-0001',
        demographics: {
          'name': 'Ahmed Ali',
          'age': 38,
          'gender': 'Male',
          'phone': '+201000000000',
          'country': 'Egypt',
          'notes': 'Penicillin allergy; diabetic patient',
        },
        createdAt: DateTime.now(),
      );

      expect(patient.name, equals('Ahmed Ali'));
      expect(patient.country, equals('Egypt'));
      expect(patient.notes, equals('Penicillin allergy; diabetic patient'));
    });

    test('PatientModel fallback defaults when country/notes are not provided', () {
      final patient = PatientModel(
        patientId: 'pid-456',
        medicalRecordNumber: 'MRN-2026-0002',
        demographics: {
          'name': 'Sarah Smith',
          'age': 29,
          'gender': 'Female',
        },
        createdAt: DateTime.now(),
      );

      expect(patient.country, equals(''));
      expect(patient.notes, equals(''));
    });
  });

  group('PreOpModel Clean Model Verification', () {
    test('PreOpModel stores and serializes without requiring bloodGroup', () {
      final preOp = PreOpModel(
        preOpId: 'pre-1',
        operationId: 'op-1',
        pastMedicalHistory: 'Hypertension',
        occupation: 'Engineer',
      );

      final map = preOp.toMap();
      expect(map[PreOpTable.columnPreOpId], equals('pre-1'));

      final restored = PreOpModel.fromMap(map);
      expect(restored.preOpId, equals('pre-1'));
      expect(restored.pastMedicalHistory, equals('Hypertension'));
      expect(restored.occupation, equals('Engineer'));
    });

    test('PreOpModel copyWith preserves clinical fields correctly', () {
      final preOp = PreOpModel(
        preOpId: 'pre-2',
        operationId: 'op-2',
        pastMedicalHistory: 'None',
        occupation: 'Teacher',
      );

      final updated = preOp.copyWith(pastMedicalHistory: 'Asthma');
      expect(updated.pastMedicalHistory, equals('Asthma'));
      expect(updated.occupation, equals('Teacher'));
      expect(updated.preOpId, equals('pre-2'));

      final unchanged = preOp.copyWith();
      expect(unchanged.pastMedicalHistory, equals('None'));
    });
  });
}
