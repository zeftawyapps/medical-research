import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/research_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_layout.dart';
import '../../widgets/adaptive_form_modal.dart';
import '../../widgets/common_widgets.dart';

class SurveysSectionScreen extends StatefulWidget {
  const SurveysSectionScreen({super.key});

  @override
  State<SurveysSectionScreen> createState() => _SurveysSectionScreenState();
}

class _SurveysSectionScreenState extends State<SurveysSectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSurveyModal(BuildContext context, ResearchProvider provider) {
    if (provider.operations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an Operation first!')),
      );
      return;
    }

    String selectedOpId = provider.operations.first.operationId;
    String surveyType = 'Pain VAS Score';
    final q1Controller = TextEditingController(text: '3/10 (Mild)');
    final q2Controller = TextEditingController(text: 'Independent mobilization without assistance');

    showAdaptiveFormModal(
      context: context,
      title: 'Add Patient Evaluation Survey',
      icon: Icons.poll_rounded,
      iconColor: AppTheme.accentPurple,
      saveButtonText: 'Save Survey',
      formBuilder: (ctx, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedOpId,
              decoration: const InputDecoration(labelText: 'Select Operation (FK) *'),
              items: provider.operations.map((op) {
                final patient = provider.patients.where((p) => p.patientId == op.patientId).firstOrNull;
                return DropdownMenuItem(
                  value: op.operationId,
                  child: Text('${op.operationType} - ${patient?.name ?? 'Patient'}', overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setModalState(() => selectedOpId = val);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: surveyType,
              decoration: const InputDecoration(labelText: 'Survey / Questionnaire Type *'),
              items: const [
                DropdownMenuItem(value: 'Pain VAS Score', child: Text('Pain VAS Scale')),
                DropdownMenuItem(value: 'Quality of Life (EQ-5D)', child: Text('Quality of Life (EQ-5D)')),
                DropdownMenuItem(value: 'Seattle Angina SAQ-7', child: Text('Seattle Angina SAQ-7')),
                DropdownMenuItem(value: 'UPDRS Motor Score', child: Text('UPDRS Motor Score')),
              ],
              onChanged: (val) {
                if (val != null) setModalState(() => surveyType = val);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: q1Controller,
              decoration: const InputDecoration(labelText: 'Primary Evaluation Metric / Score *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: q2Controller,
              decoration: const InputDecoration(labelText: 'Functional / Recovery Observation *'),
            ),
          ],
        );
      },
      onSave: () async {
        await provider.addSurveyToCase(
          selectedOpId,
          surveyType,
          {
            'primary_score': q1Controller.text.trim(),
            'functional_note': q2Controller.text.trim(),
            'completed_date': DateTime.now().toIso8601String(),
          },
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Survey evaluation saved in SQLite!')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResearchProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveLayout.isMobile(context);

    final filteredSurveys = provider.surveys.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return s.surveyType.toLowerCase().contains(q) || s.evaluationQuestions.toString().toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.horizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '8. Patient Evaluation Surveys',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Patient-reported outcome measures (PROMs) and surveys.',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11.5 : 13,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddSurveyModal(context, provider),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(isMobile ? 'Add' : 'Add Survey'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          CustomSearchBar(
            controller: _searchController,
            hint: 'Search surveys by questionnaire type (e.g. Pain VAS)...',
            onChanged: (val) => setState(() => _query = val),
            onClear: () => setState(() => _query = ''),
          ),
          const SizedBox(height: 12),

          Text(
            'Total Surveys: ${filteredSurveys.length}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          if (filteredSurveys.isEmpty)
            const EmptyStateWidget(
              icon: Icons.poll_outlined,
              title: 'No Surveys Found',
              message: 'Click "Add Survey" above to record a patient questionnaire.',
            )
          else
            ...filteredSurveys.map((s) {
              final op = provider.operations.where((o) => o.operationId == s.operationId).firstOrNull;
              final patient = op != null ? provider.patients.where((pt) => pt.patientId == op.patientId).firstOrNull : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.poll_rounded, color: AppTheme.accentPurple, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              s.surveyType,
                              style: GoogleFonts.inter(fontSize: isMobile ? 14 : 15.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            if (patient != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentPurple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  patient.name,
                                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.accentPurple),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.alertRed, size: 18),
                          onPressed: () => provider.deleteSurvey(s.surveyId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...s.evaluationQuestions.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Text('• ${e.key}: ', style: GoogleFonts.inter(fontSize: isMobile ? 11.5 : 12.5, fontWeight: FontWeight.w600, color: AppTheme.primaryCyan)),
                            Expanded(
                              child: Text('${e.value}', style: GoogleFonts.inter(fontSize: isMobile ? 11.5 : 12.5, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
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
}
