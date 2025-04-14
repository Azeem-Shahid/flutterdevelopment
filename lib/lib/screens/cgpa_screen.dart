import 'package:flutter/material.dart';
import '../widgets/custom_footer.dart';
import '../widgets/custom_drawer.dart'; // Import Custom Drawer

class CGPAResultScreen extends StatelessWidget {
  // Sample CGPA data
  final String studentName = "Azeem Shahid";
  final String studentID = "AZ12345";
  final double cgpa = 3.75; // CGPA out of 4.0

  final List<Map<String, dynamic>> courses = [
    {"name": "Mathematics", "grade": "A", "gpa": 4.0},
    {"name": "Physics", "grade": "B+", "gpa": 3.5},
    {"name": "Computer Science", "grade": "A", "gpa": 4.0},
    {"name": "Chemistry", "grade": "B", "gpa": 3.0},
    {"name": "English", "grade": "A-", "gpa": 3.7},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Dark theme background
      appBar: AppBar(
        title: Text(
          "CGPA Result",
          style: TextStyle(
            fontWeight: FontWeight.bold, // ✅ Make text bold
            fontSize: 22, // ✅ Set font size
          ),
        ),
        centerTitle: true, // ✅ Center the title
        backgroundColor: Colors.orange, // ✅ Keep color consistent
      ),
      drawer: CustomDrawer(), // ✅ Include the custom drawer here
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  _buildStudentInfoCard(),
                  SizedBox(height: 20),
                  _buildCGPAProgressBar(),
                  SizedBox(height: 20),
                  Text(
                    "Courses & Grades",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold, // ✅ Heading is bolded
                    ),
                  ),
                  SizedBox(height: 10),
                  Column(
                    children: courses.map((course) => _buildCourseCard(course)).toList(),
                  ),
                ],
              ),
            ),
          ),
          CustomFooter(), // ✅ Footer at the bottom
        ],
      ),
    );
  }

  // Widget: Student Info Card
  Widget _buildStudentInfoCard() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.account_circle, size: 50, color: Colors.orange),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600, // ✅ Increased font weight
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "ID: $studentID",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget: CGPA Progress Bar
  Widget _buildCGPAProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CGPA: $cgpa / 4.0",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold, // ✅ Bold text for better visibility
          ),
        ),
        SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: cgpa / 4.0, // Normalize CGPA between 0 to 1
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 14, // ✅ Slightly increased for better visibility
          ),
        ),
      ],
    );
  }

  // Widget: Course Card
  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.book, color: Colors.orange),
        title: Text(
          course["name"],
          style: TextStyle(
            color: Colors.white,
            fontSize: 18, // ✅ Increased font size
            fontWeight: FontWeight.w600, // ✅ Thicker text for readability
          ),
        ),
        subtitle: Text(
          "Grade: ${course["grade"]} | GPA: ${course["gpa"]}",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16, // ✅ Increased font size
            fontWeight: FontWeight.w500, // ✅ Slightly thicker
          ),
        ),
      ),
    );
  }
}
