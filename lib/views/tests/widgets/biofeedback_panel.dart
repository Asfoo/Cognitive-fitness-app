import 'package:flutter/material.dart';

import '../../../controllers/tests/biofeedback_test_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../common/buttons.dart';
import 'test_scaffold.dart';

/// Shared running layout for auditory and visual biofeedback tests:
/// math card, a test-specific response area, progress and submit.
class BiofeedbackPanel extends StatelessWidget {
  const BiofeedbackPanel({
    super.key,
    required this.controller,
    required this.answer,
    required this.instruction,
    required this.responseArea,
  });

  final BiofeedbackTestController controller;
  final TextEditingController answer;
  final String instruction;
  final Widget responseArea;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final finishedCues = controller.phase == BiofeedbackPhase.answering;

    return Column(
      children: [
        StepDots(total: controller.stimulusCount, done: controller.presented),
        const SizedBox(height: 24),
        MathCard(question: controller.problem!.question, controller: answer),
        const SizedBox(height: 24),
        Text(
          finishedCues ? 'All cues done. Submit your answer.' : instruction,
          textAlign: TextAlign.center,
          style: text.titleMedium,
        ),
        const SizedBox(height: 16),
        responseArea,
        const SizedBox(height: 16),
        Text(
          'Errors: ${controller.errors}',
          style: text.titleMedium?.copyWith(color: controller.errors == 0 ? AppColors.muted : AppColors.accent),
        ),
        const SizedBox(height: 20),
        PillButton(
          label: 'Submit answer',
          style: finishedCues ? PillStyle.accent : PillStyle.dark,
          expand: true,
          onPressed: controller.canSubmit ? () => controller.submit(answer.text) : null,
        ),
      ],
    );
  }
}

/// Brief green/red ring flash after each cue is resolved.
class FeedbackFlash extends StatelessWidget {
  const FeedbackFlash({super.key, required this.correct, required this.trigger, required this.child, this.radius = 32});

  final bool? correct;

  /// Changes with every resolved cue to restart the flash.
  final int trigger;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(trigger),
      tween: Tween(begin: correct == null ? 0 : 1, end: 0),
      duration: const Duration(milliseconds: 600),
      builder: (context, t, child) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            width: 3,
            color: (correct ?? true ? AppColors.go : AppColors.accent).withValues(alpha: t),
          ),
        ),
        child: child,
      ),
      child: child,
    );
  }
}
