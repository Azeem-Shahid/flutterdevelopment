// lib/screens/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:lesson1/sqlite/database_helper.dart';
import 'package:lesson1/sqlite/user.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Load all users from the database
  void _loadUsers() async {
    List<User> userList = await DatabaseHelper.instance.getUsers();
    setState(() {
      users = userList;
    });
  }

  // Save user data to the database
  void _saveUserData() async {
    String email = emailController.text;
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      // Show an alert if email or password is empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Error"),
          content: Text("Please enter both email and password"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Get current timestamp
    String timestamp = DateTime.now().toIso8601String();

    // Create a user object
    User user = User(
      email: email,
      password: password,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    // Insert user data into the database
    int userId = await DatabaseHelper.instance.insertUser(user);
    print('User added with id: $userId');

    // Clear the text fields after saving
    emailController.clear();
    passwordController.clear();

    // Reload users
    _loadUsers();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User saved')));
  }

  // Display the list of users
  Widget _buildUserList() {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        User user = users[index];
        return ListTile(
          title: Text(user.email),
          subtitle: Text('Created: ${user.createdAt}, Updated: ${user.updatedAt}'),
          trailing: IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showEditDialog(user);
            },
          ),
        );
      },
    );
  }

  // Show dialog to edit user information
  void _showEditDialog(User user) {
    emailController.text = user.email;
    passwordController.text = user.password;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit User"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Update the user data in the database
                User updatedUser = User(
                  id: user.id,
                  email: emailController.text,
                  password: passwordController.text,
                  createdAt: user.createdAt, // Keep the original created_at value
                  updatedAt: DateTime.now().toIso8601String(), // Update the timestamp
                );
                DatabaseHelper.instance.updateUser(updatedUser);

                // Reload users
                _loadUsers();

                // Close the dialog
                Navigator.of(context).pop();
              },
              child: Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUserData,
              child: Text('Save'),
            ),
            SizedBox(height: 20),
            Expanded(child: _buildUserList()), // Display the list of users
          ],
        ),
      ),
    );
  }
}
