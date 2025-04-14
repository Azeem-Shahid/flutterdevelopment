import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserController {
  // Storage keys
  static const String _recordCountKey = 'recordCount';
  static const String _namePrefix = 'name';
  static const String _emailPrefix = 'email';
  static const String _statusPrefix = 'status';
  static const String _createdAtPrefix = 'createdAt';
  static const String _updatedAtPrefix = 'updatedAt';

  // Private method to get SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Helper method to generate a user key
  String _generateUserKey(int id) {
    return 'user_$id';
  }

  // Helper method to format the full key with prefix
  String _formatKey(String userKey, String prefix) {
    return '${userKey}_$prefix';
  }

  // Get the current record count (total number of users)
  Future<int> _getRecordCount() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_recordCountKey) ?? 0;
  }

  // Set the record count
  Future<void> _setRecordCount(int count) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_recordCountKey, count);
  }

  // Save a user's data by field
  Future<void> _saveUserField(String userKey, String prefix, String value) async {
    final prefs = await _getPrefs();
    await prefs.setString(_formatKey(userKey, prefix), value);
  }

  // Get a user's field data
  Future<String?> _getUserField(String userKey, String prefix) async {
    final prefs = await _getPrefs();
    return prefs.getString(_formatKey(userKey, prefix));
  }

  // Remove a user's field data
  Future<void> _removeUserField(String userKey, String prefix) async {
    final prefs = await _getPrefs();
    await prefs.remove(_formatKey(userKey, prefix));
  }

  // Save user timestamp
  Future<void> _saveUserTimestamp(String userKey, String prefix) async {
    final timestamp = DateTime.now().toIso8601String();
    await _saveUserField(userKey, prefix, timestamp);
  }

  // Generate a new unique user key
  Future<String> _generateNewUserKey() async {
    final recordCount = await _getRecordCount();
    final newId = recordCount + 1;
    return _generateUserKey(newId);
  }

  // Check if a user exists
  Future<bool> userExists(String userKey) async {
    final name = await _getUserField(userKey, _namePrefix);
    return name != null;
  }

  // Save a new user and return the generated key
  Future<String> saveUser(UserModel user) async {
    // Generate a new user key
    final userKey = await _generateNewUserKey();

    // Save all user fields
    await _saveUserField(userKey, _namePrefix, user.name);
    await _saveUserField(userKey, _emailPrefix, user.email);
    await _saveUserField(userKey, _statusPrefix, user.status);

    // Save timestamps
    await _saveUserTimestamp(userKey, _createdAtPrefix);
    await _saveUserTimestamp(userKey, _updatedAtPrefix);

    // Update record count
    final recordCount = await _getRecordCount();
    await _setRecordCount(recordCount + 1);

    return userKey;
  }

  // Get all users
  Future<List<Map<String, String>>> getUsers() async {
    final recordCount = await _getRecordCount();
    final List<Map<String, String>> users = [];

    for (int i = 1; i <= recordCount; i++) {
      final userKey = _generateUserKey(i);
      final name = await _getUserField(userKey, _namePrefix);

      // Only add if name exists (user hasn't been deleted)
      if (name != null) {
        final Map<String, String> userData = {
          'key': userKey,
          'name': name,
          'email': await _getUserField(userKey, _emailPrefix) ?? '',
          'status': await _getUserField(userKey, _statusPrefix) ?? 'Active',
        };

        // Add timestamps if available
        final createdAt = await _getUserField(userKey, _createdAtPrefix);
        final updatedAt = await _getUserField(userKey, _updatedAtPrefix);

        if (createdAt != null) {
          userData['createdAt'] = createdAt;
        }

        if (updatedAt != null) {
          userData['updatedAt'] = updatedAt;
        }

        users.add(userData);
      }
    }

    return users;
  }

  // Get a specific user by key
  Future<UserModel?> getUser(String userKey) async {
    final name = await _getUserField(userKey, _namePrefix);

    // Return null if user doesn't exist
    if (name == null) return null;

    // Get user data
    final email = await _getUserField(userKey, _emailPrefix) ?? '';
    final status = await _getUserField(userKey, _statusPrefix) ?? 'Active';

    return UserModel(
      name: name,
      email: email,
      status: status,
    );
  }

  // Update an existing user
  Future<void> updateUser(String userKey, UserModel user) async {
    // Verify user exists
    if (!await userExists(userKey)) {
      throw Exception('User not found');
    }

    // Update user fields
    await _saveUserField(userKey, _namePrefix, user.name);
    await _saveUserField(userKey, _emailPrefix, user.email);
    await _saveUserField(userKey, _statusPrefix, user.status);

    // Update timestamp
    await _saveUserTimestamp(userKey, _updatedAtPrefix);
  }

  // Delete a user
  Future<void> deleteUser(String userKey) async {
    // Verify user exists
    if (!await userExists(userKey)) {
      throw Exception('User not found');
    }

    // Remove all user fields
    await _removeUserField(userKey, _namePrefix);
    await _removeUserField(userKey, _emailPrefix);
    await _removeUserField(userKey, _statusPrefix);
    await _removeUserField(userKey, _createdAtPrefix);
    await _removeUserField(userKey, _updatedAtPrefix);
  }

  // Get user count by status
  Future<Map<String, int>> getUserCountsByStatus() async {
    final users = await getUsers();

    int active = 0;
    int inactive = 0;

    for (var user in users) {
      if (user['status'] == 'Active') {
        active++;
      } else if (user['status'] == 'Inactive') {
        inactive++;
      }
    }

    return {
      'total': users.length,
      'active': active,
      'inactive': inactive,
    };
  }

  // Clear all users (useful for testing or reset functionality)
  Future<void> clearAllUsers() async {
    final recordCount = await _getRecordCount();

    for (int i = 1; i <= recordCount; i++) {
      final userKey = _generateUserKey(i);

      // Remove all fields for the user
      await _removeUserField(userKey, _namePrefix);
      await _removeUserField(userKey, _emailPrefix);
      await _removeUserField(userKey, _statusPrefix);
      await _removeUserField(userKey, _createdAtPrefix);
      await _removeUserField(userKey, _updatedAtPrefix);
    }

    // Reset record count
    await _setRecordCount(0);
  }

  // Search users by query
  Future<List<Map<String, String>>> searchUsers(String query) async {
    final allUsers = await getUsers();
    final searchQuery = query.toLowerCase();

    return allUsers.where((user) {
      final name = user['name']?.toLowerCase() ?? '';
      final email = user['email']?.toLowerCase() ?? '';

      return name.contains(searchQuery) || email.contains(searchQuery);
    }).toList();
  }

  // Filter users by status
  Future<List<Map<String, String>>> filterUsersByStatus(String status) async {
    if (status == 'All') {
      return getUsers();
    }

    final allUsers = await getUsers();

    return allUsers.where((user) => user['status'] == status).toList();
  }
}