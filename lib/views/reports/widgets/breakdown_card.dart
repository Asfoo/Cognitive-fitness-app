import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/summaries.dart';
import '../../common/charts.dart';
import '../../common/surfaces.dart';
import '../../common/test_type_style.dart';

/// Sessions and average score per test type.
class BreakdownCard extends StatelessWidget {
  const BreakdownCard({super.key, required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maxCount = summary.breakdown.fold<int>(0, (m, b) => b.count > m ? b.count : m);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By test', style: text.titleMedium),
          Text('Sessions and average score', style: text.bodySmall),
          const SizedBox(height: 16),
          for (final row in summary.breakdown)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Icon(row.type.icon, size: 20, color: row.count == 0 ? AppColors.muted : AppColors.ink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(row.type.shortTitle, style: text.bodyMedium)),
                            Text(
                              row.count == 0 ? 'No sessions' : '${row.count}× · ${row.avgScore!.round()} pts',
                              style: text.labelLarge?.copyWith(
                                color: row.count == 0 ? AppColors.muted : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ProgressBar(
                          value: maxCount == 0 ? 0 : row.count / maxCount,
                          color: row == summary.breakdown.first && row.count > 0 ? AppColors.accent : AppColors.ink,
                          height: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
