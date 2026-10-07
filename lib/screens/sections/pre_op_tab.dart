import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/operation_model.dart';
import '../../models/patient_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/age_at_operation_badge.dart';
import '../../widgets/bmi_indicator_widget.dart';
import '../../widgets/medical_image_gallery_widget.dart';
import '../../widgets/conditional_garment_section_widget.dart';

class PreOpTab extends StatelessWidget {
  final OperationModel? selectedOperation;
  final PatientModel? selectedPatient;
  final DateTime opDate;
  final ValueChanged<DateTime> onOpDateChanged;
  final TextEditingController opTypeController;
  final TextEditingController opReasonController;
  final TextEditingController? hospitalController;
  final TextEditingController pastHistoryController;
  final TextEditingController occupationController;
  final bool isSmoker;
  final ValueChanged<bool> onSmokerChanged;
  final TextEditingController cigsPerDayController;
  final TextEditingController smokingYearsController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController hbController;
  final TextEditingController t3Controller;
  final TextEditingController t4Controller;
  final List<String> scanPictures;
  final ValueChanged<List<String>> onScanPicturesChanged;
  final List<String> preOpPictures;
  final ValueChanged<List<String>> onPreOpPicturesChanged;
  final TextEditingController opNotesController;
  final List<String> operativePictures;
  final ValueChanged<List<String>> onOperativePicturesChanged;
  final TextEditingController fatVolumeController;
  final String selectedCorset;
  final ValueChanged<String>? onCorsetChanged;
  final bool isGarmentRequired;
  final ValueChanged<bool>? onGarmentRequiredChanged;
  final TextEditingController? garmentTypeController;
  final TextEditingController? garmentBrandController;
  final List<String> garmentBrandSuggestions;
  final List<String> garmentTypeSuggestions;
  final ValueChanged<String>? onGarmentTypeAdded;
  final ValueChanged<String>? onGarmentBrandAdded;
  final bool showGarmentValidationErrors;
  final VoidCallback onSave;
  final VoidCallback onGoToOperations;
  final VoidCallback? onWeightHeightChanged;
  final bool isDark;

