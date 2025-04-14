// lib/sqlite/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'user.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _dbName = 'user_database.db';

  // Singleton pattern: Private constructor and factory method
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT,
            password TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  // Insert a new user
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  // Get all users
  Future<List<User>> getUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  // Update user information and timestamp
  Future<int> updateUser(User user) async {
    final db = await database;
    user.updatedAt = DateTime.now().toIso8601String(); // Update timestamp on modification
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Delete a user
  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}