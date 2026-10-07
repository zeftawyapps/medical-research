import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/patient_record_brd.dart';
import '../providers/research_provider.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';
import '../widgets/adaptive_form_modal.dart';
import '../widgets/common_widgets.dart';

class ResearchAbstractsScreen extends StatefulWidget {
  const ResearchAbstractsScreen({super.key});

  @override
  State<ResearchAbstractsScreen> createState() =>
      _ResearchAbstractsScreenState();
}

class _ResearchAbstractsScreenState extends State<ResearchAbstractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateTemplateModal(
    BuildContext context,
    ResearchProvider provider,
  ) {
    final nameController = TextEditingController();
    final List<TemplateField> fields = [
      const TemplateField(
        fieldName: 'Histological Subtype',
        fieldType: 'String',
      ),
      const TemplateField(
        fieldName: 'Resection Margin Width (mm)',
        fieldType: 'Number',
      ),
      const TemplateField(
        fieldName: 'Lymph Nodes Examined',
        fieldType: 'Number',
      ),
    ];

    showAdaptiveFormModal(
      context: context,
      title: 'New Dynamic Research Template',
      icon: Icons.schema_rounded,
      iconColor: AppTheme.accentIndigo,
      saveButtonText: 'Save Template',
      formBuilder: (ctx, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g. Hepatic Resection Margins Protocol',
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Template Custom Fields:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ...fields.asMap().entries.map((entry) {
              final idx = entry.key;
              final f = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '• ${f.fieldName} (${f.fieldType})',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppTheme.alertRed,
                      ),
                      onPressed: () {
                        setModalState(() => fields.removeAt(idx));
                      },
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () {
                setModalState(() {
                  fields.add(
                    TemplateField(
                      fieldName: 'Custom Field ${fields.length + 1}',
                      fieldType: 'String',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Field'),
            ),
          ],
        );
      },
      onSave: () async {
        if (nameController.text.isNotEmpty) {
          await provider.createTemplate(nameController.text.trim(), fields);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dynamic research template created!'),
              ),
            );
          }
        }
      },
    );
  }

  void _showGenerateAbstractModal(
    BuildContext context,
    ResearchProvider provider,
  ) {
    final titleController = TextEditingController(
      text:
          'Comparative Outcomes & Complication Profile in ${provider.timeFrameFilteredCases.length} Surgical Research Cases',
    );

    showAdaptiveFormModal(
      context: context,
      title: 'Generate Research Abstract',
      icon: Icons.auto_awesome_rounded,
      iconColor: AppTheme.primaryCyan,
      saveButtonText: 'Synthesize & Save',
      formBuilder: (ctx, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto-synthesize Background, Methods, Complication Rates, and Conclusions from currently filtered cases (${provider.timeFrameFilteredCases.length} records).',
              style: GoogleFonts.inter(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Abstract Title'),
            ),
          ],
        );
      },
      onSave: () async {
        final generated = await provider.generateAbstractFromCases(
          provider.timeFrameFilteredCases,
          titleController.text.trim(),
        );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Abstract "${generated.abstractTitle}" generated!'),
            ),
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.horizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar: Strict 3-line pattern
          // Line 1: Heading alone
          Text(
            'Dynamic Templates & Abstracts',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Line 2: Details alone
          Text(
            'Build custom schemas and synthesize structured Markdown abstracts.',
            style: GoogleFonts.inter(
              fontSize: isMobile ? 12 : 13,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Line 3: Action Buttons alone
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    _showCreateTemplateModal(context, provider),
                icon: const Icon(Icons.schema_rounded, size: 15),
                label: Text(isMobile ? 'Template' : 'New Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentIndigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 9,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    _showGenerateAbstractModal(context, provider),
                icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                label: Text(isMobile ? 'Synthesize' : 'Auto-Generate Abstract'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppTheme.primaryCyan,
            labelColor: AppTheme.primaryCyan,
            unselectedLabelColor: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            tabs: [
              Tab(text: 'Abstracts (${provider.abstracts.length})'),
              Tab(text: 'Templates (${provider.templates.length})'),
            ],
          ),
          const SizedBox(height: 12),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAbstractsTab(context, provider, isDark, isMobile),
                _buildTemplatesTab(context, provider, isDark, isMobile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbstractsTab(
    BuildContext context,
    ResearchProvider provider,
    bool isDark,
    bool isMobile,
  ) {
    if (provider.abstracts.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.article_outlined,
        title: 'No Research Abstracts Yet',
        message:
            'Click "Auto-Generate" above to synthesize an abstract from your clinical cases.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.abstracts.length,
      itemBuilder: (context, idx) {
        final abst = provider.abstracts[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SYNTHESIZED ABSTRACT',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, yyyy').format(abst.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        tooltip: 'Copy Full Abstract Markdown',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: abst.abstractText),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Abstract copied to clipboard!'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.alertRed,
                          size: 17,
                        ),
                        onPressed: () =>
                            provider.deleteAbstract(abst.abstractId),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                abst.abstractTitle,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14.5 : 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF090D16)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: SelectableText(
                  abst.abstractText,
                  style: GoogleFonts.robotoMono(
                    fontSize: isMobile ? 11 : 12,
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplatesTab(
    BuildContext context,
    ResearchProvider provider,
    bool isDark,
    bool isMobile,
  ) {
    if (provider.templates.length <= 1) {
      // Empty or only default
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.templates.length,
      itemBuilder: (context, idx) {
        final t = provider.templates[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.schema_rounded,
                        color: AppTheme.accentIndigo,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t.templateName,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentIndigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${t.fields.length} Fields',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentIndigo,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: t.fields.map((f) {
                  return Chip(
                    label: Text('${f.fieldName} (${f.fieldType})'),
                    backgroundColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                    labelStyle: GoogleFonts.inter(
                      fontSize: isMobile ? 10.5 : 11.5,
                    ),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
