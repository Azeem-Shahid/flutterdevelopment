// lib/api/course_dropdown.dart

import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dart:async';

class CourseDropdown extends StatefulWidget {
  final Function(String, String) onCourseSelected;
  final String? userId;
  final Color primaryColor;

  const CourseDropdown({
    Key? key,
    required this.onCourseSelected,
    this.userId,
    required this.primaryColor,
  }) : super(key: key);

  @override
  _CourseDropdownState createState() => _CourseDropdownState();
}

class _CourseDropdownState extends State<CourseDropdown> {
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _filteredCourses = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _selectedCourseCode;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadCourses();

    // Add listener to search field
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Debounce search to prevent excessive filtering while typing
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isEmpty) {
        setState(() {
          _filteredCourses = _allCourses;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = true;
          _filteredCourses = _allCourses.where((course) {
            // Search in both code and name fields
            String code = _getCourseCode(course).toLowerCase();
            String name = _getCourseName(course).toLowerCase();
            String searchTerm = _searchController.text.toLowerCase();

            return code.contains(searchTerm) || name.contains(searchTerm);
          }).toList();
        });
      }
    });
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await ApiService.fetchCourses(userId: widget.userId);
      setState(() {
        _allCourses = courses;
        _filteredCourses = courses;
        _isLoading = false;
      });

      // Debug the structure of the first course if available
      if (courses.isNotEmpty) {
        print('First course structure: ${courses.first}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load courses';
        _isLoading = false;
      });
      print('Error loading courses: $e');
    }
  }

  // Helper methods to extract course code and name safely
  String _getCourseCode(Map<String, dynamic> course) {
    // Based on the JSON example provided, we first check for subject_code
    if (course.containsKey('subject_code')) {
      return course['subject_code']?.toString() ?? '';
    }
    // Then try course_code (in case API format changes)
    else if (course.containsKey('course_code')) {
      return course['course_code']?.toString() ?? '';
    }
    // Finally try id as fallback
    else if (course.containsKey('id')) {
      return course['id']?.toString() ?? '';
    }
    return 'Unknown';
  }

  String _getCourseName(Map<String, dynamic> course) {
    // Based on the JSON example provided, we first check for subject_name
    if (course.containsKey('subject_name')) {
      return course['subject_name']?.toString() ?? '';
    }
    // Then try course_name (in case API format changes)
    else if (course.containsKey('course_name')) {
      return course['course_name']?.toString() ?? '';
    }
    // Finally try name as fallback
    else if (course.containsKey('name')) {
      return course['name']?.toString() ?? '';
    }
    return 'Unknown Course';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_allCourses.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchableDropdown();
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Loading courses...',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  _errorMessage ?? 'Error loading courses',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
            TextButton(
              onPressed: _loadCourses,
              child: Text(
                'Retry',
                style: TextStyle(color: widget.primaryColor),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: 'Course Code',
          labelStyle: TextStyle(color: widget.primaryColor.withOpacity(0.7)),
          floatingLabelStyle: TextStyle(color: widget.primaryColor),
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
            borderSide: BorderSide(color: widget.primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(Icons.book, color: widget.primaryColor),
          suffixIcon: IconButton(
            icon: Icon(Icons.refresh, color: widget.primaryColor.withOpacity(0.7)),
            onPressed: _loadCourses,
            tooltip: 'Refresh courses',
          ),
          hintText: 'No courses available, enter manually',
        ),
        onChanged: (value) {
          widget.onCourseSelected(value, '');
        },
      ),
    );
  }

  Widget _buildSearchableDropdown() {
    return Column(
      children: [
        // Search input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Course',
              labelStyle: TextStyle(color: widget.primaryColor.withOpacity(0.7)),
              floatingLabelStyle: TextStyle(color: widget.primaryColor),
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
                borderSide: BorderSide(color: widget.primaryColor),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(Icons.search, color: widget.primaryColor),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: widget.primaryColor.withOpacity(0.7)),
                      onPressed: () {
                        _searchController.clear();
                      },
                      tooltip: 'Clear search',
                    ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: widget.primaryColor.withOpacity(0.7)),
                    onPressed: _loadCourses,
                    tooltip: 'Refresh courses',
                  ),
                ],
              ),
              hintText: 'Type to search courses',
            ),
          ),
        ),

        SizedBox(height: 10),

        // Results display
        if (_isSearching && _filteredCourses.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'No courses found matching "${_searchController.text}"',
              style: TextStyle(color: Colors.grey[700]),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedCourseCode,
              decoration: InputDecoration(
                labelText: 'Course',
                labelStyle: TextStyle(color: widget.primaryColor.withOpacity(0.7)),
                floatingLabelStyle: TextStyle(color: widget.primaryColor),
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
                  borderSide: BorderSide(color: widget.primaryColor),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: Icon(Icons.book, color: widget.primaryColor),
              ),
              isExpanded: true,
              hint: Text(_isSearching
                  ? 'Select from ${_filteredCourses.length} results'
                  : 'Select a course'),
              items: _filteredCourses.map((course) {
                String code = _getCourseCode(course);
                String name = _getCourseName(course);

                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(
                    '$code - $name',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCourseCode = value;
                  });

                  // Find the selected course
                  String courseName = '';
                  for (var course in _filteredCourses) {
                    String courseCode = _getCourseCode(course);

                    if (courseCode == value) {
                      courseName = _getCourseName(course);
                      break;
                    }
                  }

                  // Notify parent widget
                  widget.onCourseSelected(value, courseName);
                }
              },
            ),
          ),
      ],
    );
  }
}