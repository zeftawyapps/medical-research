import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medecat_research/widgets/medical_image_gallery_widget.dart';

/// ============================================================================
/// 🧪 MedicalImageGalleryWidget Test Suite (اختبارات معرض الصور الطبية السريرية)
/// 
/// تغطي هذه المجموعة:
/// 1. التحقق من عرض العنوان وعدد الصور وأزرار الكاميرا والمعرض وزر الإضافة [Add Image].
/// 2. اختبار حذف الصور من المعرض واستدعاء callback الخاص بالتحديث.
/// 3. اختبار الحالة الفارغة (Empty State) للمعرض وعرض خيارات الإضافة الفورية.
/// 4. اختبار عرض العنوان والوصف الفرعي الممتد (Two-line Title with Subtitle).
/// ============================================================================

void main() {
  group('MedicalImageGalleryWidget - UI & Interaction Tests', () {
    /// --------------------------------------------------------------------------
    /// 📋 Test 1:
    /// التحقق من عرض عناصر المعرض وأزرار الحذف وتحديث القائمة
    /// --------------------------------------------------------------------------
    testWidgets('MedicalImageGalleryWidget renders title, counter, and action buttons', (tester) async {
      List<String> images = ['test_image_1.png', 'test_image_2.png'];
      List<String>? updatedImages;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalImageGalleryWidget(
              title: 'Scan Pictures',
              initialImages: images,
              onImagesChanged: (list) => updatedImages = list,
            ),
          ),
        ),
      );

      // Title and counter
      expect(find.text('Scan Pictures'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Camera and Gallery buttons are present in the header
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // 'Add Image' add-more card
      expect(find.text('Add Image'), findsOneWidget);

      // Close / delete button for first item
      final closeButtons = find.byIcon(Icons.close);
      expect(closeButtons, findsNWidgets(2));

      // Tap first close button to remove
      await tester.tap(closeButtons.first);
      await tester.pump();

      // Verify callback was invoked and list reduced to 1
      expect(updatedImages, isNotNull);
      expect(updatedImages!.length, 1);
      expect(updatedImages!.first, 'test_image_2.png');
    });

    /// --------------------------------------------------------------------------
    /// 📋 Test 2:
    /// اختبار الحالة الفارغة للمعرض وظهور أزرار الإضافة السريعة (Take Photo & Choose from Gallery)
    /// --------------------------------------------------------------------------
    testWidgets('MedicalImageGalleryWidget empty state shows direct camera & gallery buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalImageGalleryWidget(
              title: 'Pre-Op Pictures',
              initialImages: const [],
              onImagesChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pre-Op Pictures'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Empty state buttons in English
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    /// --------------------------------------------------------------------------
    /// 📋 Test 3:
    /// اختبار عرض العنوان الرئيسي والوصف الفرعي
    /// --------------------------------------------------------------------------
    testWidgets('MedicalImageGalleryWidget displays two-line title with subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MedicalImageGalleryWidget(
              title: '6.d) Scan & Radiology',
              subtitle: 'CT, MRI & Imaging Pictures',
              initialImages: const [],
              onImagesChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('6.d) Scan & Radiology'), findsOneWidget);
      expect(find.text('CT, MRI & Imaging Pictures'), findsOneWidget);
    });
  });
}
