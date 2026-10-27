import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/reports_controller.dart';
import '../../models/report_period.dart';
import '../common/result_tile.dart';
import '../common/segmented_tabs.dart';
import '../common/surfaces.dart';
import '../shell/main_shell.dart';
import '../tests/test_routes.dart';
import 'widgets/breakdown_card.dart';
import 'widgets/gauge_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/metric_cards.dart';
import 'widgets/trend_chart_card.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final summary = controller.summary;
    final history = controller.historyExpanded
        ? summary.results
        : summary.results.take(ReportsController.collapsedHistoryLength).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, shellBottomInset),
        children: [
          SegmentedTabs<ReportPeriod>(
            values: ReportPeriod.values,
            selected: controller.period,
            labelOf: (p) => p.label,
            onChanged: controller.selectPeriod,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: controller.showInsight
                ? Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: InsightCard(
                      insight: summary.insight,
                      onDismiss: controller.dismissInsight,
                      onAction: () => TestRoutes.open(context, controller.suggestedTest),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 20),
          GaugeCard(summary: summary),
          const SizedBox(height: 16),
          MetricCards(summary: summary),
          const SizedBox(height: 16),
          TrendChartCard(summary: summary, targetMs: controller.reactionTargetMs),
          const SizedBox(height: 16),
          StatsGrid(summary: summary),
          const SizedBox(height: 16),
          BreakdownCard(summary: summary),
          SectionHeader(
            'Sessions',
            action: summary.results.length > ReportsController.collapsedHistoryLength
                ? TextButton(
                    onPressed: controller.toggleHistory,
                    child: Text(controller.historyExpanded ? 'Show less' : 'Show all ${summary.totalTests}'),
                  )
                : null,
          ),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: history.isEmpty
                ? EmptyHint(
                    icon: Icons.history_rounded,
                    message: 'No sessions this ${summary.period.noun}.',
                  )
                : Column(children: [for (final r in history) ResultTile(result: r, now: controller.now)]),
          ),
        ],
      ),
    );
  }
}
