import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/report_period.dart';
import '../../../models/summaries.dart';
import '../../common/surfaces.dart';

/// Reaction-time trend over the period with the personal target line.
class TrendChartCard extends StatelessWidget {
  const TrendChartCard({super.key, required this.summary, required this.targetMs});

  final ReportSummary summary;
  final int targetMs;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final spots = [
      for (final (i, p) in summary.trend.indexed)
        if (p.avgReactionMs != null) FlSpot(i.toDouble(), p.avgReactionMs!),
    ];
    final change = summary.reactionChange;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Reaction trend', style: text.titleMedium)),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (change <= 0 ? AppColors.positive : AppColors.accent).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Format.signedPercent(change),
                    style: text.labelLarge?.copyWith(color: change <= 0 ? AppColors.positive : AppColors.accent),
                  ),
                ),
            ],
          ),
          Text('Average ms per ${_bucketNoun(summary.period)} · lower is better', style: text.bodySmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 190,
            child: spots.isEmpty
                ? Center(child: Text('Complete a test to see your trend', style: text.bodyMedium))
                : _chart(context, spots),
          ),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context, List<FlSpot> spots) {
    final labelStyle = Theme.of(context).textTheme.bodySmall!;
    final values = [...spots.map((s) => s.y), targetMs.toDouble()];
    final maxY = (values.reduce(math.max) * 1.15 / 100).ceil() * 100.0;
    final minY = math.max(0.0, (values.reduce(math.min) * 0.8 / 100).floor() * 100.0);
    final labelEvery = switch (summary.period) {
      ReportPeriod.daily => 2,
      ReportPeriod.weekly => 1,
      ReportPeriod.monthly => 5,
    };

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (summary.trend.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.well, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(value.round().toString(), style: labelStyle),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= summary.trend.length || i % labelEvery != 0) return const SizedBox.shrink();
                return SideTitleWidget(meta: meta, child: Text(summary.trend[i].label, style: labelStyle));
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetMs.toDouble(),
              color: AppColors.accent.withValues(alpha: 0.7),
              strokeWidth: 1.5,
              dashArray: [6, 6],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: labelStyle.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                labelResolver: (_) => 'target',
              ),
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            tooltipBorderRadius: BorderRadius.circular(12),
            getTooltipItems: (touched) => [
              for (final s in touched)
                LineTooltipItem(
                  '${summary.trend[s.x.toInt()].label}\n${s.y.round()} ms',
                  labelStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 2,
            preventCurveOverShooting: true,
            color: AppColors.ink,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.surface,
                strokeWidth: 2.5,
                strokeColor: AppColors.ink,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.ink.withValues(alpha: 0.12), AppColors.ink.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  static String _bucketNoun(ReportPeriod period) => period == ReportPeriod.daily ? '3 hours' : 'day';
}
