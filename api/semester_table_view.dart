import 'package:flutter/material.dart';

class SemesterTableView extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color excellentColor;
  final Color goodColor;
  final Color poorColor;
  final Function(int) onDeleteResult;
  final String semester;

  const SemesterTableView({
    Key? key,
    required this.results,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.excellentColor,
    required this.goodColor,
    required this.poorColor,
    required this.onDeleteResult,
    required this.semester,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate total credit hours and GPA
    double totalCreditHours = 0;
    double totalMarksProduct = 0;
    int totalEnrolledCourses = 0;
    double totalPoints = 0;

    // Get unique course results (prevents duplicates)
    final Map<String, Map<String, dynamic>> uniqueResults = {};
    for (var result in results) {
      final courseCode = result['coursecode'];
      uniqueResults[courseCode] = result;
    }
    final uniqueResultsList = uniqueResults.values.toList();

    for (var result in uniqueResultsList) {
      if (result['consider_status'] == 'E' && result['obtainedmarks'].toString().isNotEmpty) {
        final creditHours = double.tryParse(result['credithours'].toString()) ?? 0;
        final marks = double.tryParse(result['obtainedmarks'].toString()) ?? 0;
        totalCreditHours += creditHours;
        totalMarksProduct += creditHours * marks;

        // Calculate grade points for GPA
        double gradePoints = _getGradePoints(marks);
        totalPoints += creditHours * gradePoints;

        totalEnrolledCourses++;
      }
    }

    // Calculate GPA (on 4.0 scale)
    final semesterGPA = totalCreditHours > 0
        ? totalPoints / totalCreditHours
        : 0.0;

    // Calculate percentage
    final semesterPercentage = totalCreditHours > 0
        ? totalMarksProduct / totalCreditHours
        : 0.0;

    return Card(
      margin: EdgeInsets.all(16),
      elevation: 6,
      shadowColor: primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: secondaryColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Prevent vertical overflow
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Semester $semester Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$totalEnrolledCourses Courses',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSummaryCard(
                        'Credit Hours',
                        totalCreditHours.toString(),
                        Icons.credit_card,
                        Colors.white.withOpacity(0.2),
                        Colors.white,
                      ),
                      SizedBox(width: 16),
                      _buildSummaryCard(
                        'Percentage',
                        '${semesterPercentage.toStringAsFixed(1)}%',
                        Icons.percent,
                        Colors.white.withOpacity(0.2),
                        Colors.white,
                      ),
                      SizedBox(width: 16),
                      _buildSummaryCard(
                        'GPA',
                        semesterGPA.toStringAsFixed(2),
                        Icons.school,
                        Colors.white.withOpacity(0.2),
                        _getGpaColor(semesterGPA),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons - Added new row of action buttons
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Multiple Delete Buttons
                _buildActionButton(
                  'Delete Selected',
                  Icons.check_box_outline_blank,
                  poorColor,
                      () {
                    // This would be implemented with a multi-select feature
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Select functionality coming soon'),
                        backgroundColor: primaryColor,
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
                _buildActionButton(
                  'Delete Failed',
                  Icons.remove_circle_outline,
                  poorColor.withOpacity(0.8),
                      () {
                    // Find all failed courses and delete them
                    List<int> failedIds = [];
                    for (var result in uniqueResultsList) {
                      final marks = double.tryParse(result['obtainedmarks']?.toString() ?? '') ?? 0;
                      if (marks < 50 && result['consider_status'] == 'E') {
                        final id = result['id'];
                        if (id != null) failedIds.add(id);
                      }
                    }

                    if (failedIds.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No failed courses to delete'),
                          backgroundColor: primaryColor,
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Failed Courses'),
                          content: Text('Delete ${failedIds.length} failed courses?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('CANCEL'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                for (var id in failedIds) {
                                  onDeleteResult(id);
                                }
                              },
                              child: Text('DELETE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: poorColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Table UI - making it responsive
          Container(
            height: MediaQuery.of(context).size.height * 0.4, // Fixed height to prevent overflow
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width > 600
                    ? MediaQuery.of(context).size.width
                    : 600, // Minimum width for the table
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildTableHeader('Code'),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildTableHeader('Course'),
                          ),
                          Expanded(
                            flex: 1,
                            child: _buildTableHeader('CH'),
                          ),
                          Expanded(
                            flex: 1,
                            child: _buildTableHeader('Marks'),
                          ),
                          Expanded(
                            flex: 1,
                            child: _buildTableHeader('Grade'),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 48,
                            child: _buildTableHeader('Action'),
                          ),
                        ],
                      ),
                    ),

                    // Table content - using the unique results list
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3, // Fixed height with scrolling
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: uniqueResultsList.length,
                        separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.15)),
                        itemBuilder: (context, index) {
                          final result = uniqueResultsList[index];
                          final marks = result['obtainedmarks']?.toString() ?? '';
                          final gradeDisplay = _getGrade(marks);
                          final marksColor = _getColorForMarks(marks);
                          final resultId = result['id'];

                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            color: index % 2 == 0 ? Colors.grey.withOpacity(0.05) : Colors.white,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    result['coursecode'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: primaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Tooltip(
                                    message: result['coursetitle'],
                                    child: Text(
                                      result['coursetitle'],
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    result['credithours'].toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    marks.isEmpty ? 'N/A' : '$marks',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: marksColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: marksColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: marksColor.withOpacity(0.3)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      gradeDisplay,
                                      style: TextStyle(
                                        color: marksColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                result['consider_status'] == 'E'
                                    ? Container(
                                  width: 40,
                                  height: 40,
                                  child: IconButton(
                                    icon: Icon(Icons.delete_outline, color: poorColor.withOpacity(0.7), size: 20),
                                    onPressed: resultId != null ? () {
                                      // Show confirmation dialog
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Delete Result'),
                                          content: Text('Delete ${result['coursetitle']} result?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('CANCEL'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                // Call the delete function
                                                onDeleteResult(resultId);
                                              },
                                              child: Text('DELETE'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: poorColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } : null,
                                    tooltip: 'Delete Result',
                                    padding: EdgeInsets.all(0),
                                  ),
                                )
                                    : Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    result['consider_status'],
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend and info - Reduced size to save space
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grade System',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildGradeChip('A+ (4.0): 90-100', excellentColor),
                      _buildGradeChip('A (4.0): 85-89', excellentColor),
                      _buildGradeChip('A- (3.7): 80-84', excellentColor),
                      _buildGradeChip('B+ (3.3): 75-79', goodColor),
                      _buildGradeChip('B (3.0): 70-74', goodColor),
                      _buildGradeChip('B- (2.7): 65-69', goodColor),
                      _buildGradeChip('C+ (2.3): 60-64', Colors.amber),
                      _buildGradeChip('C (2.0): 55-59', Colors.amber),
                      _buildGradeChip('C- (1.7): 50-54', Colors.amber),
                      _buildGradeChip('F (0.0): <50', poorColor),
                    ],
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: primaryColor,
        fontSize: 15,
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color bgColor, Color textColor, {bool isBold = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: textColor, size: 18),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeChip(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(right: 8, bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  double _getGradePoints(double marks) {
    if (marks >= 90) return 4.0;
    else if (marks >= 85) return 4.0;
    else if (marks >= 80) return 3.7;
    else if (marks >= 75) return 3.3;
    else if (marks >= 70) return 3.0;
    else if (marks >= 65) return 2.7;
    else if (marks >= 60) return 2.3;
    else if (marks >= 55) return 2.0;
    else if (marks >= 50) return 1.7;
    else return 0.0;
  }

  String _getGrade(String marks) {
    if (marks.isEmpty) return "N/A";

    final numMarks = double.tryParse(marks);
    if (numMarks == null) return "N/A";

    if (numMarks >= 90) return "A+";
    else if (numMarks >= 85) return "A";
    else if (numMarks >= 80) return "A-";
    else if (numMarks >= 75) return "B+";
    else if (numMarks >= 70) return "B";
    else if (numMarks >= 65) return "B-";
    else if (numMarks >= 60) return "C+";
    else if (numMarks >= 55) return "C";
    else if (numMarks >= 50) return "C-";
    else return "F";
  }

  Color _getColorForMarks(String marks) {
    if (marks.isEmpty) return Colors.grey;

    final numMarks = double.tryParse(marks);
    if (numMarks == null) return Colors.grey;

    if (numMarks < 50) return poorColor;
    else if (numMarks < 70) return goodColor;
    return excellentColor;
  }

  Color _getGpaColor(double gpa) {
    if (gpa < 2.0) return poorColor;
    else if (gpa < 3.0) return goodColor;
    return excellentColor;
  }
}