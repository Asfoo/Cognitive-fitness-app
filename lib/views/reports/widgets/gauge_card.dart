import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/summaries.dart';
import '../../common/charts.dart';
import '../../common/surfaces.dart';

/// Dual arc gauge (accuracy / sessions vs goal) with its legend card.
class GaugeCard extends StatelessWidget {
  const GaugeCard({super.key, required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return SoftWell(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 210,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
                child: DualArcGauge(outer: summary.isEmpty ? 0 : summary.accuracy, inner: summary.goalProgress),
              ),
            ),
            Expanded(
              child: SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Legend(
                      color: AppColors.accent,
                      label: 'Accuracy',
                      value: summary.isEmpty ? '–' : Format.percent(summary.accuracy),
                      unit: summary.isEmpty ? null : '/100%',
                    ),
                    _Legend(
                      color: AppColors.ink,
                      label: 'Sessions',
                      value: '${summary.totalTests}',
                      unit: '/${summary.goalTests}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value, this.unit});

  final Color color;
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: ValueWithUnit(value, unit: unit, size: 24),
        ),
      ],
    );
  }
}
