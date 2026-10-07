import 'package:flutter/material.dart';

/// Medical badge displaying patient's calculated age at the time of operation
class AgeAtOperationBadge extends StatelessWidget {
  final DateTime? dateOfBirth;
  final DateTime operationDate;

  const AgeAtOperationBadge({
    super.key,
    required this.dateOfBirth,
    required this.operationDate,
  });

  String get calculatedAgeString {
    if (dateOfBirth == null) return 'DOB not provided';

    int years = operationDate.year - dateOfBirth!.year;
    int months = operationDate.month - dateOfBirth!.month;
    int days = operationDate.day - dateOfBirth!.day;

    if (days < 0) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years < 0) return '0 yrs (invalid date)';

    if (months > 0) {
      return '$years yrs & $months mos';
    }
    return '$years yrs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDob = dateOfBirth != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasDob
            ? Colors.indigo.withValues(alpha: isDark ? 0.2 : 0.08)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasDob
              ? Colors.indigo.withValues(alpha: 0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Wrap(
        children: [
          Icon(
            Icons.cake_outlined,
            size: 18,
            color: hasDob ? Colors.indigo : Colors.grey,
          ),
          const SizedBox(width: 8),
          const Text(
            'Age at Operation:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            calculatedAgeString,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: hasDob
                  ? (isDark ? Colors.indigo.shade200 : Colors.indigo.shade800)
                  : Colors.grey,
            ),
          ),
          if (hasDob) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.shade600,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AUTO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
