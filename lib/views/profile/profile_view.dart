import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/results_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_settings.dart';
import '../../services/analytics_service.dart';
import '../common/buttons.dart';
import '../common/surfaces.dart';
import '../shell/main_shell.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final settingsController = context.watch<SettingsController>();
    final settings = settingsController.settings;
    final results = context.watch<ResultsController>().results;
    final streak = context.select<DashboardController, int>((c) => c.summary.streakDays);
    final best = const AnalyticsService().bestReaction(results);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, shellBottomInset),
        children: [
          Text('Profile', style: text.displaySmall),
          const SizedBox(height: 24),
          SoftWell(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _Stat(label: 'Sessions', value: '${results.length}'),
                const SizedBox(width: 10),
                _Stat(label: 'Best', value: best == null ? '–' : '${Format.ms(best)}ms'),
                const SizedBox(width: 10),
                _Stat(label: 'Streak', value: '${streak}d'),
              ],
            ),
          ),
          const SectionHeader('Goals'),
          SoftCard(
            child: Column(
              children: [
                _Stepper(
                  label: 'Daily goal',
                  description: 'Tests to complete each day',
                  value: '${settings.dailyGoal}',
                  onDecrement:
                      settings.dailyGoal > AppSettings.minGoal ? () => settingsController.changeDailyGoal(-1) : null,
                  onIncrement:
                      settings.dailyGoal < AppSettings.maxGoal ? () => settingsController.changeDailyGoal(1) : null,
                ),
                const Divider(height: 32, color: AppColors.well),
                _Stepper(
                  label: 'Reaction target',
                  description: 'Shown as the target line in reports',
                  value: '${settings.reactionTargetMs} ms',
                  onDecrement: settings.reactionTargetMs > AppSettings.minTargetMs
                      ? () => settingsController.changeReactionTarget(-1)
                      : null,
                  onIncrement: settings.reactionTargetMs < AppSettings.maxTargetMs
                      ? () => settingsController.changeReactionTarget(1)
                      : null,
                ),
              ],
            ),
          ),
          const SectionHeader('Data'),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.accent),
              title: Text('Clear test history', style: text.titleMedium),
              subtitle: Text('Removes all ${results.length} saved sessions', style: text.bodySmall),
              enabled: results.isNotEmpty,
              onTap: () => _confirmClear(context),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Cognitive Fitness · Assess your driving readiness',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('All saved test sessions will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<ResultsController>().clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        radius: 26,
        child: Column(
          children: [
            ValueWithUnit(value, size: 24),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.description,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String description;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.titleMedium),
              Text(description, style: text.bodySmall),
            ],
          ),
        ),
        CircleIconButton(icon: Icons.remove_rounded, size: 40, color: AppColors.well, onPressed: onDecrement),
        SizedBox(
          width: 76,
          child: Text(value, textAlign: TextAlign.center, style: text.titleMedium),
        ),
        CircleIconButton(icon: Icons.add_rounded, size: 40, color: AppColors.well, onPressed: onIncrement),
      ],
    );
  }
}
