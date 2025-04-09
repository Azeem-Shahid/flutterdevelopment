class StudentResult {
  final int? id;
  final String studentName;
  final String fatherName;
  final String progName;
  final String shift;
  final String rollNo;
  final String courseCode;
  final String courseTitle;
  final double creditHours;
  final String obtainedMarks;
  final String semester;
  final String considerStatus;
  final int isDeleted;

  StudentResult({
    this.id,
    required this.studentName,
    required this.fatherName,
    required this.progName,
    required this.shift,
    required this.rollNo,
    required this.courseCode,
    required this.courseTitle,
    required this.creditHours,
    required this.obtainedMarks,
    required this.semester,
    required this.considerStatus,
    this.isDeleted = 0,
  });

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentname': studentName,
      'fathername': fatherName,
      'progname': progName,
      'shift': shift,
      'rollno': rollNo,
      'coursecode': courseCode,
      'coursetitle': courseTitle,
      'credithours': creditHours,
      'obtainedmarks': obtainedMarks,
      'mysemester': semester,
      'consider_status': considerStatus,
      'is_deleted': isDeleted,
    };
  }

  // Create from Map (from database)
  factory StudentResult.fromMap(Map<String, dynamic> map) {
    return StudentResult(
      id: map['id'],
      studentName: map['studentname'] ?? '',
      fatherName: map['fathername'] ?? '',
      progName: map['progname'] ?? '',
      shift: map['shift'] ?? '',
      rollNo: map['rollno'] ?? '',
      courseCode: map['coursecode'] ?? '',
      courseTitle: map['coursetitle'] ?? '',
      creditHours: _parseDouble(map['credithours']),
      obtainedMarks: map['obtainedmarks']?.toString() ?? '',
      semester: map['mysemester'] ?? '',
      considerStatus: map['consider_status'] ?? 'E',
      isDeleted: map['is_deleted'] ?? 0,
    );
  }

  // Helper method to parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Calculate the grade for this result
  String getGrade() {
    final numMarks = double.tryParse(obtainedMarks);
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

  // Calculate grade points for this result
  double getGradePoints() {
    final numMarks = double.tryParse(obtainedMarks);
    if (numMarks == null) return 0.0;

    if (numMarks >= 90) return 4.0;
    else if (numMarks >= 85) return 4.0;
    else if (numMarks >= 80) return 3.7;
    else if (numMarks >= 75) return 3.3;
    else if (numMarks >= 70) return 3.0;
    else if (numMarks >= 65) return 2.7;
    else if (numMarks >= 60) return 2.3;
    else if (numMarks >= 55) return 2.0;
    else if (numMarks >= 50) return 1.7;
    else return 0.0;
  }

  // Copy with method for updating values
  StudentResult copyWith({
    int? id,
    String? studentName,
    String? fatherName,
    String? progName,
    String? shift,
    String? rollNo,
    String? courseCode,
    String? courseTitle,
    double? creditHours,
    String? obtainedMarks,
    String? semester,
    String? considerStatus,
    int? isDeleted,
  }) {
    return StudentResult(
      id: id ?? this.id,
      studentName: studentName ?? this.studentName,
      fatherName: fatherName ?? this.fatherName,
      progName: progName ?? this.progName,
      shift: shift ?? this.shift,
      rollNo: rollNo ?? this.rollNo,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      creditHours: creditHours ?? this.creditHours,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
      semester: semester ?? this.semester,
      considerStatus: considerStatus ?? this.considerStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}