import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/dashboard_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/reports_controller.dart';
import 'controllers/results_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'services/settings_repository.dart';
import 'services/test_result_repository.dart';
import 'views/splash/splash_view.dart';

class CognitiveFitnessApp extends StatelessWidget {
  const CognitiveFitnessApp({super.key, required this.resultRepository, required this.settingsRepository});

  final TestResultRepository resultRepository;
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ResultsController(resultRepository)),
        ChangeNotifierProvider(create: (_) => SettingsController(settingsRepository)),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(create: (c) => DashboardController(c.read(), c.read())),
        ChangeNotifierProvider(create: (c) => ReportsController(c.read(), c.read())),
      ],
      child: MaterialApp(
        title: 'Cognitive Fitness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashView(),
      ),
    );
  }
}
