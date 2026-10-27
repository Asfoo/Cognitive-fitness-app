import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/tests/tapping_test_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/test_type.dart';
import '../common/buttons.dart';
import '../common/surfaces.dart';
import 'widgets/test_scaffold.dart';

class TappingTestView extends StatelessWidget {
  const TappingTestView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => TappingTestController(c.read()),
      child: const _TappingBody(),
    );
  }
}

class _TappingBody extends StatefulWidget {
  const _TappingBody();

  @override
  State<_TappingBody> createState() => _TappingBodyState();
}

class _TappingBodyState extends State<_TappingBody> {
  final _answer = TextEditingController();

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TappingTestController>();
    final text = Theme.of(context).textTheme;

    return TestScaffold(
      type: TestType.tapping,
      controller: controller,
      child: controller.phase == TappingPhase.ready
          ? TestIntro(
              type: TestType.tapping,
              onStart: controller.start,
              steps: const [
                'Solve the sum and type your answer.',
                'Tap the orange target exactly the number of times shown. It moves after every tap.',
                'Extra or missing taps count as errors. Submit when done.',
              ],
            )
          : Column(
              children: [
                MathCard(question: controller.problem!.question, controller: _answer),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text('Tap the target ${controller.requiredTaps}×', style: text.titleMedium)),
                    ValueWithUnit('${controller.taps}', unit: ' taps', size: 24),
                  ],
                ),
                const SizedBox(height: 14),
                SoftWell(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 300,
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      alignment: Alignment(controller.targetX, controller.targetY),
                      child: AccentOrb(onPressed: controller.tapTarget, icon: Icons.touch_app_rounded, size: 68),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PillButton(
                  label: 'Submit answer',
                  style: controller.taps >= controller.requiredTaps ? PillStyle.accent : PillStyle.dark,
                  expand: true,
                  onPressed: controller.phase == TappingPhase.running ? () => controller.submit(_answer.text) : null,
                ),
                const SizedBox(height: 10),
                Text(
                  'Taps count only on the target.',
                  style: text.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
    );
  }
}
