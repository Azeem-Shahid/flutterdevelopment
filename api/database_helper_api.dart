import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    print("Initializing database...");
    _database = await _initDB('student_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print("Database path: $path");

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        await _verifyTableStructure(db);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    print("Creating new database tables...");
    await db.execute('''
    CREATE TABLE student_results (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentname TEXT NOT NULL,
      fathername TEXT NOT NULL,
      progname TEXT NOT NULL,
      shift TEXT NOT NULL,
      rollno TEXT NOT NULL,
      coursecode TEXT NOT NULL,
      coursetitle TEXT NOT NULL,
      credithours REAL NOT NULL,
      obtainedmarks TEXT NOT NULL,
      mysemester TEXT NOT NULL,
      consider_status TEXT NOT NULL,
      is_deleted INTEGER DEFAULT 0
    )
    ''');
    print("student_results table created successfully");
  }

  Future<void> _verifyTableStructure(Database db) async {
    print("Verifying table structure...");
    try {
      final tableInfo = await db.rawQuery("PRAGMA table_info(student_results)");

      final requiredColumns = [
        'studentname', 'fathername', 'progname', 'shift', 'rollno',
        'coursecode', 'coursetitle', 'credithours', 'obtainedmarks',
        'mysemester', 'consider_status', 'is_deleted'
      ];

      for (final column in requiredColumns) {
        if (!tableInfo.any((col) => col['name'] == column)) {
          throw Exception("Missing column: $column");
        }
      }

      print("Table structure verified successfully");
    } catch (e) {
      print("Table structure verification failed: $e");
      await _rebuildDatabase();
    }
  }

  Future<void> _rebuildDatabase() async {
    print("Rebuilding database...");
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'student_database.db');

    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      await deleteDatabase(path);
      print("Old database deleted successfully");

      _database = await _initDB('student_database.db');
      print("Database rebuilt successfully");
    } catch (e) {
      print("Error rebuilding database: $e");
      rethrow;
    }
  }

  Future<int> insertStudentResult(Map<String, dynamic> result) async {
    print('Inserting record: ${result['coursecode']} - ${result['coursetitle']}');

    if (result['coursecode'] == null || result['coursetitle'] == null) {
      throw Exception("Missing required fields (coursecode or coursetitle)");
    }

    final db = await instance.database;

    final data = {
      'studentname': _validateString(result['studentname'], 'studentname'),
      'fathername': _validateString(result['fathername'], 'fathername'),
      'progname': _validateString(result['progname'], 'progname'),
      'shift': _validateString(result['shift'], 'shift'),
      'rollno': _validateString(result['rollno'], 'rollno'),
      'coursecode': _validateString(result['coursecode'], 'coursecode'),
      'coursetitle': _validateString(result['coursetitle'], 'coursetitle'),
      'credithours': _validateCreditHours(result['credithours']),
      'obtainedmarks': _validateString(result['obtainedmarks'], 'obtainedmarks'),
      'mysemester': _validateString(result['mysemester'], 'mysemester'),
      'consider_status': _validateString(result['consider_status'], 'consider_status'),
      'is_deleted': 0,
    };

    try {
      final id = await db.insert('student_results', data);
      print('Successfully inserted record ID: $id');
      return id;
    } catch (e) {
      print("Error inserting data for ${result['coursecode']}: $e");
      print("Full data being inserted: $data");

      if (e.toString().contains('UNIQUE constraint')) {
        print("Attempting to update existing record instead");
        return await db.update(
          'student_results',
          data,
          where: 'coursecode = ? AND rollno = ? AND mysemester = ?',
          whereArgs: [data['coursecode'], data['rollno'], data['mysemester']],
        );
      }
      rethrow;
    }
  }

  String _validateString(dynamic value, String fieldName) {
    if (value == null) {
      print("Warning: $fieldName is null, converting to empty string");
      return '';
    }
    return value.toString();
  }

  double _validateCreditHours(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();

      final strValue = value.toString();
      return double.tryParse(strValue) ?? 0.0;
    } catch (e) {
      print("Error parsing credit hours: $value, using 0.0 instead");
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudentResults() async {
    final db = await instance.database;
    print("Fetching all student results...");

    final results = await db.query(
      'student_results',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'mysemester ASC, coursecode ASC',
    );

    print("Found ${results.length} records");
    return results;
  }

  Future<List<Map<String, dynamic>>> getResultsBySemester(String semester) async {
    final db = await instance.database;
    print("Fetching results for semester: $semester");

    final results = await db.query(
      'student_results',
      where: 'mysemester = ? AND is_deleted = ?',
      whereArgs: [semester, 0],
      orderBy: 'coursecode ASC',
    );

    print("Found ${results.length} records for semester $semester");
    return results;
  }

  Future<List<String>> getDistinctSemesters() async {
    final db = await instance.database;
    print("Fetching distinct semesters...");

    final results = await db.rawQuery(
        'SELECT DISTINCT mysemester FROM student_results WHERE is_deleted = 0 ORDER BY mysemester ASC'
    );

    final semesters = results.map((result) => result['mysemester'] as String).toList();
    print("Found ${semesters.length} distinct semesters: $semesters");
    return semesters;
  }

  Future<int> deleteResult(int id) async {
    final db = await instance.database;
    print("Soft-deleting record ID: $id");

    final count = await db.update(
      'student_results',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    print("Deleted $count record(s)");
    return count;
  }

  Future<int> deleteAllResults() async {
    final db = await instance.database;
    print("Soft-deleting all records...");

    final count = await db.update(
      'student_results',
      {'is_deleted': 1},
    );

    print("Deleted $count records in total");
    return count;
  }

  Future<int> restoreAllResults() async {
    final db = await instance.database;
    print("Restoring all soft-deleted records...");

    final count = await db.update(
      'student_results',
      {'is_deleted': 0},
    );

    print("Restored $count records");
    return count;
  }

  Future<void> debugPrintAllRecords() async {
    final db = await instance.database;
    print("Debug: Printing all records in database...");

    final results = await db.rawQuery('SELECT * FROM student_results');
    print('Total records in database: ${results.length}');

    for (final record in results) {
      print('''
      Record ID: ${record['id']}
      Student: ${record['studentname']} (${record['rollno']})
      Course: ${record['coursecode']} - ${record['coursetitle']}
      Semester: ${record['mysemester']}
      Marks: ${record['obtainedmarks']}
      Deleted: ${record['is_deleted'] == 1 ? 'YES' : 'NO'}
      --------------------------
      ''');
    }
  }

  Future close() async {
    if (_database != null) {
      print("Closing database connection...");
      await _database!.close();
      _database = null;
    }
  }
}