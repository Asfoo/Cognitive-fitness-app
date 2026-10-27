import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/tests/biofeedback_test_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../models/stimulus.dart';
import '../../models/test_type.dart';
import 'widgets/biofeedback_panel.dart';
import 'widgets/test_scaffold.dart';

class VisualTestView extends StatelessWidget {
  const VisualTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => VisualTestController(c.read()),
      child: const _VisualBody(),
    );
  }
}

class _VisualBody extends StatefulWidget {
  const _VisualBody();

  @override
  State<_VisualBody> createState() => _VisualBodyState();
}

class _VisualBodyState extends State<_VisualBody> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VisualTestController>();

    return TestScaffold(
      type: TestType.visual,
      controller: controller,
      child: controller.phase == BiofeedbackPhase.ready
          ? TestIntro(
              type: TestType.visual,
              onStart: controller.start,
              steps: [
                'Solve the sum while watching the signal panel.',
                'GREEN → tap the panel quickly. RED → do not tap.',
                'Each light lasts ${controller.responseWindow.inMilliseconds / 1000} s.',
              ],
            )
          : BiofeedbackPanel(
              controller: controller,
              answer: _answer,
              instruction: 'Tap on green, hold on red',
              responseArea: FeedbackFlash(
                correct: controller.lastCorrect,
                trigger: controller.responseCount,
                child: _SignalPanel(
                  stimulus: controller.activeStimulus,
                  onTap: () => controller.respond(ResponseKind.tap),
                ),
              ),
            ),
    );
  }
}

class _SignalPanel extends StatelessWidget {
  const _SignalPanel({required this.stimulus, required this.onTap});

  final StimulusKind? stimulus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (stimulus) {
      StimulusKind.go => (AppColors.go, 'GO'),
      StimulusKind.noGo => (AppColors.accent, 'STOP'),
      _ => (AppColors.surface, '•••'),
    };
    final lit = stimulus != null;

    return GestureDetector(
      onTapDown: (_) => onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: AppDecorations.card(color: color),
        child: Text(
          label,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(color: lit ? Colors.white : AppColors.track),
        ),
      ),
    );
  }
}
