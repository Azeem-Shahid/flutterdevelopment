// lib/database_helper_api.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'api_service.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Table names
  static const String studentResultsTable = 'student_results';
  static const String gradesTable = 'grades';

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
      version: 3, // Increased version for the new grades table
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _verifyTableStructure(db);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    print("Creating new database tables...");

    // Create student results table
    await _createStudentResultsTable(db);

    // Create grades table
    await _createGradesTable(db);

    print("Database tables created successfully");
  }

  Future<void> _createStudentResultsTable(Database db) async {
    print("Creating student_results table...");
    await db.execute('''
    CREATE TABLE $studentResultsTable (
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
      is_deleted INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      sync_attempted INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )
    ''');
    print("student_results table created successfully");
  }

  Future<void> _createGradesTable(Database db) async {
    print("Creating grades table...");
    await db.execute('''
    CREATE TABLE $gradesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      remote_id TEXT,
      user_id TEXT NOT NULL,
      course_name TEXT NOT NULL,
      semester_no TEXT NOT NULL,
      credit_hours TEXT NOT NULL,
      marks TEXT NOT NULL,
      grade TEXT,
      is_deleted INTEGER DEFAULT 0,
      is_synced INTEGER DEFAULT 0,
      sync_attempted INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )
    ''');
    print("grades table created successfully");
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");

    if (oldVersion < 2) {
      // Add new sync-related columns to student_results
      try {
        await db.execute("ALTER TABLE $studentResultsTable ADD COLUMN is_synced INTEGER DEFAULT 0");
        await db.execute("ALTER TABLE $studentResultsTable ADD COLUMN sync_attempted INTEGER DEFAULT 0");
        await db.execute("ALTER TABLE $studentResultsTable ADD COLUMN created_at TEXT");
        await db.execute("ALTER TABLE $studentResultsTable ADD COLUMN updated_at TEXT");
        print("Added sync-related columns to database");
      } catch (e) {
        print("Error upgrading database to version 2: $e");
      }
    }

    if (oldVersion < 3) {
      // Create the grades table if upgrading to version 3
      try {
        await _createGradesTable(db);
      } catch (e) {
        print("Error creating grades table in upgrade to version 3: $e");
      }
    }
  }

  Future<void> _verifyTableStructure(Database db) async {
    print("Verifying table structure...");
    try {
      // Verify student_results table
      final studentResultsInfo = await db.rawQuery("PRAGMA table_info($studentResultsTable)");

      final requiredStudentColumns = [
        'studentname', 'fathername', 'progname', 'shift', 'rollno',
        'coursecode', 'coursetitle', 'credithours', 'obtainedmarks',
        'mysemester', 'consider_status', 'is_deleted'
      ];

      // Check if sync columns exist, if not add them
      bool hasSyncColumns = studentResultsInfo.any((col) => col['name'] == 'is_synced');
      if (!hasSyncColumns) {
        await _onUpgrade(db, 1, 2);
      }

      for (final column in requiredStudentColumns) {
        if (!studentResultsInfo.any((col) => col['name'] == column)) {
          throw Exception("Missing column in student_results: $column");
        }
      }

      // Check if grades table exists, if not create it
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='$gradesTable'");
      if (tables.isEmpty) {
        print("Grades table not found, creating it...");
        await _createGradesTable(db);
      } else {
        print("Grades table exists, verifying structure...");
        final gradesInfo = await db.rawQuery("PRAGMA table_info($gradesTable)");

        final requiredGradesColumns = [
          'user_id', 'course_name', 'semester_no', 'credit_hours',
          'marks', 'grade', 'is_synced', 'is_deleted'
        ];

        for (final column in requiredGradesColumns) {
          if (!gradesInfo.any((col) => col['name'] == column)) {
            throw Exception("Missing column in grades: $column");
          }
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

  // STUDENT RESULTS METHODS

  Future<int> insertStudentResult(Map<String, dynamic> result) async {
    print('Inserting student result: ${result['coursecode']} - ${result['coursetitle']}');

    if (result['coursecode'] == null || result['coursetitle'] == null) {
      throw Exception("Missing required fields (coursecode or coursetitle)");
    }

    final db = await instance.database;

    // Add timestamps
    result['created_at'] = DateTime.now().toIso8601String();
    result['updated_at'] = DateTime.now().toIso8601String();
    result['is_synced'] = 0; // Not synced with API yet

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
      'is_synced': 0,
      'sync_attempted': 0,
      'created_at': result['created_at'],
      'updated_at': result['updated_at'],
    };

    try {
      final id = await db.insert(studentResultsTable, data);
      print('Successfully inserted student result ID: $id');

      // Try to sync with API if connected
      _trySyncWithApi(id, data);

      return id;
    } catch (e) {
      print("Error inserting data for ${result['coursecode']}: $e");
      print("Full data being inserted: $data");

      if (e.toString().contains('UNIQUE constraint')) {
        print("Attempting to update existing record instead");
        return await db.update(
          studentResultsTable,
          data,
          where: 'coursecode = ? AND rollno = ? AND mysemester = ?',
          whereArgs: [data['coursecode'], data['rollno'], data['mysemester']],
        );
      }
      rethrow;
    }
  }

  Future<void> _trySyncWithApi(int localId, Map<String, dynamic> data) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Device is offline. Skipping API sync for now.');
        return;
      }

      // Prepare data for API
      Map<String, dynamic> apiData = Map.from(data);
      apiData.remove('id');
      apiData.remove('is_synced');
      apiData.remove('sync_attempted');

      // Attempt to send to API
      final response = await ApiService.addStudentResult(apiData);

      // Update local sync status
      final db = await instance.database;

      if (response['success'] && !response['offline']) {
        // Successfully synced with API
        await db.update(
          studentResultsTable,
          {
            'is_synced': 1,
            'sync_attempted': 1,
            'updated_at': DateTime.now().toIso8601String()
          },
          where: 'id = ?',
          whereArgs: [localId],
        );
        print('Record ID $localId successfully synced with API');
      } else {
        // Sync attempted but failed
        await db.update(
          studentResultsTable,
          {
            'sync_attempted': 1,
            'updated_at': DateTime.now().toIso8601String()
          },
          where: 'id = ?',
          whereArgs: [localId],
        );
        print('Failed to sync record ID $localId with API: ${response['message']}');
      }
    } catch (e) {
      print('Error syncing with API: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudentResults() async {
    final db = await instance.database;
    print("Fetching all student results...");

    final results = await db.query(
      studentResultsTable,
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'mysemester ASC, coursecode ASC',
    );

    print("Found ${results.length} student records");
    return results;
  }

  Future<List<Map<String, dynamic>>> getResultsBySemester(String semester) async {
    final db = await instance.database;
    print("Fetching results for semester: $semester");

    final results = await db.query(
      studentResultsTable,
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
        'SELECT DISTINCT mysemester FROM $studentResultsTable WHERE is_deleted = 0 ORDER BY mysemester ASC'
    );

    final semesters = results.map((result) => result['mysemester'] as String).toList();
    print("Found ${semesters.length} distinct semesters: $semesters");
    return semesters;
  }

  Future<int> deleteResult(int id) async {
    final db = await instance.database;
    print("Soft-deleting student result ID: $id");

    final count = await db.update(
      studentResultsTable,
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    print("Deleted $count student result(s)");
    return count;
  }

  Future<int> deleteAllResults() async {
    final db = await instance.database;
    print("Soft-deleting all student results...");

    final count = await db.update(
      studentResultsTable,
      {'is_deleted': 1},
    );

    print("Deleted $count student results in total");
    return count;
  }

  // GRADES METHODS

  // Insert a grade record
  Future<int> insertGrade(Map<String, dynamic> grade) async {
    print('Inserting grade for user ID: ${grade['user_id']}, course: ${grade['course_name']}');

    final db = await instance.database;

    // Add timestamps
    grade['created_at'] = DateTime.now().toIso8601String();
    grade['updated_at'] = DateTime.now().toIso8601String();

    // Check if this grade already exists
    String? remoteId = grade['id']?.toString();
    String userId = _validateString(grade['user_id'], 'user_id');
    String courseName = _validateString(grade['course_name'], 'course_name');
    String semesterNo = _validateString(grade['semester_no'], 'semester_no');

    if (remoteId != null) {
      List<Map<String, dynamic>> existingGrades = await db.query(
        gradesTable,
        where: 'remote_id = ?',
        whereArgs: [remoteId],
      );

      if (existingGrades.isNotEmpty) {
        // Update existing grade
        await db.update(
          gradesTable,
          {
            'user_id': userId,
            'course_name': courseName,
            'semester_no': semesterNo,
            'credit_hours': _validateString(grade['credit_hours'], 'credit_hours'),
            'marks': _validateString(grade['marks'], 'marks'),
            'grade': _validateString(grade['grade'], 'grade'),
            'is_synced': grade['is_synced'] ?? 0,
            'is_deleted': 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'remote_id = ?',
          whereArgs: [remoteId],
        );

        print('Updated existing grade with remote ID: $remoteId');
        return existingGrades.first['id'] as int;
      }
    } else {
      // Check for duplicate grade based on user_id, course_name, and semester_no
      List<Map<String, dynamic>> existingGrades = await db.query(
        gradesTable,
        where: 'user_id = ? AND course_name = ? AND semester_no = ? AND is_deleted = 0',
        whereArgs: [userId, courseName, semesterNo],
      );

      if (existingGrades.isNotEmpty) {
        // Update existing grade
        final id = existingGrades.first['id'] as int;
        await db.update(
          gradesTable,
          {
            'credit_hours': _validateString(grade['credit_hours'], 'credit_hours'),
            'marks': _validateString(grade['marks'], 'marks'),
            'grade': _validateString(grade['grade'], 'grade'),
            'is_synced': grade['is_synced'] ?? 0,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        print('Updated existing grade with ID: $id');

        // Try to sync with API if online
        _trySyncGradeWithApi(id, {
          'user_id': userId,
          'course_name': courseName,
          'semester_no': semesterNo,
          'credit_hours': _validateString(grade['credit_hours'], 'credit_hours'),
          'marks': _validateString(grade['marks'], 'marks'),
          'grade': _validateString(grade['grade'], 'grade'),
        });

        return id;
      }
    }

    // Insert new grade
    final gradeData = {
      'remote_id': remoteId,
      'user_id': userId,
      'course_name': courseName,
      'semester_no': semesterNo,
      'credit_hours': _validateString(grade['credit_hours'], 'credit_hours'),
      'marks': _validateString(grade['marks'], 'marks'),
      'grade': _validateString(grade['grade'], 'grade'),
      'is_synced': grade['is_synced'] ?? 0,
      'is_deleted': 0,
      'sync_attempted': 0,
      'created_at': grade['created_at'],
      'updated_at': grade['updated_at'],
    };

    final id = await db.insert(gradesTable, gradeData);
    print('Successfully inserted new grade with ID: $id');

    // Try to sync with API if online
    _trySyncGradeWithApi(id, {
      'user_id': userId,
      'course_name': courseName,
      'semester_no': semesterNo,
      'credit_hours': _validateString(grade['credit_hours'], 'credit_hours'),
      'marks': _validateString(grade['marks'], 'marks'),
      'grade': _validateString(grade['grade'], 'grade'),
    });

    return id;
  }

  // Sync a grade with the API
  Future<void> _trySyncGradeWithApi(int localId, Map<String, dynamic> data) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Device is offline. Skipping grade API sync for now.');
        return;
      }

      // Attempt to send to API
      final response = await ApiService.addGrade(data);

      // Update local sync status
      final db = await instance.database;

      if (response['success'] && !response['offline']) {
        // Successfully synced with API
        await db.update(
          gradesTable,
          {
            'is_synced': 1,
            'sync_attempted': 1,
            'updated_at': DateTime.now().toIso8601String()
          },
          where: 'id = ?',
          whereArgs: [localId],
        );
        print('Grade ID $localId successfully synced with API');
      } else {
        // Sync attempted but failed
        await db.update(
          gradesTable,
          {
            'sync_attempted': 1,
            'updated_at': DateTime.now().toIso8601String()
          },
          where: 'id = ?',
          whereArgs: [localId],
        );
        print('Failed to sync grade ID $localId with API: ${response['message']}');
      }
    } catch (e) {
      print('Error syncing grade with API: $e');
    }
  }

  // Get all grades
  Future<List<Map<String, dynamic>>> getAllGrades() async {
    final db = await instance.database;
    print("Fetching all grades...");

    final results = await db.query(
      gradesTable,
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );

    print("Found ${results.length} grade records");
    return results;
  }

  // Get grades for a specific user
  Future<List<Map<String, dynamic>>> getGradesByUserId(String userId) async {
    final db = await instance.database;
    print("Fetching grades for user ID: $userId");

    final results = await db.query(
      gradesTable,
      where: 'user_id = ? AND is_deleted = ?',
      whereArgs: [userId, 0],
      orderBy: 'semester_no ASC, course_name ASC',
    );

    print("Found ${results.length} grades for user ID $userId");
    return results;
  }

  // Delete a grade
  Future<int> deleteGrade(int id) async {
    final db = await instance.database;
    print("Soft-deleting grade ID: $id");

    final count = await db.update(
      gradesTable,
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    print("Deleted $count grade(s)");
    return count;
  }

  // Delete all grades
  Future<int> deleteAllGrades() async {
    final db = await instance.database;
    print("Soft-deleting all grades...");

    final count = await db.update(
      gradesTable,
      {'is_deleted': 1},
    );

    print("Deleted $count grades in total");
    return count;
  }

  // Get unsynchronized grades
  Future<List<Map<String, dynamic>>> getUnsyncedGrades() async {
    final db = await instance.database;
    return await db.query(
      gradesTable,
      where: 'is_synced = ? AND is_deleted = ?',
      whereArgs: [0, 0],
    );
  }

  // Mark a grade as synchronized
  Future<int> markGradeAsSynced(int id) async {
    final db = await instance.database;
    return await db.update(
      gradesTable,
      {
        'is_synced': 1,
        'updated_at': DateTime.now().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // SHARED UTILITY METHODS

  // Sync all unsynced records with the API (both student results and grades)
  Future<Map<String, dynamic>> syncAllWithApi() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return {
          'success': false,
          'message': 'Device is offline. Cannot sync with API.'
        };
      }

      final db = await instance.database;

      // Sync student results
      final unsyncedResults = await db.query(
        studentResultsTable,
        where: 'is_synced = ? AND is_deleted = ?',
        whereArgs: [0, 0],
      );

      // Sync grades
      final unsyncedGrades = await db.query(
        gradesTable,
        where: 'is_synced = ? AND is_deleted = ?',
        whereArgs: [0, 0],
      );

      int totalRecords = unsyncedResults.length + unsyncedGrades.length;

      if (totalRecords == 0) {
        return {
          'success': true,
          'message': 'No unsynced records to sync',
          'count': 0
        };
      }

      int successCount = 0;

      // Sync student results
      for (var record in unsyncedResults) {
        try {
          Map<String, dynamic> apiData = Map.from(record);
          apiData.remove('id');
          apiData.remove('is_synced');
          apiData.remove('sync_attempted');

          final response = await ApiService.addStudentResult(apiData);

          if (response['success'] && !response['offline']) {
            await db.update(
              studentResultsTable,
              {
                'is_synced': 1,
                'sync_attempted': 1,
                'updated_at': DateTime.now().toIso8601String()
              },
              where: 'id = ?',
              whereArgs: [record['id']],
            );
            successCount++;
          } else {
            await db.update(
              studentResultsTable,
              {
                'sync_attempted': 1,
                'updated_at': DateTime.now().toIso8601String()
              },
              where: 'id = ?',
              whereArgs: [record['id']],
            );
          }
        } catch (e) {
          print('Error syncing student result ${record['id']}: $e');
        }
      }

      // Sync grades
      for (var grade in unsyncedGrades) {
        try {
          Map<String, dynamic> apiData = {
            'user_id': grade['user_id'],
            'course_name': grade['course_name'],
            'semester_no': grade['semester_no'],
            'credit_hours': grade['credit_hours'],
            'marks': grade['marks'],
            'grade': grade['grade'],
          };

          final response = await ApiService.addGrade(apiData);

          if (response['success'] && !response['offline']) {
            await db.update(
              gradesTable,
              {
                'is_synced': 1,
                'sync_attempted': 1,
                'updated_at': DateTime.now().toIso8601String()
              },
              where: 'id = ?',
              whereArgs: [grade['id']],
            );
            successCount++;
          } else {
            await db.update(
              gradesTable,
              {
                'sync_attempted': 1,
                'updated_at': DateTime.now().toIso8601String()
              },
              where: 'id = ?',
              whereArgs: [grade['id']],
            );
          }
        } catch (e) {
          print('Error syncing grade ${grade['id']}: $e');
        }
      }

      return {
        'success': true,
        'message': 'Synced $successCount of $totalRecords records',
        'count': successCount,
        'total': totalRecords
      };
    } catch (e) {
      print('Error in syncAllWithApi: $e');
      return {
        'success': false,
        'message': 'Error syncing records: $e'
      };
    }
  }

  // Helper functions for data validation
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

  // Get unsynced records count (both tables)
  Future<int> getUnsyncedCount() async {
    final db = await instance.database;
    final resultsCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $studentResultsTable WHERE is_synced = 0 AND is_deleted = 0'
    )) ?? 0;

    final gradesCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $gradesTable WHERE is_synced = 0 AND is_deleted = 0'
    )) ?? 0;

    return resultsCount + gradesCount;
  }

  // Debug function to print all records in both tables
  Future<void> debugPrintAllRecords() async {
    final db = await instance.database;
    print("Debug: Printing all records in database...");

    print("STUDENT RESULTS TABLE:");
    final results = await db.rawQuery('SELECT * FROM $studentResultsTable');
    print('Total student results in database: ${results.length}');

    for (final record in results) {
      print('''
      Record ID: ${record['id']}
      Student: ${record['studentname']} (${record['rollno']})
      Course: ${record['coursecode']} - ${record['coursetitle']}
      Semester: ${record['mysemester']}
      Marks: ${record['obtainedmarks']}
      Synced: ${record['is_synced'] == 1 ? 'YES' : 'NO'}
      Deleted: ${record['is_deleted'] == 1 ? 'YES' : 'NO'}
      --------------------------
      ''');
    }

    print("\nGRADES TABLE:");
    final grades = await db.rawQuery('SELECT * FROM $gradesTable');
    print('Total grades in database: ${grades.length}');

    for (final grade in grades) {
      print('''
      Grade ID: ${grade['id']}
      User ID: ${grade['user_id']}
      Course: ${grade['course_name']}
      Semester: ${grade['semester_no']}
      Credit Hours: ${grade['credit_hours']}
      Marks: ${grade['marks']}
      Grade: ${grade['grade']}
      Synced: ${grade['is_synced'] == 1 ? 'YES' : 'NO'}
      Deleted: ${grade['is_deleted'] == 1 ? 'YES' : 'NO'}
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
  // Add this method to your DatabaseHelper class

// Update an existing grade
  Future<int> updateGrade(int id, Map<String, dynamic> grade) async {
    print('Updating grade with ID: $id');
    final db = await instance.database;

    // Update timestamps
    grade['updated_at'] = DateTime.now().toIso8601String();

    // Mark as not synced since it's been modified
    grade['is_synced'] = 0;

    final updateData = {
      'user_id': _validateString(grade['user_id'], 'user_id'),
      'course_name': _validateString(grade['course_name'], 'course_name'),
      'semester_no': _validateString(grade['semester_no'], 'semester_no'),
      'credit_hours': _validateString(grade['credit_hours'], 'credit_hours'),
      'marks': _validateString(grade['marks'], 'marks'),
      'grade': _validateString(grade['grade'], 'grade'),
      'is_synced': 0,
      'updated_at': grade['updated_at'],
    };

    final result = await db.update(
      gradesTable,
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result > 0) {
      print('Successfully updated grade ID: $id');

      // Try to sync with API if online
      _trySyncGradeWithApi(id, {
        'user_id': _validateString(grade['user_id'], 'user_id'),
        'course_name': _validateString(grade['course_name'], 'course_name'),
        'semester_no': _validateString(grade['semester_no'], 'semester_no'),
        'credit_hours': _validateString(grade['credit_hours'], 'credit_hours'),
        'marks': _validateString(grade['marks'], 'marks'),
        'grade': _validateString(grade['grade'], 'grade'),
      });
    } else {
      print('Failed to update grade ID: $id');
    }

    return result;
  }
}