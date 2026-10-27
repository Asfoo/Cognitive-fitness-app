import 'package:flutter/material.dart';

import '../../../controllers/tests/test_session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/test_type.dart';
import '../../common/buttons.dart';
import '../../common/surfaces.dart';
import '../../common/test_type_style.dart';
import '../../results/result_view.dart';

/// Page frame shared by every test: back button, title, status chip and
/// automatic navigation to the result once [controller] has saved it.
class TestScaffold extends StatefulWidget {
  const TestScaffold({super.key, required this.type, required this.controller, required this.child, this.status});

  final TestType type;
  final TestSessionController controller;
  final Widget child;
  final String? status;

  @override
  State<TestScaffold> createState() => _TestScaffoldState();
}

class _TestScaffoldState extends State<TestScaffold> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final result = widget.controller.result;
    if (result == null) return;
    widget.controller.removeListener(_onControllerChanged);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ResultView(result: result)));
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      widget.type.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: widget.status == null
                        ? null
                        : Text(
                            widget.status!,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.muted),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "How it works" card shown before a test starts.
class TestIntro extends StatelessWidget {
  const TestIntro({super.key, required this.type, required this.steps, required this.onStart});

  final TestType type;
  final List<String> steps;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: 12),
        AccentOrb(onPressed: onStart, icon: type.icon, size: 88, pulse: true, tooltip: 'Start'),
        const SizedBox(height: 28),
        Text(type.description, textAlign: TextAlign.center, style: text.headlineSmall),
        const SizedBox(height: 28),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How it works', style: text.titleMedium),
              const SizedBox(height: 14),
              for (final (i, step) in steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.well, shape: BoxShape.circle),
                        child: Text('${i + 1}', style: text.labelLarge),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step, style: text.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PillButton(label: 'Start test', icon: Icons.play_arrow_rounded, onPressed: onStart, expand: true),
      ],
    );
  }
}

/// Sum to solve plus the numeric answer field.
class MathCard extends StatelessWidget {
  const MathCard({super.key, required this.question, required this.controller, this.enabled = true});

  final String question;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solve', style: text.bodyMedium?.copyWith(color: AppColors.muted)),
                const SizedBox(height: 4),
                ValueWithUnit(question, unit: ' = ?', size: 30),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: text.titleLarge,
              decoration: const InputDecoration(hintText: 'Answer'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of dots showing completed vs total steps.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i < done ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: i < done ? AppColors.accent : AppColors.track,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}
