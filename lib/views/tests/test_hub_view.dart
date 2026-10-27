import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/test_type.dart';
import '../common/buttons.dart';
import '../common/surfaces.dart';
import '../common/test_type_style.dart';
import '../shell/main_shell.dart';
import 'test_routes.dart';

/// "Train" tab: every available test, grouped.
class TestHubView extends StatelessWidget {
  const TestHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final suggested = context.select<DashboardController, TestType>((c) => c.suggestedTest);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, shellBottomInset),
        children: [
          Text('Train your\nfocus', style: text.displaySmall),
          const SizedBox(height: 24),
          _SuggestedCard(type: suggested),
          const SectionHeader('Core tests'),
          for (final type in TestType.values.where((t) => !t.isBiofeedback)) _TestCard(type: type),
          const SectionHeader('Biofeedback'),
          for (final type in TestType.values.where((t) => t.isBiofeedback)) _TestCard(type: type),
        ],
      ),
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({required this.type});

  final TestType type;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      color: AppColors.accent,
      padding: const EdgeInsets.all(24),
      onTap: () => TestRoutes.open(context, type),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggested next', style: text.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(type.title, style: text.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(type.description, style: text.bodyMedium?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleIconButton(
            icon: Icons.play_arrow_rounded,
            iconColor: AppColors.accent,
            size: 56,
            onPressed: () => TestRoutes.open(context, type),
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.type});

  final TestType type;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(16),
        radius: 28,
        onTap: () => TestRoutes.open(context, type),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.well, shape: BoxShape.circle),
              child: Icon(type.icon, color: AppColors.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.title, style: text.titleMedium),
                  const SizedBox(height: 2),
                  Text(type.description, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('~${type.estimatedSeconds}s', style: text.labelLarge?.copyWith(color: AppColors.muted)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
