import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/tests/reaction_test_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../models/test_type.dart';
import '../common/buttons.dart';
import 'widgets/test_scaffold.dart';

/// Single-task and dual-task reaction tests.
class ReactionTestView extends StatelessWidget {
  const ReactionTestView({super.key, required this.type});

  final TestType type;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ReactionTestController(c.read(), type: type),
      child: const _ReactionTestBody(),
    );
  }
}

class _ReactionTestBody extends StatefulWidget {
  const _ReactionTestBody();

  @override
  State<_ReactionTestBody> createState() => _ReactionTestBodyState();
}

class _ReactionTestBodyState extends State<_ReactionTestBody> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReactionTestController>();
    final started = controller.phase != ReactionPhase.ready;

    return TestScaffold(
      type: controller.type,
      controller: controller,
      status: started ? '${controller.completedTrials}/${controller.trials}' : null,
      child: !started
          ? TestIntro(
              type: controller.type,
              onStart: controller.start,
              steps: [
                if (controller.withMath) 'Solve the sum shown and type your answer whenever you are ready.',
                'Wait for the circle to turn orange, then tap it as fast as you can.',
                'Tapping too early counts as a false start.',
                'Complete ${controller.trials} signals to finish.',
              ],
            )
          : Column(
              children: [
                StepDots(total: controller.trials, done: controller.completedTrials),
                const SizedBox(height: 24),
                if (controller.withMath) ...[
                  MathCard(question: controller.problem!.question, controller: _answer),
                  const SizedBox(height: 28),
                ],
                _SignalPad(phase: controller.phase, onTap: controller.tap),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    controller.feedback ?? ' ',
                    key: ValueKey(controller.feedback),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                  ),
                ),
                if (controller.phase == ReactionPhase.answering) ...[
                  const SizedBox(height: 20),
                  PillButton(
                    label: 'Submit answer',
                    expand: true,
                    onPressed: () => controller.submitAnswer(_answer.text),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SignalPad extends StatelessWidget {
  const _SignalPad({required this.phase, required this.onTap});

  final ReactionPhase phase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final live = phase == ReactionPhase.signal;
    final label = switch (phase) {
      ReactionPhase.signal => 'Tap!',
      ReactionPhase.waiting => 'Wait…',
      _ => 'Done',
    };

    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 240,
        height: 240,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: live
              ? const RadialGradient(center: Alignment(-0.3, -0.4), colors: [AppColors.accentLight, AppColors.accent])
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.well, AppColors.wellLight],
                ),
          boxShadow: live ? AppDecorations.accentGlow : AppDecorations.softShadow,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: live ? Colors.white : AppColors.muted),
        ),
      ),
    );
  }
}
