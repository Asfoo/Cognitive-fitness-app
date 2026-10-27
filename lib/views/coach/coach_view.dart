import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/coach_controller.dart';
import '../../controllers/dashboard_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../models/coach_message.dart';
import '../../models/test_type.dart';
import '../common/buttons.dart';
import '../common/charts.dart';
import '../common/surfaces.dart';
import '../tests/test_routes.dart';

/// Conversational progress coach answering from local history.
class CoachView extends StatelessWidget {
  const CoachView({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoachView()));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => CoachController(c.read(), c.read()),
      child: const _CoachBody(),
    );
  }
}

class _CoachBody extends StatefulWidget {
  const _CoachBody();

  @override
  State<_CoachBody> createState() => _CoachBodyState();
}

class _CoachBodyState extends State<_CoachBody> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _ask(CoachTopic topic) {
    context.read<CoachController>().ask(topic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CoachController>();
    final quickTest = context.select<DashboardController, TestType>((c) => c.suggestedTest);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('Coach', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                  ),
                  CircleIconButton(icon: Icons.refresh_rounded, tooltip: 'New chat', onPressed: controller.reset),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                itemCount: controller.messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, i) => _MessageView(message: controller.messages[i]),
              ),
            ),
            AccentOrb(
              onPressed: () => TestRoutes.open(context, quickTest),
              size: 64,
              pulse: true,
              tooltip: 'Start suggested test',
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                itemCount: CoachTopic.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final topic = CoachTopic.values[i];
                  return ActionChip(
                    label: Text(topic.question),
                    onPressed: () => _ask(topic),
                    backgroundColor: AppColors.surface,
                    side: BorderSide.none,
                    elevation: 2,
                    shadowColor: const Color(0x22000000),
                    shape: const StadiumBorder(),
                    labelStyle: Theme.of(context).textTheme.labelLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
          child: SoftWell(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Text(message.text, style: text.titleMedium?.copyWith(fontSize: 18)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: AppDecorations.card(radius: 28),
          child: Text(message.text, style: text.titleLarge?.copyWith(fontSize: 19)),
        ),
        if (message.stats.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: message.stats.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _StatChip(stat: message.stats[i]),
            ),
          ),
        ],
        if (message.suggestedTest != null) ...[
          const SizedBox(height: 12),
          PillButton(
            label: 'Start ${message.suggestedTest!.title}',
            icon: Icons.play_arrow_rounded,
            style: PillStyle.dark,
            onPressed: () => TestRoutes.open(context, message.suggestedTest!),
          ),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.stat});

  final CoachStat stat;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(stat.label, style: text.bodyMedium),
              const SizedBox(height: 4),
              Text(stat.value, style: text.titleLarge),
            ],
          ),
          if (stat.progress != null) ...[
            const SizedBox(width: 16),
            RingProgress(value: stat.progress!, size: 52, strokeWidth: 5, color: AppColors.accent),
          ],
        ],
      ),
    );
  }
}
