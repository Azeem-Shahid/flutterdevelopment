import 'package:flutter/material.dart';
import 'dart:async';
import 'api_service.dart';
import 'database_helper_api.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'course_dropdown.dart';

class AddGradeForm extends StatefulWidget {
  final Function onGradeAdded;
  final Map<String, dynamic>? gradeToEdit; // Optional parameter for editing existing grades

  const AddGradeForm({
    Key? key,
    required this.onGradeAdded,
    this.gradeToEdit,
  }) : super(key: key);

  @override
  _AddGradeFormState createState() => _AddGradeFormState();
}

class _AddGradeFormState extends State<AddGradeForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _creditHoursController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();

  bool _isLoading = false;
  bool _isOffline = false;
  String? _calculatedGrade;
  bool _isEditMode = false;
  int? _editingGradeId;

  // For tracking connectivity
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Define a more modern color scheme (matching your existing app)
  final Color _primaryColor = Color(0xFF5E35B1); // Deep Purple
  // ignore: unused_field
  final Color _secondaryColor = Color(0xFF7E57C2); // Medium Purple
  final Color _accentColor = Color(0xFFFF6D00); // Deep Orange
  final Color _backgroundColor = Color(0xFFF8F9FE); // Light Gray-Blue
  // ignore: unused_field
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();

    // Check if we're in edit mode
    if (widget.gradeToEdit != null) {
      _isEditMode = true;
      _editingGradeId = widget.gradeToEdit!['id'];

      // Populate form fields with existing data
      _userIdController.text = widget.gradeToEdit!['user_id']?.toString() ?? '';
      _courseNameController.text = widget.gradeToEdit!['course_name']?.toString() ?? '';
      _semesterController.text = widget.gradeToEdit!['semester_no']?.toString() ?? '';
      _creditHoursController.text = widget.gradeToEdit!['credit_hours']?.toString() ?? '';
      _marksController.text = widget.gradeToEdit!['marks']?.toString() ?? '';

      // Calculate grade if needed
      if (widget.gradeToEdit!['grade'] != null && widget.gradeToEdit!['grade'].toString().isNotEmpty) {
        _calculatedGrade = widget.gradeToEdit!['grade'].toString();
      } else {
        _calculateGradeFromMarks(_marksController.text);
      }
    }

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

    // Add listener to marks field to calculate grade
    _marksController.addListener(_onMarksChanged);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _courseNameController.dispose();
    _semesterController.dispose();
    _creditHoursController.dispose();
    _marksController.dispose();
    _marksController.removeListener(_onMarksChanged);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  void _onMarksChanged() {
    _calculateGradeFromMarks(_marksController.text);
  }

  void _calculateGradeFromMarks(String marksStr) {
    if (marksStr.isNotEmpty) {
      try {
        double marks = double.parse(marksStr);
        String grade;

        if (marks >= 90) grade = 'A';
        else if (marks >= 80) grade = 'B';
        else if (marks >= 70) grade = 'C';
        else if (marks >= 60) grade = 'D';
        else grade = 'F';

        setState(() {
          _calculatedGrade = grade;
        });
      } catch (e) {
        setState(() {
          _calculatedGrade = null;
        });
      }
    } else {
      setState(() {
        _calculatedGrade = null;
      });
    }
  }

  // Handle course selection from dropdown
  void _handleCourseSelected(String courseCode, String courseName) {
    setState(() {
      _courseNameController.text = courseName;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare data for API and local storage
        final gradeData = {
          'user_id': _userIdController.text,
          'course_name': _courseNameController.text,
          'semester_no': _semesterController.text,
          'credit_hours': _creditHoursController.text,
          'marks': _marksController.text,
          'grade': _calculatedGrade ?? '', // Use calculated grade
          'is_synced': 0, // Not synced initially
        };

        late int id;
        if (_isEditMode && _editingGradeId != null) {
          // Update existing grade
          gradeData['id'] = _editingGradeId!; // Using null assertion operator

          // Update in local database
          await _dbHelper.updateGrade(_editingGradeId!, gradeData);
          id = _editingGradeId!;

          _showSnackBar('Grade updated successfully');
        } else {
          // Add new grade to local database
          id = await _dbHelper.insertGrade(gradeData);
          _showSnackBar('Grade added successfully');
        }

        // Try sending to API if online
        if (!_isOffline) {
          try {
            final response = await ApiService.addGrade(gradeData);

            if (response['success']) {
              // Mark as synced in local database
              await _dbHelper.markGradeAsSynced(id);
              _showSnackBar(_isEditMode
                  ? 'Grade updated and synced with server'
                  : 'Grade added and synced with server');
            } else {
              _showSnackBar('Grade saved locally but sync failed: ${response['message']}');
            }
          } catch (e) {
            print('API submission error: $e');
            _showSnackBar('Grade saved locally. Will sync when online.');
          }
        } else {
          _showSnackBar('You are offline. Grade saved locally and will be synced when online.');
        }

        // Clear form
        _clearForm();

        // Notify parent widget
        widget.onGradeAdded();

        // Close form after a short delay
        await Future.delayed(Duration(seconds: 1));
        if (mounted) Navigator.pop(context);

      } catch (e) {
        _showSnackBar('Error saving grade: $e');
        print('Error in submitForm: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _userIdController.clear();
    _courseNameController.clear();
    _semesterController.clear();
    _creditHoursController.clear();
    _marksController.clear();
    setState(() {
      _calculatedGrade = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primaryColor.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Grade' : 'Add New Grade',
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
          // Clear form button
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
              // Offline indicator
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
                          'You are offline. Grades will be saved locally and synchronized when online.',
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

              // User ID field
              _buildTextFormField(
                controller: _userIdController,
                label: 'Student ID',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student ID';
                  }
                  return null;
                },
                enabled: !_isEditMode, // Disable in edit mode
              ),
              SizedBox(height: 24),

              _buildSectionHeader('Course Information'),
              SizedBox(height: 16),

              // Course Dropdown - Will fetch from API (only in add mode)
              if (!_isEditMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: CourseDropdown(
                    onCourseSelected: _handleCourseSelected,
                    userId: _userIdController.text.isNotEmpty ? _userIdController.text : null,
                    primaryColor: _primaryColor,
                  ),
                ),

              // Course Name field
              _buildTextFormField(
                controller: _courseNameController,
                label: 'Course Name',
                prefixIcon: Icons.book,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course name';
                  }
                  return null;
                },
                enabled: !_isEditMode, // Disable in edit mode
              ),
              SizedBox(height: 12),

              // Semester and Credit Hours row
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _semesterController,
                      label: 'Semester',
                      prefixIcon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter semester';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                      enabled: !_isEditMode, // Disable in edit mode
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _creditHoursController,
                      label: 'Credit Hours',
                      prefixIcon: Icons.credit_card,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter credit hours';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Marks field with calculated grade display
              Stack(
                children: [
                  _buildTextFormField(
                    controller: _marksController,
                    label: 'Marks (0-100)',
                    prefixIcon: Icons.grade,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter marks';
                      }
                      final marks = double.tryParse(value);
                      if (marks == null) {
                        return 'Enter a valid number';
                      }
                      if (marks < 0 || marks > 100) {
                        return 'Marks must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  if (_calculatedGrade != null)
                    Positioned(
                      right: 16,
                      top: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGradeColor(_calculatedGrade!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Grade: $_calculatedGrade',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 32),

              // Submit button
              ElevatedButton(
                onPressed: _submitForm,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _isEditMode ? 'UPDATE GRADE' : 'SAVE GRADE',
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
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
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
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: enabled
              ? _primaryColor.withOpacity(0.7)
              : Colors.grey),
          floatingLabelStyle: TextStyle(color: enabled
              ? _primaryColor
              : Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
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
          fillColor: enabled ? Colors.white : Colors.grey.withOpacity(0.05),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: enabled ? _primaryColor : Colors.grey)
              : null,
        ),
      ),
    );
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
}