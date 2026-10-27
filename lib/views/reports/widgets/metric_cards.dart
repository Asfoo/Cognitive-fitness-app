import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/summaries.dart';
import '../../common/charts.dart';
import '../../common/surfaces.dart';

/// Reaction (bar) and score (line) mini charts side by side, as in the design.
class MetricCards extends StatelessWidget {
  const MetricCards({super.key, required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final trend = summary.trend;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ChartCard(
              label: 'Reaction',
              value: Format.ms(summary.avgReactionMs),
              unit: summary.avgReactionMs == null ? null : 'ms',
              chart: MiniBarChart(values: [for (final p in trend) p.avgReactionMs]),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ChartCard(
              label: 'Score',
              value: summary.avgScore == null ? '–' : '${summary.avgScore!.round()}',
              unit: summary.avgScore == null ? null : '/100',
              chart: Sparkline(values: [for (final p in trend) p.avgScore]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.label, required this.value, required this.chart, this.unit});

  final String label;
  final String value;
  final String? unit;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          ValueWithUnit(value, unit: unit),
          const SizedBox(height: 18),
          chart,
        ],
      ),
    );
  }
}

/// 2×2 grid of secondary figures.
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final change = summary.reactionChange;
    final tiles = [
      _StatTile(
        icon: Icons.flash_on_rounded,
        label: 'Best reaction',
        value: summary.bestReactionMs == null ? '–' : '${Format.ms(summary.bestReactionMs)} ms',
      ),
      _StatTile(
        icon: Icons.swap_vert_rounded,
        label: 'vs last ${summary.period.noun}',
        value: change == null ? '–' : Format.signedPercent(change),
        valueColor: change == null
            ? null
            : change <= 0
                ? AppColors.positive
                : AppColors.accent,
      ),
      _StatTile(
        icon: Icons.straighten_rounded,
        label: 'Consistency',
        value: summary.consistencyMs == null ? '–' : '±${Format.ms(summary.consistencyMs)} ms',
      ),
      _StatTile(
        icon: Icons.timer_outlined,
        label: 'Training time',
        value: Format.duration(summary.trainingTime),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [for (final tile in tiles) SizedBox(width: width, child: tile)],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.well, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  value,
                  style: text.titleMedium?.copyWith(color: valueColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
