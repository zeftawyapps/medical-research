import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/complication_model.dart';
import '../../models/operation_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/complications_list_widget.dart';
import '../../widgets/medical_image_gallery_widget.dart';

class PostOpTab extends StatelessWidget {
  final OperationModel? selectedOperation;
  final DateTime opDate;
  final List<ComplicationModel> operationComplications;
  final ValueChanged<ComplicationModel> onAddComplication;
  final ValueChanged<String> onDeleteComplication;
  final TextEditingController postOpNotesController;
  final List<String> postOpPictures;
  final ValueChanged<List<String>> onPostOpPicturesChanged;
  final VoidCallback onSavePostOp;
  final VoidCallback onGoToOperations;
  final bool isDark;

  const PostOpTab({
    super.key,
    required this.selectedOperation,
    required this.opDate,
    required this.operationComplications,
    required this.onAddComplication,
    required this.onDeleteComplication,
    required this.postOpNotesController,
    required this.postOpPictures,
    required this.onPostOpPicturesChanged,
    required this.onSavePostOp,
    required this.onGoToOperations,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedOperation == null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.healing_outlined, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'No Operation Selected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please select an operation from the Operations tab to track complications and recovery.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onGoToOperations,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Go to Operations Tab'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Reference Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Timeline reference: Operation Date is ${DateFormat('yyyy-MM-dd').format(opDate)}. Post Operative Day (POD) is computed automatically for each complication.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.amber.shade200
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1/ Complications as a separate list
          ComplicationsListWidget(
            operationDate: opDate,
            complications: operationComplications,
            onAddComplication: onAddComplication,
            onDeleteComplication: onDeleteComplication,
          ),
          const Divider(height: 36),

          // Recovery Notes
          const Text(
            'Post-Operative Progression & Recovery Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: postOpNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Recovery course, wound healing, garment compliance, analgesia...',
            ),
          ),
          const SizedBox(height: 20),

          // Post-Op Pictures
          MedicalImageGalleryWidget(
            title: 'Post-operative Recovery',
            subtitle: 'Follow-up & Healing Pictures',
            initialImages: postOpPictures,
            onImagesChanged: onPostOpPicturesChanged,
          ),
          const SizedBox(height: 28),

          // Save Follow-Up Button
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onSavePostOp,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save Post-Operative Follow-Up',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
