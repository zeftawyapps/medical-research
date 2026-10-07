import 'package:flutter/material.dart';

/// Digital medical badge displaying calculated Post-Operative Day (POD)
class PodCalculatorBadge extends StatelessWidget {
  final DateTime operationDate;
  final DateTime evaluationDate;

  const PodCalculatorBadge({
    super.key,
    required this.operationDate,
    required this.evaluationDate,
  });

  int get podDays {
    final opZero = DateTime(operationDate.year, operationDate.month, operationDate.day);
    final evalZero = DateTime(evaluationDate.year, evaluationDate.month, evaluationDate.day);
    final diff = evalZero.difference(opZero).inDays;
    return diff >= 0 ? diff : 0;
  }

  @override
  Widget build(BuildContext context) {
    final pod = podDays;
    final isImmediate = pod <= 3;
    final isEarly = pod > 3 && pod <= 14;

    final badgeColor = isImmediate
        ? Colors.amber.shade800
        : (isEarly ? Colors.teal.shade700 : Colors.purple.shade700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_repeat_rounded, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            'POD: $pod',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(Day $pod Post-Op)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
