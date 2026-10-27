import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../services/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  static const targetStepMs = 25;

  final SettingsRepository _repository;
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _repository.load();
    notifyListeners();
  }

  void changeDailyGoal(int delta) => _update(_settings.copyWith(dailyGoal: _settings.dailyGoal + delta));

  void changeReactionTarget(int steps) {
    _update(_settings.copyWith(reactionTargetMs: _settings.reactionTargetMs + steps * targetStepMs));
  }

  void _update(AppSettings next) {
    if (next.dailyGoal == _settings.dailyGoal && next.reactionTargetMs == _settings.reactionTargetMs) return;
    _settings = next;
    notifyListeners();
    _repository.save(next);
  }
}
