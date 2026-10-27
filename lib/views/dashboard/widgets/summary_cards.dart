import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/settings_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/summaries.dart';
import '../../../models/test_result.dart';
import '../../common/charts.dart';
import '../../common/surfaces.dart';

/// Horizontally scrolling stat cards with progress rings.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final targetMs = context.select<SettingsController, int>((c) => c.settings.reactionTargetMs);
    final reaction = summary.avgReactionMs;
    final cards = [
      _SummaryCard(
        label: 'Avg reaction',
        value: Format.ms(reaction),
        unit: reaction == null ? null : ' ms',
        // Full ring at or below target, empty at the "too slow" threshold.
        progress: reaction == null
            ? 0
            : ((TestResult.slowMs - reaction) / (TestResult.slowMs - targetMs)).clamp(0.0, 1.0),
      ),
      _SummaryCard(
        label: 'Accuracy',
        value: Format.percent(summary.accuracy),
        unit: summary.accuracy == null ? null : '%',
        progress: summary.accuracy ?? 0,
        color: AppColors.accent,
      ),
      _SummaryCard(
        label: 'Readiness',
        value: summary.readiness?.toString() ?? '–',
        unit: summary.readiness == null ? null : '/100',
        progress: (summary.readiness ?? 0) / 100,
      ),
      _SummaryCard(
        label: 'Streak',
        value: '${summary.streakDays}',
        unit: summary.streakDays == 1 ? ' day' : ' days',
        progress: (summary.streakDays / 7).clamp(0.0, 1.0),
        color: AppColors.accent,
      ),
      _SummaryCard(
        label: 'Training today',
        value: Format.duration(summary.trainingToday),
        progress: (summary.trainingToday.inSeconds / 300).clamp(0.0, 1.0),
      ),
    ];

    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.progress,
    this.unit,
    this.color = AppColors.ink,
  });

  final String label;
  final String value;
  final String? unit;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 236,
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  ValueWithUnit(value, unit: unit, size: 28),
                ],
              ),
            ),
            RingProgress(value: progress, size: 64, color: color),
          ],
        ),
      ),
    );
  }
}
