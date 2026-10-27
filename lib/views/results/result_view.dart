import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/results_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/summaries.dart';
import '../../models/test_result.dart';
import '../../services/analytics_service.dart';
import '../common/buttons.dart';
import '../common/charts.dart';
import '../common/surfaces.dart';
import '../tests/test_routes.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.result, this.fromHistory = false});

  final TestResult result;

  /// Opened from a history list rather than straight after a test.
  final bool fromHistory;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final comparison = const AnalyticsService().compare(result, context.read<ResultsController>().results);
    final targetMs = context.read<SettingsController>().settings.reactionTargetMs;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: fromHistory ? Icons.arrow_back_rounded : Icons.close_rounded,
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(child: Text(result.type.title, textAlign: TextAlign.center, style: text.titleLarge)),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: RingProgress(
                value: result.score / 100,
                size: 196,
                strokeWidth: 16,
                color: AppColors.accent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${result.score}', style: text.displayMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('score', style: text.titleMedium?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(_headline(result.score), textAlign: TextAlign.center, style: text.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${result.timestamp.dayLabel} · ${result.timestamp.timeLabel}',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            if (comparison.avgScore != null) ...[
              const SizedBox(height: 14),
              Center(child: _DeltaChip(delta: result.score - comparison.avgScore!)),
            ],
            const SizedBox(height: 28),
            _MetricsGrid(result: result),
            if (result.reactionMs != null) ...[
              const SizedBox(height: 16),
              _ReactionComparison(result: result, comparison: comparison, targetMs: targetMs),
            ],
            const SizedBox(height: 28),
            if (fromHistory)
              PillButton(
                label: 'Practice again',
                expand: true,
                onPressed: () => TestRoutes.replaceWith(context, result.type),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Retake',
                      style: PillStyle.light,
                      icon: Icons.replay_rounded,
                      onPressed: () => TestRoutes.replaceWith(context, result.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PillButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _headline(int score) {
    if (score >= 80) return 'Outstanding focus!';
    if (score >= 60) return 'Solid performance';
    if (score >= 40) return 'Room to grow';
    return 'Keep practicing';
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final up = delta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (up ? AppColors.positive : AppColors.accent).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${up ? '+' : '−'}${delta.abs().round()} vs your average',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: up ? AppColors.positive : AppColors.accent),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.result});

  final TestResult result;

  @override
  Widget build(BuildContext context) {
    final tiles = <(String, String, String?)>[
      if (result.reactionMs != null) ('Avg reaction', Format.ms(result.reactionMs), 'ms'),
      if (result.tapIntervalMs != null) ('Tap interval', Format.ms(result.tapIntervalMs), 'ms'),
      if (result.variabilityMs != null) ('Consistency', '±${Format.ms(result.variabilityMs)}', 'ms'),
      ('Accuracy', Format.percent(result.accuracy), '%'),
      ('Errors', '${result.errors}', '/${result.attempts}'),
      if (result.hasMath) ('Math', result.isMathCorrect ? 'Correct' : '${result.mathAnswer ?? '–'}', null),
      if (result.hasMath && !result.isMathCorrect) ('Answer was', '${result.correctAnswer}', null),
      ('Duration', Format.duration(result.duration), null),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final (label, value, unit) in tiles)
              SizedBox(
                width: width,
                child: SoftCard(
                  padding: const EdgeInsets.all(18),
                  radius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted)),
                      const SizedBox(height: 6),
                      ValueWithUnit(value, unit: unit, size: 24),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReactionComparison extends StatelessWidget {
  const _ReactionComparison({required this.result, required this.comparison, required this.targetMs});

  final TestResult result;
  final ResultComparison comparison;
  final int targetMs;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = <(String, double, Color)>[
      ('This session', result.reactionMs!, AppColors.accent),
      if (comparison.avgReactionMs != null) ('Your average', comparison.avgReactionMs!, AppColors.ink),
      ('Target', targetMs.toDouble(), AppColors.muted),
    ];
    final maxValue = rows.map((r) => r.$2).reduce((a, b) => a > b ? a : b);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reaction time (lower is better)', style: text.titleMedium),
          const SizedBox(height: 16),
          for (final (label, value, color) in rows) ...[
            Row(
              children: [
                Expanded(child: Text(label, style: text.bodyMedium)),
                Text('${value.round()} ms', style: text.labelLarge),
              ],
            ),
            const SizedBox(height: 6),
            ProgressBar(value: value / maxValue, color: color),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}
