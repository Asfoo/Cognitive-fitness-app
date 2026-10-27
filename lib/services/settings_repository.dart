import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}

class PrefsSettingsRepository implements SettingsRepository {
  static const _dailyGoalKey = 'daily_goal';
  static const _reactionTargetKey = 'reaction_target_ms';

  final _prefs = SharedPreferencesAsync();

  @override
  Future<AppSettings> load() async {
    const defaults = AppSettings();
    return defaults.copyWith(
      dailyGoal: await _prefs.getInt(_dailyGoalKey),
      reactionTargetMs: await _prefs.getInt(_reactionTargetKey),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setInt(_dailyGoalKey, settings.dailyGoal);
    await _prefs.setInt(_reactionTargetKey, settings.reactionTargetMs);
  }
}
