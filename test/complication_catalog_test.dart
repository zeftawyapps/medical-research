import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/models/complication_catalog_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ComplicationCatalogModel', () {
    test('Model instantiation and toMap/fromMap serialization', () {
      final now = DateTime(2026, 9, 6);
      final model = ComplicationCatalogModel(
        id: 'cat-1',
        name: 'Seroma',
        treatment: 'Aspiration + compression dressing',
        grade: 'Grade I (Minor complication, no specific treatment required)',
        category: 'Wound',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map[ComplicationCatalogTable.columnId], 'cat-1');
      expect(map[ComplicationCatalogTable.columnName], 'Seroma');
      expect(map[ComplicationCatalogTable.columnTreatment],
          'Aspiration + compression dressing');
      expect(map[ComplicationCatalogTable.columnGrade],
          'Grade I (Minor complication, no specific treatment required)');
      expect(map[ComplicationCatalogTable.columnCategory], 'Wound');

      final reconstructed = ComplicationCatalogModel.fromMap(map);
      expect(reconstructed.id, model.id);
      expect(reconstructed.name, model.name);
      expect(reconstructed.treatment, model.treatment);
      expect(reconstructed.grade, model.grade);
      expect(reconstructed.category, model.category);
    });

    test('CopyWith updates fields properly', () {
      final model = ComplicationCatalogModel(
        id: 'cat-1',
        name: 'Seroma',
        treatment: 'Aspiration',
        createdAt: DateTime.now(),
      );

      final updated = model.copyWith(
        treatment: 'Aspiration + binder',
        grade: 'Grade II',
      );

      expect(updated.name, 'Seroma');
      expect(updated.treatment, 'Aspiration + binder');
      expect(updated.grade, 'Grade II');
    });
  });
}