  const PreOpTab({
    super.key,
    required this.selectedOperation,
    required this.selectedPatient,
    required this.opDate,
    required this.onOpDateChanged,
    required this.opTypeController,
    required this.opReasonController,
    required this.pastHistoryController,
    required this.occupationController,
    required this.isSmoker,
    required this.onSmokerChanged,
    required this.cigsPerDayController,
    required this.smokingYearsController,
    required this.weightController,
    required this.heightController,
    required this.hbController,
    required this.t3Controller,
    required this.t4Controller,
    required this.scanPictures,
    required this.onScanPicturesChanged,
    required this.preOpPictures,
    required this.onPreOpPicturesChanged,
    required this.opNotesController,
    required this.operativePictures,
    required this.onOperativePicturesChanged,
    required this.fatVolumeController,
    this.selectedCorset = 'Abdominal Garment',
    this.onCorsetChanged,
    this.isGarmentRequired = false,
    this.onGarmentRequiredChanged,
    this.garmentTypeController,
    this.garmentBrandController,
    this.garmentBrandSuggestions = const [],
    this.garmentTypeSuggestions = const [],
    this.onGarmentTypeAdded,
    this.onGarmentBrandAdded,
    this.showGarmentValidationErrors = false,
    required this.onSave,
    required this.onGoToOperations,
    this.hospitalController,
    this.onWeightHeightChanged,
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
              const Icon(
                Icons.medical_services_outlined,
                size: 40,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'No Operation Selected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Please select an operation from the Operations tab, or add a new operation first.',
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

    final double? weight = double.tryParse(weightController.text);
    final double? height = double.tryParse(heightController.text);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Procedure Header Card with Age at Operation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.teal.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Heading alone
                const Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      color: Colors.teal,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Surgical Procedure Details & Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Line 2: Details / Badge alone
                AgeAtOperationBadge(
                  dateOfBirth: DateTime.tryParse(
                    selectedPatient?.dateOfBirth ?? '',
                  ),
                  operationDate: opDate,
                ),
                const SizedBox(height: 12),
                // Responsive Wrap for Procedure Type & Date
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 520;
                    final typeWidth = isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 14) * 0.65;
                    final dateWidth = isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 14) * 0.35;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: typeWidth,
                          child: TextField(
                            controller: opTypeController,
                            scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                            decoration: const InputDecoration(
                              labelText: 'Procedure Type *',
                              prefixIcon: Icon(Icons.healing),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: dateWidth,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: opDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                onOpDateChanged(picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date: ${DateFormat('yyyy-MM-dd').format(opDate)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month,
                                    color: Colors.teal,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: opReasonController,
                  maxLines: 2,
                  scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis Details & Clinical Indication',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1/ Past Medical History
          const Text(
            '1/ Past Medical & Surgical History (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: pastHistoryController,
            maxLines: 2,
            scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
            decoration: const InputDecoration(
              hintText:
                  'Previous surgeries, chronic conditions, allergies, medications...',
            ),
          ),
          const SizedBox(height: 16),

          // 2/ Occupation
          const Text(
            '2/ Occupation (Optional)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: occupationController,
            scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
            decoration: const InputDecoration(
              hintText: 'e.g., Field Engineer, Office Worker, Teacher...',
            ),
          ),
          const SizedBox(height: 16),

          // 3/ Smoker Switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.smoking_rooms, color: Colors.teal, size: 20),
                        SizedBox(width: 5),
                        Text(
                          '3/ Tobacco Smoker?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isSmoker,
                      activeThumbColor: Colors.teal,
                      onChanged: onSmokerChanged,
                    ),
                  ],
                ),
                if (isSmoker) ...[
                  const Divider(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = constraints.maxWidth < 450
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 14) / 2;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: TextField(
                              controller: cigsPerDayController,
                              keyboardType: TextInputType.number,
                              scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                              decoration: const InputDecoration(
                                labelText: 'Cigarettes per day',
                                prefixIcon: Icon(Icons.numbers),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: TextField(
                              controller: smokingYearsController,
                              keyboardType: TextInputType.number,
                              scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                              decoration: const InputDecoration(
                                labelText: 'Smoking years',
                                prefixIcon: Icon(Icons.timeline),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4/ Weight & 5/ Height with Automatic BMI (Responsive Wrap)
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 450
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                      decoration: const InputDecoration(
                        labelText: '4/ Weight (Kg)',
                        prefixIcon: Icon(Icons.scale_rounded),
                        suffixText: 'Kg',
                      ),
                      onChanged: (_) => onWeightHeightChanged?.call(),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: TextField(
                      controller: heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                      decoration: const InputDecoration(
                        labelText: '5/ Height (Metre)',
                        prefixIcon: Icon(Icons.height_rounded),
                        suffixText: 'm',
                      ),
                      onChanged: (_) => onWeightHeightChanged?.call(),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Automatic BMI Calculation Widget
          BmiIndicatorWidget(weightKg: weight, heightM: height),
          const SizedBox(height: 20),

          // 6/ Investigations: Hemoglobin, T3, T4 (Responsive Wrap)
          const Text(
            '6/ Laboratory Investigations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSingleCol = constraints.maxWidth < 500;
              final itemWidth = isSingleCol
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 20) / 3;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: TextField(
                      controller: hbController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                      decoration: const InputDecoration(
                        labelText: '6.a) Hemoglobin (Hb)',
                        suffixText: 'g/dL',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: TextField(
                      controller: t3Controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                      decoration: const InputDecoration(
                        labelText: '6.b) Triiodothyronine (T3)',
                        suffixText: 'ng/dL',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: TextField(
                      controller: t4Controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
                      decoration: const InputDecoration(
                        labelText: '6.c) Thyroxine (T4)',
                        suffixText: 'µg/dL',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // 6.d) Scan picture (Radiology / Scan Gallery)
          MedicalImageGalleryWidget(
            title: '6.d) Scan & Radiology',
            subtitle: 'CT, MRI & Imaging Pictures',
            initialImages: scanPictures,
            onImagesChanged: onScanPicturesChanged,
          ),
          const SizedBox(height: 20),

          // 7) Pre-operative picture
          MedicalImageGalleryWidget(
            title: '7) Pre-operative',
            subtitle: 'Clinical Patient Pictures',
            initialImages: preOpPictures,
            onImagesChanged: onPreOpPicturesChanged,
          ),
          const Divider(height: 40),

          // --- Operative details: ---
          const Text(
            'Operative Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 6),

          // Operation Name
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: opTypeController,
            builder: (context, value, _) {
              final opName = value.text.trim().isNotEmpty
                  ? value.text.trim()
                  : (selectedOperation?.operationType.trim().isNotEmpty == true
                      ? selectedOperation!.operationType.trim()
                      : '');
              return Row(
                children: [
                  const Icon(
                    Icons.medical_services_outlined,
                    size: 15,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      opName.isNotEmpty ? opName : 'Operation',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Hospital / Facility
          if (hospitalController != null) ...[
            TextField(
              controller: hospitalController,
              scrollPadding: ResponsiveLayout.textFieldScrollPadding(context),
              decoration: const InputDecoration(
                labelText: 'Hospital / Facility (Optional)',
                hintText: 'e.g. Royal Surgery Hospital, Al-Amal Clinic...',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 1/ Operative notes
          const Text(
            '1/ Operative Notes & Technique',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: opNotesController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText:
                  'Surgical technique, anesthesia, intra-operative findings, anatomical zones...',
            ),
          ),
          const SizedBox(height: 16),

          // 2/ Operative picture
          MedicalImageGalleryWidget(
            title: '2/ Operative Field',
            subtitle: 'Intra-Op Surgical Pictures',
            initialImages: operativePictures,
            onImagesChanged: onOperativePicturesChanged,
          ),
          const SizedBox(height: 16),

          // 3/ Amount of fat
          TextField(
            controller: fatVolumeController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: '3/ Amount of Fat Removed (Liters)',
              prefixIcon: Icon(Icons.water_drop_outlined),
              suffixText: 'Litre',
            ),
          ),
          const SizedBox(height: 18),

          // 4/ Compression Garment Section (Conditional Dynamic)
          if (garmentTypeController != null &&
              garmentBrandController != null &&
              onGarmentRequiredChanged != null)
            ConditionalGarmentSectionWidget(
              isRequired: isGarmentRequired,
              onRequiredChanged: onGarmentRequiredChanged!,
              typeController: garmentTypeController!,
              brandModelController: garmentBrandController!,
              typeSuggestions: garmentTypeSuggestions,
              brandSuggestions: garmentBrandSuggestions,
              onTypeAdded: onGarmentTypeAdded,
              onBrandAdded: onGarmentBrandAdded,
              isDark: isDark,
              showValidationErrors: showGarmentValidationErrors,
            ),
          const SizedBox(height: 28),

          // Save Button
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
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save Pre-Op & Operative Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
