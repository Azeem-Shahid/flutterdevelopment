import 'package:flutter/material.dart';
import 'database_helper_api.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'api_service.dart';
import 'course_dropdown.dart';

class AddResultForm extends StatefulWidget {
  final Function onResultAdded;

  const AddResultForm({Key? key, required this.onResultAdded}) : super(key: key);

  @override
  _AddResultFormState createState() => _AddResultFormState();
}

class _AddResultFormState extends State<AddResultForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = false;
  bool _isOffline = false;

  // For tracking connectivity
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Form controllers
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _progNameController = TextEditingController();
  final TextEditingController _shiftController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
  final TextEditingController _courseTitleController = TextEditingController();
  final TextEditingController _creditHoursController = TextEditingController();
  final TextEditingController _obtainedMarksController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();

  String _considerStatus = 'E'; // Default to 'E' (Enrolled)

  // Define more modern colors to match your app
  final Color _primaryColor = Color(0xFF5E35B1); // Deep Purple
  final Color _secondaryColor = Color(0xFF7E57C2); // Medium Purple
  final Color _accentColor = Color(0xFFFF6D00); // Deep Orange
  final Color _backgroundColor = Color(0xFFF8F9FE); // Light Gray-Blue
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();

    // Check initial connectivity
    _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    // Clean up controllers and subscriptions
    _studentNameController.dispose();
    _fatherNameController.dispose();
    _progNameController.dispose();
    _shiftController.dispose();
    _rollNoController.dispose();
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _creditHoursController.dispose();
    _obtainedMarksController.dispose();
    _semesterController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  // Handle course selection from dropdown
  void _handleCourseSelected(String courseCode, String courseName) {
    setState(() {
      _courseCodeController.text = courseCode;
      _courseTitleController.text = courseName;
    });
  }

  // Calculate letter grade from marks
  String _calculateGrade(String marksStr) {
    if (marksStr.isEmpty) return 'F';

    double marks;
    try {
      marks = double.parse(marksStr);
    } catch (e) {
      return 'F';
    }

    if (marks >= 90) return 'A';
    if (marks >= 80) return 'B';
    if (marks >= 70) return 'C';
    if (marks >= 60) return 'D';
    return 'F';
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare data for insertion
        final resultData = {
          'studentname': _studentNameController.text,
          'fathername': _fatherNameController.text,
          'progname': _progNameController.text,
          'shift': _shiftController.text,
          'rollno': _rollNoController.text,
          'coursecode': _courseCodeController.text,
          'coursetitle': _courseTitleController.text,
          'credithours': _creditHoursController.text,
          'obtainedmarks': _obtainedMarksController.text,
          'mysemester': _semesterController.text,
          'consider_status': _considerStatus,
          'is_deleted': 0,
        };

        // Also prepare data for direct API submission
        final apiGradeData = {
          'user_id': _rollNoController.text,
          'course_name': _courseTitleController.text,
          'semester_no': _semesterController.text,
          'credit_hours': _creditHoursController.text,
          'marks': _obtainedMarksController.text,
          'grade': _calculateGrade(_obtainedMarksController.text),
        };

        // Insert into database (which will attempt to sync with API)
        final id = await _dbHelper.insertStudentResult(resultData);

        // Also try direct API submission if online
        bool apiSuccess = false;
        if (!_isOffline) {
          try {
            final apiResponse = await ApiService.addGrade(apiGradeData);
            apiSuccess = apiResponse['success'] && !apiResponse['offline'];
          } catch (e) {
            print('Direct API submission error: $e');
            // Continue with local success message
          }
        }

        if (id > 0) {
          // Determine message based on connectivity and API success
          String message;
          if (_isOffline) {
            message = 'Result added locally. Will sync when online.';
          } else if (apiSuccess) {
            message = 'Result added successfully to API!';
          } else {
            message = 'Result added successfully!';
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: _primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.all(10),
            ),
          );

          // Clear form
          _formKey.currentState!.reset();
          _clearForm();

          // Notify parent widget to refresh data
          widget.onResultAdded();

          // If online, attempt to sync all pending records
          if (!_isOffline) {
            _dbHelper.syncAllWithApi();
          }

          // Close the form screen after a short delay
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding result: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(10),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _studentNameController.clear();
    _fatherNameController.clear();
    _progNameController.clear();
    _shiftController.clear();
    _rollNoController.clear();
    _courseCodeController.clear();
    _courseTitleController.clear();
    _creditHoursController.clear();
    _obtainedMarksController.clear();
    _semesterController.clear();
    setState(() {
      _considerStatus = 'E';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add New Result',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _clearForm,
            icon: Icon(Icons.refresh, color: Colors.white),
            label: Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: _primaryColor),
      )
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connectivity status indicator
              if (_isOffline)
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange.shade800),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are offline. Results will be saved locally and synchronized when online.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildSectionHeader('Student Information'),
              SizedBox(height: 16),
              _buildTextFormField(
                controller: _studentNameController,
                label: 'Student Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              _buildTextFormField(
                controller: _fatherNameController,
                label: 'Father\'s Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter father\'s name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              _buildTextFormField(
                controller: _rollNoController,
                label: 'Roll Number (User ID)',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter roll number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _progNameController,
                      label: 'Program',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter program';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _shiftController,
                      label: 'Shift',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter shift';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),
              _buildSectionHeader('Course Information'),
              SizedBox(height: 16),

              // Course Dropdown - Will fetch from API
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: CourseDropdown(
                  onCourseSelected: _handleCourseSelected,
                  userId: _rollNoController.text.isNotEmpty ? _rollNoController.text : null,
                  primaryColor: _primaryColor,
                ),
              ),

              // Keep the original course code field as backup
              _buildTextFormField(
                controller: _courseCodeController,
                label: 'Course Code',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter or select a course code';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              _buildTextFormField(
                controller: _courseTitleController,
                label: 'Course Title',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _creditHoursController,
                      label: 'Credit Hours',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter credit hours';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _semesterController,
                      label: 'Semester',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter semester';
                        }
                        // Check if semester is a valid number
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid semester number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildTextFormField(
                controller: _obtainedMarksController,
                label: 'Obtained Marks',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter obtained marks';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  final marks = double.parse(value);
                  if (marks < 0 || marks > 100) {
                    return 'Marks must be between 0 and 100';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _primaryColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusOption('E', 'Enrolled'),
                        SizedBox(width: 12),
                        _buildStatusOption('W', 'Withdrawn'),
                        SizedBox(width: 12),
                        _buildStatusOption('I', 'Incomplete'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'SAVE RESULT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _primaryColor.withOpacity(0.7)),
          floatingLabelStyle: TextStyle(color: _primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStatusOption(String value, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _considerStatus = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _considerStatus == value
                ? _primaryColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _considerStatus == value
                  ? _primaryColor
                  : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _considerStatus == value
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: _considerStatus == value
                    ? _primaryColor
                    : Colors.grey,
                size: 20,
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _considerStatus == value
                      ? _primaryColor
                      : Colors.grey[800],
                  fontWeight: _considerStatus == value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}