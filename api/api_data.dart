import 'package:flutter/material.dart';
import 'database_helper_api.dart';
import 'api_service.dart';

class StudentResultsPage extends StatefulWidget {
  @override
  _StudentResultsPageState createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  List<Map<String, dynamic>> _studentResults = [];
  List<String> _semesters = [];
  String? _selectedSemester;
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Define a custom color scheme
  final Color _primaryColor = Color(0xFF3F51B5);       // Indigo
  final Color _secondaryColor = Color(0xFF5C6BC0);     // Lighter Indigo
  final Color _accentColor = Color(0xFFFF4081);        // Pink
  final Color _backgroundColor = Color(0xFFF5F7FF);    // Light Blue-Gray
  final Color _cardColor = Colors.white;

  // Grade colors
  final Color _excellentColor = Color(0xFF4CAF50);   // Green
  final Color _goodColor = Color(0xFFFFC107);        // Amber
  final Color _poorColor = Color(0xFFF44336);        // Red

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    setState(() => _isLoading = true);
    try {
      if (_selectedSemester != null) {
        _studentResults = await _dbHelper.getResultsBySemester(_selectedSemester!);
      } else {
        _studentResults = await _dbHelper.getAllStudentResults();
      }

      // Load available semesters for filtering
      _semesters = await _dbHelper.getDistinctSemesters();
    } catch (e) {
      _showSnackBar('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndStoreResults() async {
    setState(() => _isLoading = true);
    try {
      // First restore all results
      await _dbHelper.restoreAllResults();

      // Then fetch new data
      final apiData = await ApiService.fetchStudentResults();

      for (var result in apiData) {
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

  Widget _buildResultCard(Map<String, dynamic> result) {
    final marks = result['obtainedmarks']?.toString() ?? '';
    final marksDisplay = marks.isEmpty ? "N/A" : marks;

    // Determine grade color based on marks
    Color gradeColor = _excellentColor;
    if (double.tryParse(marks) != null) {
      double numMarks = double.parse(marks);
      if (numMarks < 50) gradeColor = _poorColor;
      else if (numMarks < 70) gradeColor = _goodColor;
    }

    // Get letter grade
    String letterGrade = "N/A";
    if (double.tryParse(marks) != null) {
      double numMarks = double.parse(marks);
      if (numMarks >= 90) letterGrade = "A+";
      else if (numMarks >= 85) letterGrade = "A";
      else if (numMarks >= 80) letterGrade = "A-";
      else if (numMarks >= 75) letterGrade = "B+";
      else if (numMarks >= 70) letterGrade = "B";
      else if (numMarks >= 65) letterGrade = "B-";
      else if (numMarks >= 60) letterGrade = "C+";
      else if (numMarks >= 55) letterGrade = "C";
      else if (numMarks >= 50) letterGrade = "C-";
      else letterGrade = "F";
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _secondaryColor.withOpacity(0.1), width: 1),
      ),
      color: _cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course header
          Container(
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${result['coursecode']} - ${result['coursetitle']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.white, size: 22),
                    onPressed: () => _deleteResult(result['id']),
                    tooltip: 'Delete Result',
                    constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          // Student info section
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student details
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.person, 'Student', result['studentname']),
                      Divider(height: 16, thickness: 1, color: Colors.grey.withOpacity(0.2)),
                      _buildInfoRow(Icons.family_restroom, 'Father', result['fathername']),
                      Divider(height: 16, thickness: 1, color: Colors.grey.withOpacity(0.2)),
                      _buildInfoRow(Icons.school, 'Program', '${result['progname']} (${result['shift']})'),
                      Divider(height: 16, thickness: 1, color: Colors.grey.withOpacity(0.2)),
                      _buildInfoRow(Icons.numbers, 'Roll No', result['rollno']),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Results section
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Credit Hours', '${result['credithours']}', _secondaryColor),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Marks', marksDisplay, gradeColor),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Grade', letterGrade, gradeColor),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Footer row with semester and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: _primaryColor),
                          SizedBox(width: 6),
                          Text(
                            'Semester ${result['mysemester']}',
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: result['consider_status'] == 'E'
                            ? _excellentColor.withOpacity(0.1)
                            : _goodColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: result['consider_status'] == 'E'
                                ? _excellentColor.withOpacity(0.2)
                                : _goodColor.withOpacity(0.2)
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            result['consider_status'] == 'E' ? Icons.check_circle : Icons.warning,
                            size: 16,
                            color: result['consider_status'] == 'E' ? _excellentColor : _goodColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            result['consider_status'] == 'E' ? 'Enrolled' : result['consider_status'],
                            style: TextStyle(
                              color: result['consider_status'] == 'E' ? _excellentColor : _goodColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _primaryColor),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Group results by semester
  Map<String, List<Map<String, dynamic>>> _groupBySemester() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var result in _studentResults) {
      final semester = result['mysemester']?.toString() ?? 'Unknown';
      if (!grouped.containsKey(semester)) {
        grouped[semester] = [];
      }
      grouped[semester]!.add(result);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedResults = _groupBySemester();
    final sortedSemesters = groupedResults.keys.toList()..sort();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Student Results',
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
          // Semester filter dropdown
          if (_semesters.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedSemester,
                  hint: Text(
                    'All Semesters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: Icon(Icons.filter_list, color: Colors.white, size: 20),
                  dropdownColor: _primaryColor,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  isDense: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSemester = newValue;
                    });
                    _loadLocalData();
                  },
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Semesters'),
                    ),
                    ..._semesters.map((semester) {
                      return DropdownMenuItem<String?>(
                        value: semester,
                        child: Text('Semester $semester'),
                      );
                    }).toList(),
                  ],
                ),
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
              'Tap the button below to fetch your results',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _fetchAndStoreResults,
              icon: Icon(Icons.cloud_download),
              label: Text('FETCH RESULTS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchAndStoreResults,
        color: _accentColor,
        child: _selectedSemester == null
            ? ListView(
          padding: EdgeInsets.only(top: 16, bottom: 80),
          children: sortedSemesters.map((semester) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryColor, _secondaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Semester $semester',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${groupedResults[semester]!.length} courses',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(indent: 16, color: Colors.grey.withOpacity(0.3))),
                    ],
                  ),
                ),
                ...groupedResults[semester]!.map((result) => _buildResultCard(result)).toList(),
                SizedBox(height: 8),
              ],
            );
          }).toList(),
        )
            : ListView.builder(
          padding: EdgeInsets.only(top: 16, bottom: 80),
          itemCount: _studentResults.length,
          itemBuilder: (context, index) {
            return _buildResultCard(_studentResults[index]);
          },
        ),
      ),
      floatingActionButton: _studentResults.isEmpty
          ? null
          : FloatingActionButton.extended(
        onPressed: _fetchAndStoreResults,
        label: Text('REFRESH'),
        icon: Icon(Icons.refresh),
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}