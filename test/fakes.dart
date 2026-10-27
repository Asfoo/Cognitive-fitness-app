import 'package:cognitive_fitness_app/models/app_settings.dart';
import 'package:cognitive_fitness_app/models/test_result.dart';
import 'package:cognitive_fitness_app/services/settings_repository.dart';
import 'package:cognitive_fitness_app/services/test_result_repository.dart';

class InMemoryResultRepository implements TestResultRepository {
  InMemoryResultRepository([List<TestResult> seed = const []]) : _rows = [...seed];

  final List<TestResult> _rows;
  int _nextId = 1;

  @override
  Future<List<TestResult>> fetchAll() async {
    return [..._rows]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<int> insert(TestResult result) async {
    final id = _nextId++;
    _rows.add(result.copyWith(id: id));
    return id;
  }

  @override
  Future<void> deleteAll() async => _rows.clear();
}

class InMemorySettingsRepository implements SettingsRepository {
  AppSettings saved = const AppSettings();

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}
