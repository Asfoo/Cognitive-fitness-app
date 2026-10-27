import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../models/summaries.dart';
import '../../common/buttons.dart';
import '../../common/surfaces.dart';

/// "You're 45% to your daily goal" card with the quick-start bolt.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.summary, required this.onQuickStart});

  final DashboardSummary summary;
  final VoidCallback onQuickStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final percent = (summary.goalProgress * 100).round();

    return SoftWell(
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  percent >= 100 ? 'Daily goal complete. Nice work!' : "You're $percent% to your daily goal",
                  style: text.titleLarge?.copyWith(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              AccentOrb(onPressed: onQuickStart, tooltip: 'Quick start'),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            height: 58,
            padding: const EdgeInsets.all(6),
            decoration: AppDecorations.well(radius: 29),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: summary.goalProgress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    // Keep a visible stub so the track reads as a slider even at 0%.
                    widthFactor: value.clamp(0.12, 1.0),
                    heightFactor: 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.all(Radius.circular(23)),
                        boxShadow: AppDecorations.softShadow,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text.rich(
                      TextSpan(
                        text: '${summary.testsToday}',
                        style: text.titleMedium,
                        children: [
                          TextSpan(
                            text: '/${summary.dailyGoal} tests',
                            style: text.titleMedium?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
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
