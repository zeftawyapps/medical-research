import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/patient_model.dart';

/// Opens an optimized, responsive patient search dialog.
///
/// Fully theme-bound, designed to prevent RenderFlex overflow (overload)
/// on any screen size or when the soft keyboard is visible, and uses virtualized
/// lazy rendering to ensure lightning-fast performance without UI stutters.
void openPatientSearchDialog({
  required BuildContext context,
  required List<PatientModel> patients,
  required PatientModel? selectedPatient,
  required ValueChanged<PatientModel> onPatientSelected,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _PatientSearchDialogWidget(
      patients: patients,
      selectedPatient: selectedPatient,
      onPatientSelected: onPatientSelected,
    ),
  );
}

class _PatientSearchDialogWidget extends StatefulWidget {
  final List<PatientModel> patients;
  final PatientModel? selectedPatient;
  final ValueChanged<PatientModel> onPatientSelected;

  const _PatientSearchDialogWidget({
    required this.patients,
    required this.selectedPatient,
    required this.onPatientSelected,
  });

  @override
  State<_PatientSearchDialogWidget> createState() =>
      _PatientSearchDialogWidgetState();
}

class _PatientSearchDialogWidgetState
    extends State<_PatientSearchDialogWidget> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    // Responsive screen & keyboard handling to prevent ANY RenderFlex overload
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    final dialogWidth = math.min(520.0, screenWidth - 32.0);
    final availableHeight = screenHeight - keyboardHeight - 48.0;
    final dialogHeight = math.min(
      580.0,
      math.max(260.0, availableHeight * 0.9),
    );

    // Filter patients efficiently
    final query = _searchFilter.trim().toLowerCase();
    final results = query.isEmpty
        ? widget.patients
        : widget.patients.where((pat) {
            return pat.name.toLowerCase().contains(query) ||
                pat.medicalRecordNumber.toLowerCase().contains(query) ||
                pat.phone.toLowerCase().contains(query);
          }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.dialogTheme.backgroundColor ?? colorScheme.surface,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            // 1. Header Bar
            _buildHeader(context, theme, colorScheme, isDark, results.length, widget.patients.length),

            // 2. Search Box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                onChanged: (val) {
                  setState(() => _searchFilter = val);
                },
                decoration: InputDecoration(
                  hintText: 'Search by Name, MRN, or Phone...',
                  hintStyle: theme.inputDecorationTheme.hintStyle ??
                      TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  suffixIcon: _searchFilter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchFilter = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.primary.withValues(
                    alpha: isDark ? 0.08 : 0.04,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.8,
                    ),
                  ),
                  isDense: true,
                ),
              ),
            ),

            const Divider(height: 1),

            // 3. Results View (Virtualized, Lazy Loading - Zero Freezes)
            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState(theme, colorScheme, query)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        indent: 64,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, idx) {
                        final pat = results[idx];
                        final isSelected =
                            widget.selectedPatient?.patientId == pat.patientId;
                        return _buildPatientTile(
                          context,
                          theme,
                          colorScheme,
                          pat,
                          isSelected,
                          isDark,
                        );
                      },
                    ),
            ),

            const Divider(height: 1),

            // 4. Footer Bar
            _buildFooter(context, theme, colorScheme, results.length, widget.patients.length),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    int resultCount,
    int totalCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        border: Border(
          bottom: BorderSide(
            color: theme.dividerTheme.color ?? theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_search_rounded,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Select Patient',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ) ??
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              query.isEmpty
                  ? Icons.person_off_rounded
                  : Icons.search_off_rounded,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              query.isEmpty
                  ? 'No patients registered yet'
                  : 'No matching patients found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'No records matched "$query"',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchFilter = '');
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientTile(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    PatientModel pat,
    bool isSelected,
    bool isDark,
  ) {
    final initials = pat.name.trim().isNotEmpty
        ? pat.name.trim().substring(0, 1).toUpperCase()
        : 'P';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withValues(
        alpha: isDark ? 0.18 : 0.08,
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isSelected
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.15),
        child: isSelected
            ? Icon(Icons.check, size: 18, color: colorScheme.onPrimary)
            : Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.primary,
                ),
              ),
      ),
      title: Text(
        pat.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.18 : 0.08,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'MRN: ${pat.medicalRecordNumber}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Age: ${pat.age} yrs • Phone: ${pat.phone}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary, size: 20)
          : Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
      onTap: () {
        Navigator.pop(context);
        widget.onPatientSelected(pat);
      },
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    int resultCount,
    int totalCount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Showing $resultCount of $totalCount patient${totalCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
