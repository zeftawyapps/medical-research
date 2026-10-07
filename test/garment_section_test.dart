import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medecat_research/models/patient_record_brd.dart';
import 'package:medecat_research/services/garment_preferences_service.dart';
import 'package:medecat_research/widgets/conditional_garment_section_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Garment Section - Model & Schema Verification', () {
    test('IntraOpModel serialization and garment_info structure', () {
      final intraOp = IntraOpModel(
        intraOpId: 'intra-101',
        operationId: 'op-202',
        operativeNotes: 'Tumescent liposuction performed',
        amountOfFatLiters: 3.5,
        isGarmentRequired: true,
        garmentType: 'Abdomen',
        garmentBrandModel: 'Marena Comfort Pro Stage 1',
      );

      // Verify model fields
      expect(intraOp.isGarmentRequired, isTrue);
      expect(intraOp.garmentType, equals('Abdomen'));
      expect(intraOp.garmentBrandModel, equals('Marena Comfort Pro Stage 1'));

      // Verify garment_info structured map
      final info = intraOp.garmentInfo;
      expect(info['is_required'], isTrue);
      expect(info['garment_type'], equals('Abdomen'));
      expect(info['brand_model'], equals('Marena Comfort Pro Stage 1'));

      // Verify toMap
      final map = intraOp.toMap();
      expect(map[IntraOpTable.columnIsGarmentRequired], equals(1));
      expect(map[IntraOpTable.columnGarmentType], equals('Abdomen'));
      expect(map[IntraOpTable.columnGarmentBrandModel], equals('Marena Comfort Pro Stage 1'));

      // Verify fromMap round-trip
      final restored = IntraOpModel.fromMap(map);
      expect(restored.intraOpId, equals('intra-101'));
      expect(restored.isGarmentRequired, isTrue);
      expect(restored.garmentType, equals('Abdomen'));
      expect(restored.garmentBrandModel, equals('Marena Comfort Pro Stage 1'));
    });

    test('IntraOpModel backwards compatibility when garment is not required', () {
      final intraOp = IntraOpModel(
        intraOpId: 'intra-102',
        operationId: 'op-203',
        operativeNotes: 'Minor procedure',
        isGarmentRequired: false,
      );

      expect(intraOp.isGarmentRequired, isFalse);
      expect(intraOp.garmentType, isEmpty);
      expect(intraOp.garmentBrandModel, isEmpty);

      final map = intraOp.toMap();
      expect(map[IntraOpTable.columnIsGarmentRequired], equals(0));

      final restored = IntraOpModel.fromMap(map);
      expect(restored.isGarmentRequired, isFalse);
    });

    test('IntraOpModel backwards compatibility with legacy database maps', () {
      final legacyMap = {
        IntraOpTable.columnIntraOpId: 'intra-legacy-1',
        IntraOpTable.columnOperationId: 'op-1',
        IntraOpTable.columnOperativeNotes: 'Routine notes',
        IntraOpTable.columnCorsetType: 'Chest Vest',
      };

      final restored = IntraOpModel.fromMap(legacyMap);
      expect(restored.isGarmentRequired, isTrue);
      expect(restored.garmentType, equals('Chest Vest'));
      expect(restored.garmentBrandModel, isEmpty);
    });

    test('GarmentBrandModel and GarmentTypeModel serialization', () {
      final brand = GarmentBrandModel(
        id: 'b-1',
        name: 'Lipoelastic',
        createdAt: DateTime(2026, 1, 1),
      );
      final brandMap = brand.toMap();
      final restoredBrand = GarmentBrandModel.fromMap(brandMap);
      expect(restoredBrand.id, equals('b-1'));
      expect(restoredBrand.name, equals('Lipoelastic'));

      final type = GarmentTypeModel(
        id: 't-1',
        name: 'Arms',
        createdAt: DateTime(2026, 1, 1),
      );
      final typeMap = type.toMap();
      final restoredType = GarmentTypeModel.fromMap(typeMap);
      expect(restoredType.id, equals('t-1'));
      expect(restoredType.name, equals('Arms'));
    });
  });

  group('ConditionalGarmentSectionWidget UI Verification', () {
    testWidgets('Renders collapsed state when isRequired is false', (tester) async {
      final typeCtrl = TextEditingController();
      final brandCtrl = TextEditingController();
      bool isRequired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ConditionalGarmentSectionWidget(
                  isRequired: isRequired,
                  onRequiredChanged: (val) => setState(() => isRequired = val),
                  typeController: typeCtrl,
                  brandModelController: brandCtrl,
                  typeSuggestions: const ['Abdomen', 'Chest'],
                  brandSuggestions: const ['Marena', 'VOE'],
                );
              },
            ),
          ),
        ),
      );

      // Header is visible
      expect(find.text('4/ Compression Garment'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Subfields are not visible when false
      expect(find.text('Garment Type / Area *'), findsNothing);
      expect(find.text('Brand / Manufacturer & Model *'), findsNothing);

      // Toggle Switch on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Now subfields expand and are visible, label is Yes
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Garment Type / Area *'), findsOneWidget);
      expect(find.text('Brand / Manufacturer & Model *'), findsOneWidget);

      // Toggle Switch off
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Subfields hide again
      expect(find.text('No'), findsOneWidget);
      expect(find.text('Garment Type / Area *'), findsNothing);
      expect(find.text('Brand / Manufacturer & Model *'), findsNothing);
    });

    testWidgets('Shows validation errors when required fields are empty and validation triggered', (tester) async {
      final typeCtrl = TextEditingController();
      final brandCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionalGarmentSectionWidget(
              isRequired: true,
              onRequiredChanged: (_) {},
              typeController: typeCtrl,
              brandModelController: brandCtrl,
              showValidationErrors: true,
            ),
          ),
        ),
      );

      expect(find.text('Please specify garment area / type'), findsOneWidget);
      expect(find.text('Please specify manufacturer & model'), findsOneWidget);
    });

    testWidgets('Tapping Add Type button opens dialog and saves to SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final typeCtrl = TextEditingController();
      final brandCtrl = TextEditingController();
      String? addedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionalGarmentSectionWidget(
              isRequired: true,
              onRequiredChanged: (_) {},
              typeController: typeCtrl,
              brandModelController: brandCtrl,
              onTypeAdded: (val) => addedType = val,
            ),
          ),
        ),
      );

      // Verify Add Type button is present
      expect(find.text('+ Add New Type'), findsOneWidget);

      // Tap + Add New Type
      await tester.tap(find.text('+ Add New Type'));
      await tester.pumpAndSettle();

      // Dialog is displayed
      expect(find.text('Add Garment Type'), findsOneWidget);
      expect(find.text('Save to Preferences'), findsOneWidget);

      // Enter new type
      await tester.enterText(find.widgetWithText(TextField, 'Garment Type *'), 'Upper Back Vest');
      await tester.tap(find.text('Save to Preferences'));
      await tester.pumpAndSettle();

      // Controller updated and callback fired
      expect(typeCtrl.text, equals('Upper Back Vest'));
      expect(addedType, equals('Upper Back Vest'));

      // Check SharedPreferences directly
      final savedTypes = await GarmentPreferencesService.getCustomTypes();
      expect(savedTypes, contains('Upper Back Vest'));
    });

    testWidgets('Tapping Add Brand button opens dialog and saves to SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final typeCtrl = TextEditingController();
      final brandCtrl = TextEditingController();
      String? addedBrand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConditionalGarmentSectionWidget(
              isRequired: true,
              onRequiredChanged: (_) {},
              typeController: typeCtrl,
              brandModelController: brandCtrl,
              onBrandAdded: (val) => addedBrand = val,
            ),
          ),
        ),
      );

      // Verify Add Brand button is present
      expect(find.text('+ Add New Brand / Model'), findsOneWidget);

      // Tap + Add New Brand / Model
      await tester.tap(find.text('+ Add New Brand / Model'));
      await tester.pumpAndSettle();

      // Dialog is displayed
      expect(find.text('Add Garment Brand / Model'), findsOneWidget);
      expect(find.text('Save to Preferences'), findsOneWidget);

      // Enter new brand
      await tester.enterText(find.widgetWithText(TextField, 'Brand / Model *'), 'SurgicalPro Lux');
      await tester.tap(find.text('Save to Preferences'));
      await tester.pumpAndSettle();

      // Controller updated and callback fired
      expect(brandCtrl.text, equals('SurgicalPro Lux'));
      expect(addedBrand, equals('SurgicalPro Lux'));

      // Check SharedPreferences directly
      final savedBrands = await GarmentPreferencesService.getCustomBrands();
      expect(savedBrands, contains('SurgicalPro Lux'));
    });
  });

  group('GarmentPreferencesService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Saves custom type and merges with defaults in English', () async {
      await GarmentPreferencesService.saveCustomType('Lower Body Suit');
      final custom = await GarmentPreferencesService.getCustomTypes();
      expect(custom, equals(['Lower Body Suit']));

      final all = await GarmentPreferencesService.getAllTypes();
      expect(all, contains('Lower Body Suit'));
      expect(all, contains('Abdomen'));
    });

    test('Saves custom brand and merges with defaults in English', () async {
      await GarmentPreferencesService.saveCustomBrand('BioForm Pro');
      final custom = await GarmentPreferencesService.getCustomBrands();
      expect(custom, equals(['BioForm Pro']));

      final all = await GarmentPreferencesService.getAllBrands();
      expect(all, contains('BioForm Pro'));
      expect(all, contains('Marena'));
    });
  });
}
