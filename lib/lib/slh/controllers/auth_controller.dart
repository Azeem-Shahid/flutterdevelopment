import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import 'dart:developer' as developer;
import 'dart:io';

class AuthController {
  // Register a new user
  Future<bool> registerUser(UserModel user) async {
    try {
      // Log the registration attempt
      developer.log('Attempting to register user: ${user.email}');

      // Check if image is provided
      if (user.imagePath == null || user.imagePath!.isEmpty) {
        developer.log('Registration failed: No profile image provided');
        return false;
      }

      // Check if user image file exists
      if (!await File(user.imagePath!).exists()) {
        developer.log('Registration failed: Profile image file does not exist at path: ${user.imagePath}');
        return false;
      }

      // Check if email is already registered
      if (await isEmailRegistered(user.email)) {
        developer.log('Registration failed: Email ${user.email} is already registered');
        return false;
      }

      // Validate other user fields
      if (_validateUser(user)) {
        await SharedPrefs.saveUser(user);
        developer.log('User registered successfully: ${user.email}');
        return true; // Successfully registered
      } else {
        developer.log('Registration failed: Invalid user data');
        return false; // Validation failed
      }
    } catch (e) {
      developer.log('Error during registration: $e');
      return false; // Error during registration
    }
  }

  // Update existing user
  Future<bool> updateUser(UserModel updatedUser) async {
    try {
      developer.log('Attempting to update user: ${updatedUser.email}');

      // Check if image is provided
      if (updatedUser.imagePath == null || updatedUser.imagePath!.isEmpty) {
        developer.log('Update failed: No profile image provided');
        return false;
      }

      // Check if user image file exists
      if (!await File(updatedUser.imagePath!).exists()) {
        developer.log('Update failed: Profile image file does not exist at path: ${updatedUser.imagePath}');
        return false;
      }

      // Get current user to compare
      UserModel? currentUser = await SharedPrefs.getUser();

      // Only allow updates for the same email (prevent changing to an existing email)
      if (currentUser != null && updatedUser.email != currentUser.email) {
        if (await isEmailRegistered(updatedUser.email)) {
          developer.log('Update failed: Cannot change to email ${updatedUser.email} as it is already registered');
          return false;
        }
      }

      // Validate user fields
      if (_validateUser(updatedUser)) {
        await SharedPrefs.updateUser(updatedUser);
        developer.log('User updated successfully: ${updatedUser.email}');
        return true;
      } else {
        developer.log('Update failed: Invalid user data');
        return false;
      }
    } catch (e) {
      developer.log('Error during user update: $e');
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteUser() async {
    try {
      developer.log('Attempting to delete user account');
      await SharedPrefs.clearUserData();
      developer.log('User account deleted successfully');
      return true;
    } catch (e) {
      developer.log('Error during account deletion: $e');
      return false;
    }
  }

  // Login user by checking email and password
  Future<bool> loginUser(String email, String password) async {
    try {
      developer.log('Attempting login for: $email');

      UserModel? savedUser = await SharedPrefs.getUser();
      if (savedUser == null) {
        developer.log('Login failed: No saved user found');
        return false;
      }

      if (savedUser.email == email && savedUser.password == password) {
        await SharedPrefs.setLoggedIn(true);
        developer.log('Login successful for: $email');
        return true; // Login successful
      } else {
        developer.log('Login failed: Invalid credentials');
        return false; // Login failed
      }
    } catch (e) {
      developer.log('Error during login: $e');
      return false; // Error during login
    }
  }

  // Validate user input
  bool _validateUser(UserModel user) {
    final isValid = user.name.isNotEmpty &&
        user.email.isNotEmpty &&
        user.email.contains('@') &&  // Basic email validation
        user.password.isNotEmpty &&
        user.password.length >= 6 &&  // Enforce minimum password length
        user.city.isNotEmpty &&
        user.address.isNotEmpty &&
        user.gender.isNotEmpty &&
        user.imagePath != null &&
        user.imagePath!.isNotEmpty;  // Make sure image is provided

    if (!isValid) {
      developer.log('User validation failed');
      if (user.imagePath == null || user.imagePath!.isEmpty) {
        developer.log('- Missing profile image');
      }
      if (user.name.isEmpty) {
        developer.log('- Name is empty');
      }
      if (user.email.isEmpty || !user.email.contains('@')) {
        developer.log('- Invalid email');
      }
      if (user.password.isEmpty || user.password.length < 6) {
        developer.log('- Invalid password');
      }
      if (user.city.isEmpty) {
        developer.log('- City is empty');
      }
      if (user.address.isEmpty) {
        developer.log('- Address is empty');
      }
      if (user.gender.isEmpty) {
        developer.log('- Gender is empty');
      }
    }

    return isValid;
  }

  // Check if a user is already registered with this email
  Future<bool> isEmailRegistered(String email) async {
    UserModel? savedUser = await SharedPrefs.getUser();
    return savedUser != null && savedUser.email == email;
  }

  // Logout user
  Future<void> logoutUser() async {
    await SharedPrefs.setLoggedIn(false);
    developer.log('User logged out');
  }
}