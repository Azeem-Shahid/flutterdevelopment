import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_package; // Changed to avoid naming conflict

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database at app startup
  final database = await DatabaseHelper.instance.database;

  runApp(const SubjectMarksApp());
}

class SubjectMarksApp extends StatelessWidget {
  const SubjectMarksApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subject Marks Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SubjectMarksScreen(),
    );
  }
}

// Database Helper Class to manage database operations
class DatabaseHelper {
  static const _databaseName = "subject_marks.db";
  static const _databaseVersion = 1;
  static const table = 'marks';

  // Singleton pattern implementation
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String dbPath = path_package.join(await getDatabasesPath(), _databaseName); // Using the renamed import
    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Create database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        marks INTEGER NOT NULL
      )
    ''');
  }

  // Database CRUD operations
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  Future<int> deleteAll() async {
    Database db = await instance.database;
    return await db.delete(table);
  }
}

// Subject and Grade Models
class Subject {
  final String name;
  const Subject(this.name);
}

class Grade {
  static String calculateGrade(int marks) {
    if (marks >= 85) return 'A';
    if (marks >= 75) return 'B+';
    if (marks >= 65) return 'B';
    if (marks >= 55) return 'C+';
    if (marks >= 51) return 'C';
    if (marks >= 47) return 'D+';
    if (marks >= 43) return 'D';
    return 'F';
  }

  static double calculateGPA(int marks) {
    if (marks >= 80) return 4.0;
    if (marks >= 75) return 3.67;
    if (marks >= 70) return 3.33;
    if (marks >= 65) return 3.0;
    if (marks >= 60) return 2.67;
    if (marks >= 55) return 2.33;
    if (marks >= 51) return 2.0;
    if (marks >= 47) return 1.67;
    if (marks >= 43) return 1.33;
    if (marks >= 40) return 1.0;
    return 0.0;
  }
}

class SubjectMarksScreen extends StatefulWidget {
  const SubjectMarksScreen({Key? key}) : super(key: key);

  @override
  _SubjectMarksScreenState createState() => _SubjectMarksScreenState();
}

class _SubjectMarksScreenState extends State<SubjectMarksScreen> {
  // List of available subjects
  final List<Subject> subjects = const [
    Subject('E-Commerce'),
    Subject('Numerical Computing'),
    Subject('Professional Practice'),
    Subject('Operating System'),
    Subject('Theory of Automata'),
    Subject('Data Structure and Algorithm'),
    Subject('App Development'),
  ];

  String? selectedSubject;
  final TextEditingController marksController = TextEditingController();
  List<Map<String, dynamic>> subjectMarks = [];
  int totalMarks = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectMarks();
  }

  @override
  void dispose() {
    marksController.dispose();
    super.dispose();
  }

  Future<void> _addSubjectMarks() async {
    if (selectedSubject == null) {
      _showSnackBar('Please select a subject');
      return;
    }

    int? marks = int.tryParse(marksController.text);

    if (marks == null) {
      _showSnackBar('Please enter valid marks');
      return;
    }

    if (marks < 0 || marks > 100) {
      _showSnackBar('Marks must be between 0 and 100');
      return;
    }

    try {
      await DatabaseHelper.instance.insert({
        'subject': selectedSubject,
        'marks': marks,
      });

      setState(() {
        selectedSubject = null;
        marksController.clear();
      });

      _loadSubjectMarks();
      _showSnackBar('Marks added successfully');
    } catch (e) {
      _showSnackBar('Error adding marks: $e');
    }
  }

  Future<void> _removeAllRecords() async {
    try {
      await DatabaseHelper.instance.deleteAll();
      _loadSubjectMarks();
      _showSnackBar('All records removed');
    } catch (e) {
      _showSnackBar('Error removing records: $e');
    }
  }

  Future<void> _loadSubjectMarks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await DatabaseHelper.instance.queryAllRows();
      setState(() {
        subjectMarks = data;
        totalMarks = subjectMarks.fold(0, (sum, item) => sum + (item['marks'] as int));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Error loading data: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog( // Fixed BuildContext
        title: const Text('Remove All Records'),
        content: const Text('Are you sure you want to remove all records? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Use dialogContext
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Use dialogContext
              _removeAllRecords();
            },
            child: const Text('REMOVE ALL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalGPA = subjectMarks.isNotEmpty
        ? subjectMarks.fold(0.0, (sum, item) => sum + Grade.calculateGPA(item['marks'] as int)) / subjectMarks.length
        : 0.0;

    double totalPercentage = subjectMarks.isNotEmpty
        ? (totalMarks / (subjectMarks.length * 100)) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Marks Tracker'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add New Subject Marks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      hint: const Text('Select Subject'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() => selectedSubject = value);
                      },
                      items: subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject.name,
                          child: Text(subject.name),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: marksController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Marks (0-100)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addSubjectMarks,
                            icon: const Icon(Icons.add),
                            label: const Text('ADD MARKS'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subject Marks Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subjectMarks.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: _showConfirmDialog,
                            tooltip: 'Remove All Records',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (subjectMarks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Subject')),
                            DataColumn(label: Text('Marks')),
                            DataColumn(label: Text('Grade')),
                            DataColumn(label: Text('GPA')),
                          ],
                          rows: subjectMarks.map((item) {
                            final marks = item['marks'] as int;
                            return DataRow(cells: [
                              DataCell(Text(item['subject'])),
                              DataCell(Text('$marks')),
                              DataCell(Text(Grade.calculateGrade(marks))),
                              DataCell(Text(Grade.calculateGPA(marks).toStringAsFixed(2))),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No subject marks added yet'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (subjectMarks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('Total Marks', '$totalMarks / ${subjectMarks.length * 100}'),
                      const SizedBox(height: 8),
                      _buildStatRow('Percentage', '${totalPercentage.toStringAsFixed(2)}%'),
                      const SizedBox(height: 8),
                      _buildStatRow('GPA', totalGPA.toStringAsFixed(2)),
                      const SizedBox(height: 8),
                      _buildStatRow('Grade', Grade.calculateGrade((totalPercentage).round())),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}