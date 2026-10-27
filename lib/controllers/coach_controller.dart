import 'package:flutter/foundation.dart';

import '../models/coach_message.dart';
import '../services/coach_service.dart';
import 'results_controller.dart';
import 'settings_controller.dart';

class CoachController extends ChangeNotifier {
  CoachController(
    this._results,
    this._settings, {
    CoachService service = const CoachService(),
    DateTime Function() clock = DateTime.now,
  })  : _service = service,
        _clock = clock;

  static const _welcome = CoachMessage.coach(
    "Hi! I'm your focus coach. Ask me about your progress and I'll answer from your test history.",
  );

  final ResultsController _results;
  final SettingsController _settings;
  final CoachService _service;
  final DateTime Function() _clock;
  final List<CoachMessage> _messages = [_welcome];

  List<CoachMessage> get messages => List.unmodifiable(_messages);

  void ask(CoachTopic topic) {
    _messages
      ..add(CoachMessage.user(topic.question))
      ..add(_service.answer(topic, _results.results, _settings.settings, _clock()));
    notifyListeners();
  }

  void reset() {
    _messages
      ..clear()
      ..add(_welcome);
    notifyListeners();
  }
}
