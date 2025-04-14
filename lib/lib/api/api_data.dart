import 'package:flutter/material.dart';
import 'database_helper_api.dart';
import 'api_service.dart';
import 'semester_table_view.dart';
import 'add_result_form.dart'; // Import the new form

class StudentResultsPage extends StatefulWidget {
  @override
  _StudentResultsPageState createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _studentResults = [];
  List<String> _semesters = [];
  String? _selectedSemester;
  bool _isLoading = false;

  // Initialize the controller properly
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isTabControllerInitialized = false;

  // Define a more modern color scheme
  final Color _primaryColor = Color(0xFF5E35B1);       // Deep Purple
  final Color _secondaryColor = Color(0xFF7E57C2);     // Medium Purple
  final Color _accentColor = Color(0xFFFF6D00);        // Deep Orange
  final Color _backgroundColor = Color(0xFFF8F9FE);    // Light Gray-Blue
  final Color _cardColor = Colors.white;

  // Grade colors
  final Color _excellentColor = Color(0xFF43A047);   // Green
  final Color _goodColor = Color(0xFFFFA000);        // Amber
  final Color _poorColor = Color(0xFFE53935);        // Red

  @override
  void initState() {
    super.initState();
    // Initialize with this as vsync
    _tabController = TabController(length: 1, vsync: this);
    _loadLocalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initTabController() {
    try {
      // Dispose old controller if it exists
      if (_isTabControllerInitialized) {
        _tabController.dispose();
      }

      // Create new controller with correct length
      _tabController = TabController(
        length: _semesters.length + 1, // +1 for "All Semesters" tab
        vsync: this,
      );

      _isTabControllerInitialized = true;

      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          if (_tabController.index == 0) {
            setState(() {
              _selectedSemester = null;
            });
          } else {
            setState(() {
              _selectedSemester = _semesters[_tabController.index - 1];
            });
          }
          _loadLocalData();
        }
      });
    } catch (e) {
      print("Error initializing tab controller: $e");
      // Fallback to simpler initialization
      _tabController = TabController(length: 1, vsync: this);
      _isTabControllerInitialized = false;
    }
  }

  // Function to open the Add Result form
  void _openAddResultForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddResultForm(
          onResultAdded: () {
            // Reload data when a new result is added
            _loadLocalData();
          },
        ),
      ),
    );
  }

  // Helper function to remove duplicate results
  List<Map<String, dynamic>> _removeDuplicates(List<Map<String, dynamic>> results) {
    final Map<String, Map<String, dynamic>> uniqueResults = {};

    for (var result in results) {
      final key = "${result['mysemester']}-${result['coursecode']}";
      uniqueResults[key] = result;
    }

    return uniqueResults.values.toList();
  }

  Future<void> _loadLocalData() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> results;

      if (_selectedSemester != null) {
        results = await _dbHelper.getResultsBySemester(_selectedSemester!);
      } else {
        results = await _dbHelper.getAllStudentResults();
      }

      // Remove any duplicate results
      results = _removeDuplicates(results);

      setState(() {
        _studentResults = results;
      });

      // Load available semesters for filtering
      _semesters = await _dbHelper.getDistinctSemesters();

      // Sort semesters numerically
      _semesters.sort((a, b) {
        int aNum = int.tryParse(a) ?? 0;
        int bNum = int.tryParse(b) ?? 0;
        return aNum.compareTo(bNum);
      });

      // Initialize tab controller if needed
      if (_semesters.isNotEmpty && !_isTabControllerInitialized) {
        _initTabController();
      }
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndStoreResults() async {
    setState(() => _isLoading = true);
    try {
      // Then fetch new data
      final apiData = await ApiService.fetchStudentResults();

      // Remove any duplicates from the API data
      final Map<String, dynamic> uniqueApiData = {};
      for (var result in apiData) {
        final key = "${result['mysemester']}-${result['coursecode']}";
        uniqueApiData[key] = result;
      }

      final uniqueResults = uniqueApiData.values.toList();

      // Clear existing data to prevent duplicates
      await _dbHelper.deleteAllResults();

      // Insert unique results
      for (var result in uniqueResults) {
        await _dbHelper.insertStudentResult(result);
      }

      await _loadLocalData();
      _showSnackBar('Data refreshed successfully!');
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteResult(int id) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Result',
      'Are you sure you want to delete this result?',
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _dbHelper.deleteResult(id);
        await _loadLocalData();
        _showSnackBar('Result deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSemesterResults(String semester) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Semester',
      'Are you sure you want to delete all results for Semester $semester?',
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        // Get all results for this semester
        final semesterResults = await _dbHelper.getResultsBySemester(semester);

        // Delete each result
        for (var result in semesterResults) {
          await _dbHelper.deleteResult(result['id']);
        }

        await _loadLocalData();
        _showSnackBar('Semester $semester results deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting semester results: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAllResults() async {
    final confirmed = await _showConfirmationDialog(
      'Delete All Results',
      'Are you sure you want to delete all results? This action cannot be undone.',
    );

    if (confirmed) {
      setState(() => _isLoading = true);
      try {
        await _dbHelper.deleteAllResults();
        await _loadLocalData();
        _showSnackBar('All results deleted');
      } catch (e) {
        _showSnackBar('Error deleting all: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primaryColor.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        elevation: 5,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('CONFIRM'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  // Group results by semester and ensure no duplicates
  Map<String, List<Map<String, dynamic>>> _groupBySemester() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final processedCourses = <String>{};

    for (var result in _studentResults) {
      final semester = result['mysemester']?.toString() ?? 'Unknown';
      final courseCode = result['coursecode']?.toString() ?? '';
      final key = "$semester-$courseCode";

      // Skip if we've already processed this course for this semester
      if (processedCourses.contains(key)) continue;

      if (!grouped.containsKey(semester)) {
        grouped[semester] = [];
      }

      grouped[semester]!.add(result);
      processedCourses.add(key);
    }

    return grouped;
  }

  Widget _buildSummaryHeader() {
    // Calculate overall stats
    double totalCreditHours = 0;
    double totalPoints = 0;
    int totalEnrolledCourses = 0;

    for (var result in _studentResults) {
      if (result['consider_status'] == 'E' && result['obtainedmarks'].toString().isNotEmpty) {
        final creditHours = double.tryParse(result['credithours'].toString()) ?? 0;
        final marks = double.tryParse(result['obtainedmarks'].toString()) ?? 0;

        // Calculate grade points
        double gradePoints = 0;
        if (marks >= 90) gradePoints = 4.0;
        else if (marks >= 85) gradePoints = 4.0;
        else if (marks >= 80) gradePoints = 3.7;
        else if (marks >= 75) gradePoints = 3.3;
        else if (marks >= 70) gradePoints = 3.0;
        else if (marks >= 65) gradePoints = 2.7;
        else if (marks >= 60) gradePoints = 2.3;
        else if (marks >= 55) gradePoints = 2.0;
        else if (marks >= 50) gradePoints = 1.7;
        else gradePoints = 0.0;

        totalCreditHours += creditHours;
        totalPoints += creditHours * gradePoints;
        totalEnrolledCourses++;
      }
    }

    // Calculate CGPA
    final cGPA = totalCreditHours > 0 ? totalPoints / totalCreditHours : 0.0;

    // Get color based on CGPA
    Color gpaColor = _excellentColor;
    if (cGPA < 2.0) gpaColor = _poorColor;
    else if (cGPA < 3.0) gpaColor = _goodColor;

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 6,
      shadowColor: _primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor, _secondaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent vertical overflow
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Overall performance across all semesters',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        '$totalEnrolledCourses Courses',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSummaryStatCard(
                    'Credit Hours',
                    totalCreditHours.toStringAsFixed(1),
                    Icons.credit_card,
                  ),
                  SizedBox(width: 16),
                  _buildSummaryStatCard(
                    'CGPA',
                    cGPA.toStringAsFixed(2),
                    Icons.trending_up,
                    valueColor: gpaColor,
                  ),
                  SizedBox(width: 16),
                  _buildSummaryStatCard(
                    'Semesters',
                    _semesters.length.toString(),
                    Icons.calendar_today,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStatCard(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent vertical overflow
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedResults = _groupBySemester();
    final sortedSemesters = groupedResults.keys.toList()..sort((a, b) {
      int aNum = int.tryParse(a) ?? 0;
      int bNum = int.tryParse(b) ?? 0;
      return aNum.compareTo(bNum);
    });

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Academic Report',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: _primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          // Add new result button
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: _openAddResultForm,
              tooltip: 'Add New Result',
            ),
          ),

          // Refresh button
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchAndStoreResults,
              tooltip: 'Refresh Data',
            ),
          ),

          // Delete all button
          Container(
            margin: EdgeInsets.only(right: 8, left: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _deleteAllResults,
              tooltip: 'Delete All Results',
            ),
          ),
        ],
        // Fix the TabBar implementation to avoid null errors
        bottom: _semesters.isNotEmpty
            ? PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: DefaultTabController(
              length: _semesters.length + 1,
              child: TabBar(
                isScrollable: true,
                indicatorColor: _accentColor,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
                onTap: (index) {
                  setState(() {
                    if (index == 0) {
                      _selectedSemester = null;
                    } else {
                      _selectedSemester = _semesters[index - 1];
                    }
                    _loadLocalData();
                  });
                },
                tabs: [
                  Tab(text: 'All Semesters'),
                  ..._semesters.map((semester) => Tab(text: 'Semester $semester')).toList(),
                ],
              ),
            ),
          ),
        )
            : null,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            SizedBox(height: 16),
            Text(
              'Loading results...',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : _studentResults.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 64,
              color: _primaryColor.withOpacity(0.7),
            ),
            SizedBox(height: 20),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Add a new result or fetch from server',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _openAddResultForm,
                  icon: Icon(Icons.add),
                  label: Text('ADD RESULT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _fetchAndStoreResults,
                  icon: Icon(Icons.cloud_download),
                  label: Text('FETCH FROM SERVER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchAndStoreResults,
        color: _accentColor,
        child: ListView(
          padding: EdgeInsets.only(bottom: 80),
          children: [
            // Only show summary header when viewing all semesters
            if (_selectedSemester == null) _buildSummaryHeader(),

            // For all semesters view, show each semester in a table view
            if (_selectedSemester == null)
              ...sortedSemesters.map((semester) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add semester delete button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Add New Result for this semester button
                          ElevatedButton.icon(
                            onPressed: _openAddResultForm,
                            icon: Icon(Icons.add, size: 18),
                            label: Text('Add to Semester $semester'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: TextStyle(fontSize: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                          // Delete semester button
                          ElevatedButton.icon(
                            onPressed: () => _deleteSemesterResults(semester),
                            icon: Icon(Icons.delete, size: 18),
                            label: Text('Delete Semester $semester'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _poorColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: TextStyle(fontSize: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SemesterTableView(
                      results: groupedResults[semester]!,
                      primaryColor: _primaryColor,
                      secondaryColor: _secondaryColor,
                      accentColor: _accentColor,
                      excellentColor: _excellentColor,
                      goodColor: _goodColor,
                      poorColor: _poorColor,
                      onDeleteResult: _deleteResult,
                      semester: semester,
                    ),
                  ],
                );
              }).toList()
            // For single semester view, show just that semester
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add buttons for single semester view
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Add New Result for this semester button
                        ElevatedButton.icon(
                          onPressed: _openAddResultForm,
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Add to Semester ${_selectedSemester}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accentColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: TextStyle(fontSize: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        ),
                        // Delete semester button
                        ElevatedButton.icon(
                          onPressed: () => _deleteSemesterResults(_selectedSemester!),
                          icon: Icon(Icons.delete, size: 18),
                          label: Text('Delete Semester ${_selectedSemester}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _poorColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: TextStyle(fontSize: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SemesterTableView(
                    results: _studentResults,
                    primaryColor: _primaryColor,
                    secondaryColor: _secondaryColor,
                    accentColor: _accentColor,
                    excellentColor: _excellentColor,
                    goodColor: _goodColor,
                    poorColor: _poorColor,
                    onDeleteResult: _deleteResult,
                    semester: _selectedSemester!,
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddResultForm,
        label: Text('ADD RESULT'),
        icon: Icon(Icons.add),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}