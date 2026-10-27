import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/tests/biofeedback_test_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../models/stimulus.dart';
import '../../models/test_type.dart';
import '../../services/beep_player.dart';
import 'widgets/biofeedback_panel.dart';
import 'widgets/test_scaffold.dart';

class AuditoryTestView extends StatelessWidget {
  const AuditoryTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AuditoryTestController(c.read(), AssetBeepPlayer()),
      child: const _AuditoryBody(),
    );
  }
}

class _AuditoryBody extends StatefulWidget {
  const _AuditoryBody();

  @override
  State<_AuditoryBody> createState() => _AuditoryBodyState();
}

class _AuditoryBodyState extends State<_AuditoryBody> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuditoryTestController>();
    final listening = controller.activeStimulus != null;

    return TestScaffold(
      type: TestType.auditory,
      controller: controller,
      child: controller.phase == BiofeedbackPhase.ready
          ? TestIntro(
              type: TestType.auditory,
              onStart: controller.start,
              steps: [
                'Turn your volume up. Solve the sum while beeps play.',
                'High beep → tap LEFT. Low beep → tap RIGHT.',
                'Respond within ${controller.responseWindow.inMilliseconds / 1000} s; misses count as errors.',
              ],
            )
          : BiofeedbackPanel(
              controller: controller,
              answer: _answer,
              instruction: listening ? 'Beep! Which pitch?' : 'Listen for the next beep…',
              responseArea: FeedbackFlash(
                correct: controller.lastCorrect,
                trigger: controller.responseCount,
                child: Row(
                  children: [
                    _PitchPad(
                      label: 'High',
                      icon: Icons.north_rounded,
                      active: listening,
                      onTap: () => controller.respond(ResponseKind.left),
                    ),
                    const SizedBox(width: 12),
                    _PitchPad(
                      label: 'Low',
                      icon: Icons.south_rounded,
                      active: listening,
                      onTap: () => controller.respond(ResponseKind.right),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PitchPad extends StatelessWidget {
  const _PitchPad({required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => onTap(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 150,
          decoration: AppDecorations.card(color: active ? AppColors.ink : AppColors.surface),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: active ? Colors.white : AppColors.ink),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: active ? Colors.white : AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
