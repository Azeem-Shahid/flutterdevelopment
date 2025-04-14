import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/user_model.dart';

class SharedPrefs {
  // Keys
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _emailKey = 'email';

  // Save user using JSON serialization
  static Future<void> saveUser(UserModel user) async {
    // Validate user data first
    if (user.imagePath == null || user.imagePath!.isEmpty) {
      developer.log('ERROR: Attempt to save user without profile image');
      throw Exception('Profile image is required');
    }

    if (user.name.isEmpty || user.email.isEmpty || !user.email.contains('@') ||
        user.password.isEmpty || user.city.isEmpty || user.address.isEmpty ||
        user.gender.isEmpty) {
      developer.log('ERROR: Attempt to save user with invalid data');
      throw Exception('All user fields are required and must be valid');
    }

    final prefs = await SharedPreferences.getInstance();

    try {
      // Convert the entire user model to JSON
      final userJson = user.toJson();
      final userJsonString = jsonEncode(userJson);

      // Save the complete user data as a single JSON string
      await prefs.setString(_userDataKey, userJsonString);

      // Also save email for easier login checks
      await prefs.setString(_emailKey, user.email);

      developer.log('User saved successfully: ${user.email}');
    } catch (e) {
      developer.log('Error saving user data: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  // Update existing user data
  static Future<void> updateUser(UserModel user) async {
    try {
      // Simply save over the existing user data
      await saveUser(user);
      developer.log('User updated successfully: ${user.email}');
    } catch (e) {
      developer.log('Error updating user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }

  // Get user using JSON deserialization
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final userJsonString = prefs.getString(_userDataKey);

      if (userJsonString != null && userJsonString.isNotEmpty) {
        final userJson = jsonDecode(userJsonString);
        final user = UserModel.fromJson(userJson);

        // Verify that image path exists
        if (user.imagePath == null || user.imagePath!.isEmpty) {
          developer.log('Warning: Retrieved user has no profile image');
        }

        developer.log('User data retrieved successfully for: ${user.email}');
        return user;
      } else {
        developer.log('No user data found in SharedPreferences');
        return _getLegacyUser();
      }
    } catch (e) {
      developer.log('Error retrieving user data: $e');

      // Fallback to legacy method (reading individual fields)
      return _getLegacyUser();
    }
  }

  // Legacy method for backward compatibility
  static Future<UserModel?> _getLegacyUser() async {
    developer.log('Attempting to retrieve user data using legacy method');
    final prefs = await SharedPreferences.getInstance();

    String? name = prefs.getString('name');
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    String? city = prefs.getString('city');
    String? address = prefs.getString('address');
    String? gender = prefs.getString('gender');
    String? imagePath = prefs.getString('imagePath');

    if (name != null &&
        email != null &&
        password != null &&
        city != null &&
        address != null &&
        gender != null &&
        imagePath != null) { // Make sure image path exists
      developer.log('User data retrieved using legacy method for: $email');
      return UserModel(
        name: name,
        email: email,
        password: password,
        city: city,
        address: address,
        gender: gender,
        imagePath: imagePath,
      );
    }
    developer.log('No user data found using legacy method');
    return null;
  }

  // Set login status
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
    developer.log('Login status set to: $value');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    developer.log('Current login status: $loggedIn');
    return loggedIn;
  }

  // Clear all user data for logout or account deletion
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // For account deletion, remove all user data
    await prefs.remove(_userDataKey);
    await prefs.remove(_emailKey);

    // For logout, just set logged in to false
    await prefs.setBool(_isLoggedInKey, false);

    // Also remove legacy keys
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('city');
    await prefs.remove('address');
    await prefs.remove('gender');
    await prefs.remove('imagePath');

    developer.log('User data cleared successfully');
  }

  // Get current user email
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    return email;
  }
}