import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/results_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../common/buttons.dart';
import '../shell/main_shell.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  static const _minimumDisplay = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      context.read<ResultsController>().load(),
      context.read<SettingsController>().load(),
      Future<void>.delayed(_minimumDisplay),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AccentOrb(onPressed: null, size: 76, pulse: true, icon: Icons.psychology_alt_rounded),
              const SizedBox(height: 36),
              Text('Cognitive\nFitness', textAlign: TextAlign.center, style: text.displaySmall),
              const SizedBox(height: 12),
              Text(
                'Assess your driving readiness',
                style: text.titleMedium?.copyWith(color: AppColors.muted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
