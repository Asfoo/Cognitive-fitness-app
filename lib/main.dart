import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/theme/app_colors.dart';
import 'services/database_service.dart';
import 'services/settings_repository.dart';
import 'services/test_result_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    CognitiveFitnessApp(
      resultRepository: SqfliteTestResultRepository(DatabaseService()),
      settingsRepository: PrefsSettingsRepository(),
    ),
  );
}
