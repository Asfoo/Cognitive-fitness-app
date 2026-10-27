import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService({this.fileName = 'cognitive_fitness.db'});

  static const resultsTable = 'session_results';
  static const _version = 2;

  final String fileName;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), fileName);
    return openDatabase(
      path,
      version: _version,
      onCreate: (db, _) => _createResultsTable(db),
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) await _migrateFromV1(db);
      },
    );
  }

  static Future<void> _createResultsTable(DatabaseExecutor db) {
    return db.execute('''
CREATE TABLE $resultsTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  test_type TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  reaction_ms REAL,
  variability_ms REAL,
  tap_interval_ms REAL,
  errors INTEGER NOT NULL DEFAULT 0,
  attempts INTEGER NOT NULL DEFAULT 0,
  math_answer INTEGER,
  correct_answer INTEGER
)''');
  }

  /// v1 measured time with `DateTime.second` (1 s resolution, wrapping at 60),
  /// so its timings are unusable. Sessions, answers and error counts are kept.
  static Future<void> _migrateFromV1(Database db) {
    return db.transaction((txn) async {
      await _createResultsTable(txn);
      await txn.execute('''
INSERT INTO $resultsTable (test_type, timestamp, duration_ms, errors, attempts, math_answer, correct_answer)
SELECT test_type, timestamp, 0, COALESCE(eye_tracking, 0), CASE WHEN test_type IN ('Single', 'Dual') THEN 1 ELSE 3 END,
       math_answer, correct_answer
FROM test_results''');
      await txn.execute('DROP TABLE test_results');
    });
  }
}
