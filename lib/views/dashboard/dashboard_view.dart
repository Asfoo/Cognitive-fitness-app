import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/test_type.dart';
import '../coach/coach_view.dart';
import '../common/buttons.dart';
import '../common/result_tile.dart';
import '../common/surfaces.dart';
import '../shell/main_shell.dart';
import '../tests/test_routes.dart';
import 'widgets/goal_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/summary_cards.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();
    final summary = controller.summary;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, shellBottomInset),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(controller.today.dayLabel, style: text.titleMedium?.copyWith(color: AppColors.muted)),
              ),
              CircleIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                tooltip: 'Coach',
                size: 44,
                onPressed: () => CoachView.open(context),
              ),
            ],
          ),
          const SizedBox(height: 36),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              controller.greeting,
              key: ValueKey(controller.greeting),
              textAlign: TextAlign.center,
              style: text.displaySmall,
            ),
          ),
          const SizedBox(height: 40),
          GoalCard(
            summary: summary,
            onQuickStart: () => TestRoutes.open(context, controller.suggestedTest),
          ),
          const SizedBox(height: 20),
          QuickActions(
            actions: [
              QuickAction(
                icon: Icons.touch_app_rounded,
                label: 'Reaction',
                onTap: () => TestRoutes.open(context, TestType.single),
              ),
              QuickAction(
                icon: Icons.calculate_rounded,
                label: 'Dual',
                onTap: () => TestRoutes.open(context, TestType.dual),
              ),
              QuickAction(
                icon: Icons.graphic_eq_rounded,
                label: 'Biofeed.',
                onTap: () => context.read<NavigationController>().select(AppTab.tests),
              ),
              QuickAction(
                icon: Icons.auto_awesome_rounded,
                label: 'Coach',
                onTap: () => CoachView.open(context),
              ),
            ],
          ),
          const SectionHeader('Daily Summary'),
          SummaryCards(summary: summary),
          SectionHeader(
            'Recent activity',
            action: summary.recent.isEmpty
                ? null
                : TextButton(
                    onPressed: () => context.read<NavigationController>().select(AppTab.progress),
                    child: const Text('See reports'),
                  ),
          ),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: summary.recent.isEmpty
                ? const EmptyHint(
                    icon: Icons.self_improvement_rounded,
                    message: 'No sessions yet.\nTap the orange bolt to take your first test.',
                  )
                : Column(
                    children: [for (final r in summary.recent) ResultTile(result: r, now: controller.today)],
                  ),
          ),
        ],
      ),
    );
  }
}
