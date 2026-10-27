import '../models/test_result.dart';
import 'database_service.dart';

abstract interface class TestResultRepository {
  /// All sessions, newest first.
  Future<List<TestResult>> fetchAll();

  /// Persists [result] and returns its new id.
  Future<int> insert(TestResult result);

  Future<void> deleteAll();
}

class SqfliteTestResultRepository implements TestResultRepository {
  SqfliteTestResultRepository(this._db);

  final DatabaseService _db;

  @override
  Future<List<TestResult>> fetchAll() async {
    final db = await _db.database;
    final rows = await db.query(DatabaseService.resultsTable, orderBy: 'timestamp DESC');
    return rows.map(TestResult.fromMap).toList();
  }

  @override
  Future<int> insert(TestResult result) async {
    final db = await _db.database;
    return db.insert(DatabaseService.resultsTable, result.toMap());
  }

  @override
  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete(DatabaseService.resultsTable);
  }
}
