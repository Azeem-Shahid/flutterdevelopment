import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentGradeScreen extends StatefulWidget {
  @override
  _StudentGradeScreenState createState() => _StudentGradeScreenState();
}

class _StudentGradeScreenState extends State<StudentGradeScreen> {
  final TextEditingController _userIdController = TextEditingController();
  List<dynamic> _grades = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Colors
  final Color _primaryColor = Color(0xFF5E35B1);
  final Color _accentColor = Color(0xFFFF6D00);
  final Color _backgroundColor = Color(0xFFF8F9FE);

  Future<void> _fetchAllGrades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _grades = [];
    });

    try {
      final response = await http.get(
        Uri.parse('https://devtechtop.com/management/public/api/select_data'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle both possible response formats:
        // 1. Direct array of grades
        // 2. Object with 'data' field containing array
        if (responseData is List) {
          setState(() {
            _grades = responseData;
            _isLoading = false;
          });
        } else if (responseData is Map && responseData.containsKey('data')) {
          setState(() {
            _grades = responseData['data'] is List ? responseData['data'] : [];
            _isLoading = false;
          });
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        throw Exception('Failed to load grades: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchGradesByUserId() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a user ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _grades = [];
    });

    try {
      final response = await http.get(
        Uri.parse('https://devtechtop.com/management/public/api/select_data'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> grades = [];

        // Handle both response formats
        if (responseData is List) {
          grades = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          grades = responseData['data'] is List ? responseData['data'] : [];
        } else {
          throw Exception('Unexpected data format');
        }

        final filteredGrades = grades.where((grade) =>
        grade['user_id']?.toString() == userId).toList();

        setState(() {
          _grades = filteredGrades;
          _isLoading = false;
          if (filteredGrades.isEmpty) {
            _errorMessage = 'No grades found for user ID: $userId';
          }
        });
      } else {
        throw Exception('Failed to load grades: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _calculateGradeLetter(String marksStr) {
    double marks = double.tryParse(marksStr) ?? 0;
    if (marks >= 90) return 'A';
    if (marks >= 80) return 'B';
    if (marks >= 70) return 'C';
    if (marks >= 60) return 'D';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange[700]!;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Student Grades', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search by User ID
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: InputDecoration(
                      labelText: 'Enter User ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _fetchGradesByUserId,
                  child: Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Fetch All Button
            ElevatedButton(
              onPressed: _fetchAllGrades,
              child: Text('Fetch All Grades'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                minimumSize: Size(double.infinity, 0),
              ),
            ),
            SizedBox(height: 20),

            // Status Messages
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            SizedBox(height: 10),

            // Loading Indicator
            if (_isLoading)
              CircularProgressIndicator(color: _primaryColor),

            // Grades List
            Expanded(
              child: _grades.isEmpty && !_isLoading
                  ? Center(
                child: Text(
                  'No grades to display',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _grades.length,
                itemBuilder: (context, index) {
                  final grade = _grades[index];
                  final gradeLetter = _calculateGradeLetter(grade['marks']?.toString() ?? '0');

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getGradeColor(gradeLetter),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          gradeLetter,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        grade['course_name']?.toString() ?? 'No Course Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User ID: ${grade['user_id']}'),
                          Text('Semester: ${grade['semester_no']}'),
                          Text('Credit Hours: ${grade['credit_hours']}'),
                          Text('Marks: ${grade['marks']}'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
}