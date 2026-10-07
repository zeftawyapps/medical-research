import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/patient_record_brd.dart';
import '../../providers/research_provider.dart';
import '../data/countries_data.dart';
import '../../theme/app_theme.dart';

class ClinicalCaseDetailView extends StatefulWidget {
  final CompleteClinicalCase clinicalCase;
  final VoidCallback? onClose;

  const ClinicalCaseDetailView({
    super.key,
    required this.clinicalCase,
    this.onClose,
  });

  @override
  State<ClinicalCaseDetailView> createState() => _ClinicalCaseDetailViewState();
}

class _ClinicalCaseDetailViewState extends State<ClinicalCaseDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddComplicationDialog(BuildContext context, ResearchProvider provider) {
    final podController = TextEditingController(text: '1');
    final gradeController = TextEditingController(text: 'Clavien-Dindo Grade I');
    final mgmtController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Log Post-Op Complication', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: podController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Post-Op Day (POD) Number (e.g. 1, 3, 14)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: gradeController.text,
                  decoration: const InputDecoration(labelText: 'Clavien-Dindo Grade'),
                  items: const [
                    DropdownMenuItem(value: 'Clavien-Dindo Grade I', child: Text('Grade I (Minor/Conservative)')),
                    DropdownMenuItem(value: 'Clavien-Dindo Grade II', child: Text('Grade II (Pharmacological/POAF/ABX)')),
                    DropdownMenuItem(value: 'Clavien-Dindo Grade IIIa', child: Text('Grade IIIa (Intervention no GA)')),
                    DropdownMenuItem(value: 'Clavien-Dindo Grade IIIb', child: Text('Grade IIIb (Intervention under GA)')),
                    DropdownMenuItem(value: 'Clavien-Dindo Grade IV', child: Text('Grade IV (ICU/Organ Dysfunction)')),
                    DropdownMenuItem(value: 'Clavien-Dindo Grade V', child: Text('Grade V (Mortality)')),
                  ],
                  onChanged: (val) {
                    if (val != null) gradeController.text = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mgmtController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Management & Medical Intervention Approach',
                    hintText: 'e.g. IV diuretics, antibiotics, diagnostic thoracentesis...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final pod = int.tryParse(podController.text) ?? 1;
                provider.addComplicationToCase(
                  widget.clinicalCase.operation.operationId,
                  pod,
                  gradeController.text,
                  mgmtController.text,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Complication logged into SQLite database.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertAmber, foregroundColor: Colors.black),
              child: const Text('Save Complication'),
            ),
          ],
        );
      },
    );
  }

  void _showAddLabDialog(BuildContext context, ResearchProvider provider) {
    final testNameController = TextEditingController();
    final resultController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Record Digital Blood & Lab Test', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: testNameController,
                decoration: const InputDecoration(labelText: 'Test Name (e.g. Hemoglobin, Platelets, CRP, ALT)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resultController,
                decoration: const InputDecoration(labelText: 'Result Value with Unit (e.g. 13.8 g/dL, 12.4 mg/L)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (testNameController.text.isNotEmpty && resultController.text.isNotEmpty) {
                  provider.addBloodLabToCase(
                    widget.clinicalCase.operation.operationId,
                    testNameController.text,
                    resultController.text,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lab test recorded into SQLite.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.black),
              child: const Text('Add Lab Result'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patient = widget.clinicalCase.patient;
    final operation = widget.clinicalCase.operation;
    final formattedDate = DateFormat('MMMM dd, yyyy').format(operation.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        patient.medicalRecordNumber,
                        style: GoogleFonts.robotoMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy MRN',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: patient.medicalRecordNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied ${patient.medicalRecordNumber}!')),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.alertRed, size: 20),
                      tooltip: 'Delete Case from SQLite',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Clinical Record'),
                            content: const Text('Are you sure you want to permanently delete this surgical record from SQLite?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await provider.deleteCase(widget.clinicalCase);
                          if (widget.onClose != null) widget.onClose!();
                        }
                      },
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: widget.onClose,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Patient Summary Card
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        patient.name,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentIndigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (context) {
                    final countryObj = findCountry(patient.country);
                    final countryStr = countryObj != null
                        ? ' • Country: ${countryObj.flag} ${countryObj.nameEn}'
                        : (patient.country.isNotEmpty ? ' • Country: 🌐 ${patient.country}' : '');
                    final bloodStr = (patient.bloodGroup.isNotEmpty && patient.bloodGroup != 'N/A')
                        ? ' • Blood: ${patient.bloodGroup}'
                        : '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age: ${patient.age} yrs • Gender: ${patient.gender}$countryStr$bloodStr • Phone: ${patient.phone}',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        if (patient.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '📝 Notes: ${patient.notes}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROCEDURE & DIAGNOSIS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryCyan,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        operation.operationType,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        operation.diagnosisDetails,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      if (operation.hospital.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_hospital_rounded,
                              size: 13,
                              color: AppTheme.primaryTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              operation.hospital,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 6-Tab Bar for BRD Sections
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryCyan,
            labelColor: AppTheme.primaryCyan,
            unselectedLabelColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
            tabs: [
              const Tab(text: '1. Pre-Op'),
              const Tab(text: '2. Intra-Op'),
              const Tab(text: '3. Post-Op'),
              Tab(text: '4. Complications (${widget.clinicalCase.complications.length})'),
              Tab(text: '5. Blood Labs (${widget.clinicalCase.bloodLabs.length})'),
              Tab(text: '6. Surveys (${widget.clinicalCase.surveys.length})'),
            ],
          ),

          // Tab Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreOpTab(context, widget.clinicalCase.preOp, isDark),
                _buildIntraOpTab(context, widget.clinicalCase.intraOp, isDark),
                _buildPostOpTab(context, widget.clinicalCase.postOp, isDark),
                _buildComplicationsTab(context, widget.clinicalCase.complications, provider, isDark),
                _buildBloodLabsTab(context, widget.clinicalCase.bloodLabs, provider, isDark),
                _buildSurveysTab(context, widget.clinicalCase.surveys, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreOpTab(BuildContext context, PreOpModel? preOp, bool isDark) {
    if (preOp == null) {
      return const Center(child: Text('No pre-operative record available.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubHeader('Clinical Case Presentation'),
          const SizedBox(height: 6),
          Text(preOp.caseDescription, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
          const SizedBox(height: 18),

          _buildSubHeader('Radiology Reports (Text)'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(preOp.radiologyReports, style: GoogleFonts.inter(fontSize: 12.5, height: 1.4)),
          ),
          const SizedBox(height: 18),

          _buildSubHeader('Clinical & Radiology Image Attachments'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [...preOp.clinicalImages, ...preOp.radiologyImages].map((img) {
              return Container(
                width: 130,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_outlined, color: AppTheme.primaryCyan, size: 28),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        img.split('/').last,
                        style: GoogleFonts.inter(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIntraOpTab(BuildContext context, IntraOpModel? intraOp, bool isDark) {
    if (intraOp == null) {
      return const Center(child: Text('No intra-operative record available.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubHeader('Operative Surgical Procedure Description'),
          const SizedBox(height: 6),
          Text(intraOp.operationDescription, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
          const SizedBox(height: 18),

          _buildSubHeader('Intra-Operative Surgical Field Photos'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: intraOp.intraOpImages.map((img) {
              return Container(
                width: 140,
                height: 95,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: AppTheme.accentPurple, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      img.split('/').last,
                      style: GoogleFonts.inter(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostOpTab(BuildContext context, PostOpModel? postOp, bool isDark) {
    if (postOp == null) {
      return const Center(child: Text('No post-operative record available.'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubHeader('Post-Operative Progress & Clinical Evolution'),
          const SizedBox(height: 6),
          Text(postOp.postOpDescription, style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
          const SizedBox(height: 18),

          _buildSubHeader('Post-Op Wound & Recovery Photos'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: postOp.postOpImages.map((img) {
              return Container(
                width: 140,
                height: 95,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.healing_outlined, color: AppTheme.primaryTeal, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      img.split('/').last,
                      style: GoogleFonts.inter(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComplicationsTab(
    BuildContext context,
    List<ComplicationModel> complications,
    ResearchProvider provider,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubHeader('Complications Registry by Post-Op Day (POD)'),
              ElevatedButton.icon(
                onPressed: () => _showAddComplicationDialog(context, provider),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Log Complication'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.alertAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (complications.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No surgical or medical complications recorded for this procedure.',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryTeal),
                    ),
                  ),
                ],
              ),
            )
          else
            ...complications.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.alertAmber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.alertAmber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'POD ${c.podDay}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.alertAmber,
                            ),
                          ),
                        ),
                        Text(
                          c.grade,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Management: ${c.management}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBloodLabsTab(
    BuildContext context,
    List<BloodLabModel> bloodLabs,
    ResearchProvider provider,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSubHeader('Serial Blood & Lab Biomarkers (Digital Readings)'),
              ElevatedButton.icon(
                onPressed: () => _showAddLabDialog(context, provider),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Lab Result'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (bloodLabs.isEmpty)
            const Text('No digital lab results recorded yet.')
          else
            Table(
              border: TableBorder.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, borderRadius: BorderRadius.circular(8)),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground),
                  children: [
                    Padding(padding: const EdgeInsets.all(10), child: Text('TEST NAME', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('RESULT VALUE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700))),
                    Padding(padding: const EdgeInsets.all(10), child: Text('DATE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                ),
                ...bloodLabs.map((lab) {
                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(10), child: Text(lab.testName, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      Padding(padding: const EdgeInsets.all(10), child: Text(lab.resultValue, style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.primaryCyan, fontWeight: FontWeight.w700))),
                      Padding(padding: const EdgeInsets.all(10), child: Text(DateFormat('MM/dd').format(lab.testDate), style: GoogleFonts.inter(fontSize: 12))),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSurveysTab(BuildContext context, List<SurveyModel> surveys, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubHeader('Patient Evaluation Surveys & Outcome Measures'),
          const SizedBox(height: 14),

          if (surveys.isEmpty)
            const Text('No surveys completed yet for this surgical case.')
          else
            ...surveys.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_turned_in_rounded, size: 18, color: AppTheme.accentIndigo),
                        const SizedBox(width: 8),
                        Text(
                          s.surveyType,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.accentIndigo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...s.evaluationQuestions.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ${e.key.replaceAll('_', ' ')}: ', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Expanded(
                              child: Text(
                                e.value.toString(),
                                style: GoogleFonts.inter(fontSize: 12.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryCyan),
    );
  }
}
