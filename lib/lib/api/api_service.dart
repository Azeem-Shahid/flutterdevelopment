// lib/api/api_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // API Endpoints
  static const String addGradeUrl = 'https://devtechtop.com/management/public/api/grades';
  static const String fetchGradesUrl = 'https://devtechtop.com/management/public/api/select_data';
  static const String fetchCoursesUrl = 'https://bgnuerp.online/api/get_courses';

  static const String localStorageKey = 'pending_results';

  // Fetch student results (used in StudentResultsPage)
  static Future<List<Map<String, dynamic>>> fetchStudentResults() async {
    try {
      // Direct API call to the endpoint you specified
      final uri = Uri.parse(fetchGradesUrl);

      print('Fetching all student results from: $uri');
      final response = await http.get(uri).timeout(Duration(seconds: 15));

      print('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          // Convert each item to Map<String, dynamic> explicitly
          return List<Map<String, dynamic>>.from(
              responseData.map((item) => Map<String, dynamic>.from(item))
          );
        } else if (responseData is Map && responseData.containsKey('data')) {
          final dataList = responseData['data'];
          if (dataList is List) {
            return List<Map<String, dynamic>>.from(
                dataList.map((item) => Map<String, dynamic>.from(item))
            );
          }
        }

        // If response is not in expected format, return empty list
        return [];
      } else {
        throw Exception('Failed to load student results: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your internet connection.');
    } catch (e) {
      print('Error fetching student results: $e');
      throw Exception('Failed to load student results: $e');
    }
  }

  // Fetch all grades for a user
  static Future<List<Map<String, dynamic>>> fetchGradesByUserId(String userId) async {
    try {
      // According to your requirements, we should directly call the grades API for a specific user
      final uri = Uri.parse(addGradeUrl);

      print('Fetching grades for user ID $userId from: $uri');

      // Using POST as per your requirement
      final response = await http.post(
        uri,
        body: {'user_id': userId},
      ).timeout(Duration(seconds: 15));

      print('Grades API Response Status: ${response.statusCode}');
      print('Grades API Response Body: ${response.body.substring(0, min(response.body.length, 500))}...');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is List) {
          // Force cast to Map<String, dynamic> to ensure correct typing
          return List<Map<String, dynamic>>.from(
              responseData
                  .where((grade) => grade['user_id'].toString() == userId.toString())
                  .map((grade) => Map<String, dynamic>.from(grade))
          );
        } else if (responseData is Map && responseData.containsKey('data')) {
          final dataList = responseData['data'];
          if (dataList is List) {
            return List<Map<String, dynamic>>.from(
                dataList
                    .where((grade) => grade['user_id'].toString() == userId.toString())
                    .map((grade) => Map<String, dynamic>.from(grade))
            );
          }
        } else if (responseData is Map) {
          // Handle single object response
          if (responseData['user_id'].toString() == userId.toString()) {
            return [Map<String, dynamic>.from(responseData)];
          }
        }

        // If we get a 422 error or other response that indicates missing fields
        // We should try to get the data from the general endpoint and filter locally
        return await _getFallbackGradesByUserId(userId);
      } else if (response.statusCode == 422) {
        // As per your API example, this might be an expected response if missing fields
        // Fall back to filtering from the main endpoint
        return await _getFallbackGradesByUserId(userId);
      } else {
        throw Exception('Failed to load grades: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your internet connection.');
    } catch (e) {
      print('Error fetching grades: $e');
      // Try fallback if the direct call fails
      try {
        return await _getFallbackGradesByUserId(userId);
      } catch (fallbackError) {
        throw Exception('Failed to load grades: $e');
      }
    }
  }

  // Fallback method to get grades by user ID from the main endpoint
  static Future<List<Map<String, dynamic>>> _getFallbackGradesByUserId(String userId) async {
    try {
      final allResults = await fetchStudentResults();
      return allResults
          .where((grade) => grade['user_id']?.toString() == userId.toString() ||
          grade['rollno']?.toString() == userId.toString())
          .toList();
    } catch (e) {
      print('Error in fallback method for fetching grades: $e');
      return [];
    }
  }

  // Fetch all available courses
  static Future<List<Map<String, dynamic>>> fetchCourses({String? userId, String? searchQuery}) async {
    try {
      // Build the query parameters
      final queryParams = <String, String>{};
      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId;
      }

      // Add search parameter if provided (for server-side filtering if supported)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search'] = searchQuery;
      }

      // Create URI with query parameters
      final uri = Uri.parse(fetchCoursesUrl).replace(queryParameters: queryParams);

      print('Fetching courses from: $uri');
      final response = await http.get(uri).timeout(Duration(seconds: 15));

      print('Courses API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Print a preview of the response for debugging
        print('API Response Preview: ${response.body.substring(0, min(response.body.length, 500))}...');

        final responseData = json.decode(response.body);
        List<Map<String, dynamic>> courses = [];

        if (responseData is List) {
          // Direct list response (matches your sample data format)
          courses = List<Map<String, dynamic>>.from(
              responseData.map((course) => Map<String, dynamic>.from(course))
          );
        } else if (responseData is Map && responseData.containsKey('data')) {
          // Data wrapped in a container object
          final dataList = responseData['data'];
          if (dataList is List) {
            courses = List<Map<String, dynamic>>.from(
                dataList.map((course) => Map<String, dynamic>.from(course))
            );
          }
        }

        // If we have a search query but the API doesn't support server-side filtering,
        // we'll do client-side filtering here
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final lowercaseQuery = searchQuery.toLowerCase();
          return courses.where((course) {
            // Try all possible field names for course code and name
            final subjectCode = course['subject_code']?.toString().toLowerCase() ?? '';
            final courseCode = course['course_code']?.toString().toLowerCase() ?? '';
            final id = course['id']?.toString().toLowerCase() ?? '';

            final subjectName = course['subject_name']?.toString().toLowerCase() ?? '';
            final courseName = course['course_name']?.toString().toLowerCase() ?? '';
            final name = course['name']?.toString().toLowerCase() ?? '';

            // Return true if the search term is found in any of the potential fields
            return subjectCode.contains(lowercaseQuery) ||
                courseCode.contains(lowercaseQuery) ||
                id.contains(lowercaseQuery) ||
                subjectName.contains(lowercaseQuery) ||
                courseName.contains(lowercaseQuery) ||
                name.contains(lowercaseQuery);
          }).toList();
        }

        return courses;
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out. Please check your internet connection.');
    } catch (e) {
      print('Error fetching courses: $e');
      throw Exception('Failed to load courses: $e');
    }
  }

  // Search courses (a specialized wrapper around fetchCourses)
  static Future<List<Map<String, dynamic>>> searchCourses(String query, {String? userId}) async {
    if (query.isEmpty) {
      return fetchCourses(userId: userId);
    }

    try {
      return await fetchCourses(userId: userId, searchQuery: query);
    } catch (e) {
      print('Error searching courses: $e');
      throw Exception('Failed to search courses: $e');
    }
  }

  // Add a new grade - updated to use the direct API as specified
  static Future<Map<String, dynamic>> addGrade(Map<String, dynamic> gradeData) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      // Check if device is online
      if (connectivityResult == ConnectivityResult.none) {
        // Store data locally if offline
        await _saveResultLocally(gradeData);
        return {
          'success': true,
          'id': 0, // Temporary ID for locally stored results
          'message': 'No internet connection. Grade saved locally and will be synced when online.',
          'offline': true
        };
      }

      // Make a direct POST call to the grades API endpoint
      final uri = Uri.parse(addGradeUrl);

      print('Adding grade to: $uri');
      print('Grade data: $gradeData');

      final response = await http.post(
        uri,
        body: gradeData,
      ).timeout(Duration(seconds: 15));

      print('Add Grade API Response Status: ${response.statusCode}');
      print('Add Grade API Response Body: ${response.body.substring(0, min(response.body.length, 500))}...');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
          'message': 'Grade added successfully!',
          'offline': false
        };
      } else {
        // Save locally if API request fails
        await _saveResultLocally(gradeData);
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}. Grade saved locally.',
          'offline': true
        };
      }
    } on TimeoutException {
      // Save locally if the request times out
      await _saveResultLocally(gradeData);
      return {
        'success': false,
        'message': 'Connection timed out. Grade saved locally.',
        'offline': true
      };
    } catch (e) {
      print('API Error: $e');
      // Save locally for any other errors
      await _saveResultLocally(gradeData);
      return {
        'success': false,
        'message': 'Error: ${e.toString()}. Grade saved locally.',
        'offline': true
      };
    }
  }

  // Add a student result using the previous API format
  static Future<Map<String, dynamic>> addStudentResult(Map<String, dynamic> resultData) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();

      // Check if device is online
      if (connectivityResult == ConnectivityResult.none) {
        // Store data locally if offline
        await _saveResultLocally(resultData);
        return {
          'success': true,
          'id': 0, // Temporary ID for locally stored results
          'message': 'No internet connection. Result saved locally and will be synced when online.',
          'offline': true
        };
      }

      // Map the data to the format expected by the grade API
      final gradeData = {
        'user_id': resultData['rollno'],
        'course_name': resultData['coursetitle'],
        'semester_no': resultData['mysemester'],
        'credit_hours': resultData['credithours'],
        'marks': resultData['obtainedmarks'],
        'grade': _calculateGradeFromMarks(resultData['obtainedmarks']),
      };

      return await addGrade(gradeData);
    } catch (e) {
      print('Error in addStudentResult: $e');
      await _saveResultLocally(resultData);
      return {
        'success': false,
        'message': 'Error: ${e.toString()}. Result saved locally.',
        'offline': true
      };
    }
  }

  // Calculate letter grade from marks
  static String _calculateGradeFromMarks(dynamic marks) {
    if (marks == null) return 'F';

    double score;
    try {
      score = double.parse(marks.toString());
    } catch (e) {
      return 'F';
    }

    if (score >= 90) return 'A';
    if (score >= 80) return 'B';
    if (score >= 70) return 'C';
    if (score >= 60) return 'D';
    return 'F';
  }

  // Save result data to local storage for offline handling
  static Future<void> _saveResultLocally(Map<String, dynamic> resultData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingResults = prefs.getStringList(localStorageKey) ?? [];

      // Add timestamp to track when it was saved
      resultData['saved_at'] = DateTime.now().toIso8601String();
      resultData['synced'] = false;

      pendingResults.add(json.encode(resultData));
      await prefs.setStringList(localStorageKey, pendingResults);
      print('Saved result locally: ${resultData['coursetitle'] ?? resultData['course_name']}');
    } catch (e) {
      print('Error saving result locally: $e');
    }
  }

  // Sync offline data with the server
  static Future<Map<String, dynamic>> syncOfflineData() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return {
          'success': false,
          'message': 'No internet connection available for syncing'
        };
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> pendingResults = prefs.getStringList(localStorageKey) ?? [];

      if (pendingResults.isEmpty) {
        return {
          'success': true,
          'message': 'No pending data to sync'
        };
      }

      print('Found ${pendingResults.length} pending results to sync');
      int successCount = 0;
      List<String> remainingResults = [];

      for (String resultJson in pendingResults) {
        try {
          Map<String, dynamic> resultData = json.decode(resultJson);

          // Remove local tracking fields before sending to API
          resultData.remove('saved_at');
          resultData.remove('synced');

          // Determine which API to use based on data format
          Map<String, dynamic> response;

          if (resultData.containsKey('coursetitle')) {
            // It's in student result format
            response = await addStudentResult(resultData);
          } else {
            // It's in grade format
            response = await addGrade(resultData);
          }

          if (response['success'] && !response['offline']) {
            successCount++;
            print('Successfully synced: ${resultData['coursetitle'] ?? resultData['course_name']}');
          } else {
            remainingResults.add(resultJson);
            print('Failed to sync: ${resultData['coursetitle'] ?? resultData['course_name']}');
          }
        } catch (e) {
          remainingResults.add(resultJson);
          print('Error during sync of a record: $e');
        }
      }

      // Update pending results
      await prefs.setStringList(localStorageKey, remainingResults);

      return {
        'success': true,
        'synced_count': successCount,
        'remaining_count': remainingResults.length,
        'message': 'Synced $successCount results. ${remainingResults.length} remaining.'
      };
    } catch (e) {
      print('Error during sync process: $e');
      return {
        'success': false,
        'message': 'Error during sync: ${e.toString()}'
      };
    }
  }

  // Get offline saved results
  static Future<List<Map<String, dynamic>>> getOfflineResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> pendingResults = prefs.getStringList(localStorageKey) ?? [];

      return pendingResults
          .map((resultJson) => json.decode(resultJson) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting offline results: $e');
      return [];
    }
  }

  // Helper function to get the minimum of two numbers
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}