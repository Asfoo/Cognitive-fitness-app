import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cognitive_fitness.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE test_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  test_type TEXT,
  reaction_time INTEGER,
  math_answer INTEGER,
  correct_answer INTEGER,
  eeg REAL,
  ecg INTEGER,
  emg REAL,
  eye_tracking INTEGER,
  timestamp TEXT
)
''');
  }

  Future<void> insertResult(Map<String, dynamic> result) async {
    final db = await database;
    await db.insert('test_results', {
      'test_type': result['test_type'],
      'reaction_time': result['reaction_time'],
      'math_answer': result['math_answer'],
      'correct_answer': result['correct_answer'],
      'eeg': result['eeg'],
      'ecg': result['ecg'],
      'emg': result['emg'],
      'eye_tracking': result['eye_tracking'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final db = await database;
    return await db.query('test_results', orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>> getLatestResult() async {
    final db = await database;
    final results = await db.query('test_results', orderBy: 'timestamp DESC', limit: 1);
    return results.isNotEmpty ? results.first : {};
  }
}