import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/responsive_layout.dart';

Future<T?> showAdaptiveFormModal<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Color iconColor,
  required Widget Function(BuildContext context, StateSetter setModalState) formBuilder,
  required Future<void> Function() onSave,
  String saveButtonText = 'Save Record',
}) {
  final isMobileOrCompact = ResponsiveLayout.isMobileOrLandscape(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (isMobileOrCompact) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final mediaQuery = MediaQuery.of(ctx);
            final isLandscape = mediaQuery.orientation == Orientation.landscape;
            final isCompactHeight = mediaQuery.size.height < 550;
            final bottomInset = mediaQuery.viewInsets.bottom;
            final bottomPadding = mediaQuery.viewPadding.bottom;
            final isKeyboardOpen = bottomInset > 0;
            final availableHeight = mediaQuery.size.height - bottomInset;

            // In landscape with keyboard open, maximize available vertical space above keyboard
            final maxSheetHeight = (isLandscape || isCompactHeight)
                ? (isKeyboardOpen ? availableHeight - 4 : mediaQuery.size.height * 0.94)
                : (availableHeight * 0.88);

            final isUltraCompact = (isLandscape || isCompactHeight) && isKeyboardOpen;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: math.max(120.0, maxSheetHeight),
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Header Section: Compact in landscape keyboard mode like WhatsApp
                    if (isUltraCompact)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Row(
                          children: [
                            Icon(icon, color: iconColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Quick Save Action right in the header bar
                            ElevatedButton.icon(
                              onPressed: () async {
                                await onSave();
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 16),
                              label: Text(
                                saveButtonText,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryCyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Drag Handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white30 : Colors.black26,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Header Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: iconColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(icon, color: iconColor, size: 19),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.inter(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : AppTheme.lightTextPrimary,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'SQLite Clinical Record Entry',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Material(
                                  color: isDark ? AppTheme.darkSurface : AppTheme.lightBorder.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(20),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => Navigator.pop(ctx),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.close_rounded, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder.withValues(alpha: 0.6),
                    ),

                    // Scrollable Form Body with WhatsApp-like keyboard avoidance
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.symmetric(
                          horizontal: isUltraCompact ? 14 : 18,
                          vertical: isUltraCompact ? 8 : 14,
                        ),
                        child: formBuilder(ctx, setModalState),
                      ),
                    ),

                    // Bottom Action Bar: hidden in landscape keyboard mode so text fields have full vertical room
                    if (!isUltraCompact)
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          10,
                          18,
                          math.max(12.0, bottomPadding + 6.0),
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
                          border: Border(
                            top: BorderSide(
                              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await onSave();
                                },
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: Text(
                                  saveButtonText,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryCyan,
                                  foregroundColor: Colors.black,
                                  elevation: 2,
                                  shadowColor: AppTheme.primaryCyan.withValues(alpha: 0.4),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } else {
    // Large Desktop / Widescreen Dialog
    return showDialog<T>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final mediaQuery = MediaQuery.of(ctx);
            final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;
            final isCompactHeight = mediaQuery.size.height < 600;

            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              insetPadding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isKeyboardOpen ? 6 : (isCompactHeight ? 12 : 24),
              ),
              titlePadding: EdgeInsets.fromLTRB(20, isCompactHeight ? 12 : 18, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              actionsPadding: EdgeInsets.fromLTRB(20, 10, 20, isCompactHeight ? 12 : 18),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(fontSize: 16.5, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'SQLite Local Storage Registry',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: formBuilder(ctx, setDialogState),
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await onSave();
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(
                    saveButtonText,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    shadowColor: AppTheme.primaryCyan.withValues(alpha: 0.3),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
