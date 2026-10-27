import 'package:flutter/foundation.dart';

import '../models/test_result.dart';
import '../services/test_result_repository.dart';

/// Source of truth for session history; other controllers derive from it.
class ResultsController extends ChangeNotifier {
  ResultsController(this._repository);

  final TestResultRepository _repository;
  List<TestResult> _results = const [];

  /// Newest first.
  List<TestResult> get results => _results;

  Future<void> load() async {
    _results = await _repository.fetchAll();
    notifyListeners();
  }

  Future<TestResult> save(TestResult result) async {
    final saved = result.copyWith(id: await _repository.insert(result));
    _results = [saved, ..._results];
    notifyListeners();
    return saved;
  }

  Future<void> clear() async {
    await _repository.deleteAll();
    _results = const [];
    notifyListeners();
  }
}
