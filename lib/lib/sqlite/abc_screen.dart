// lib/sqlite/abc_screen.dart
import 'package:flutter/material.dart';
import 'package:lesson1/widgets/custom_drawer.dart'; // Import the custom drawer
import 'database_helper.dart';
import 'user.dart';

class ABC_Screen extends StatefulWidget {
  @override
  _ABC_ScreenState createState() => _ABC_ScreenState();
}

class _ABC_ScreenState extends State<ABC_Screen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _obscurePassword = true;
  List<User> users = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn)
    );

    _animationController.forward();
  }

  // Load all users from the database
  void _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    List<User> userList = await DatabaseHelper.instance.getUsers();

    setState(() {
      users = userList;
      _isLoading = false;
    });
  }

  // Save user data to the database
  void _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String email = emailController.text;
    String password = passwordController.text;

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    // Get current timestamp
    String timestamp = DateTime.now().toIso8601String();

    // Create a user object
    User user = User(
      email: email,
      password: password,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    try {
      // Insert user data into the database
      int userId = await DatabaseHelper.instance.insertUser(user);
      print('User added with id: $userId');

      // Clear the text fields after saving
      emailController.clear();
      passwordController.clear();

      // Reload users
      _loadUsers();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('User saved successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 16),
              Text('Error: ${e.toString()}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete a user
  void _deleteUser(User user) async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 10),
              Text("Delete User"),
            ],
          ),
          content: Text("Are you sure you want to delete ${user.email}?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton.icon(
              icon: Icon(Icons.cancel, size: 18),
              label: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete, size: 18),
              label: Text("Delete"),
              onPressed: () async {
                Navigator.of(context).pop();

                setState(() {
                  _isLoading = true;
                });

                try {
                  // Delete the user from the database
                  await DatabaseHelper.instance.deleteUser(user.id!);

                  // Reload users
                  _loadUsers();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 16),
                          Text('User deleted successfully'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 16),
                          Text('Error: ${e.toString()}'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: EdgeInsets.all(10),
                    ),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  // Display the list of users
  Widget _buildUserList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
      ));
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add a new user using the form above',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          User user = users[index];
          return Card(
            elevation: 3,
            shadowColor: Colors.black26,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Hero(
                tag: 'avatar-${user.id}',
                child: CircleAvatar(
                  backgroundColor: Colors.orange.shade700,
                  child: Text(
                    user.email.isNotEmpty ? user.email.substring(0, 1).toUpperCase() : '?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              title: Text(
                user.email,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Created: ${_formatDate(user.createdAt)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.update, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Updated: ${_formatDate(user.updatedAt)}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _showEditDialog(user);
                    },
                    tooltip: 'Edit User',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteUser(user);
                    },
                    tooltip: 'Delete User',
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                // Show user details or perform an action
                _showUserDetailsBottomSheet(user);
              },
            ),
          );
        },
      ),
    );
  }

  void _showUserDetailsBottomSheet(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.shade700,
                    child: Text(
                      user.email.isNotEmpty ? user.email.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'User ID: ${user.id}',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.blue),
                title: Text('Created'),
                subtitle: Text(_formatDate(user.createdAt)),
                dense: true,
              ),
              ListTile(
                leading: Icon(Icons.update, color: Colors.green),
                title: Text('Last Updated'),
                subtitle: Text(_formatDate(user.updatedAt)),
                dense: true,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDialog(user);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Delete'),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteUser(user);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: Icon(Icons.close),
                    label: Text('Close'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Format ISO date string to a more readable format
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  // Show dialog to edit user information
  void _showEditDialog(User user) {
    final editEmailController = TextEditingController(text: user.email);
    final editPasswordController = TextEditingController(text: user.password);
    bool obscureEditPassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 10),
                    Text("Edit User"),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                content: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: editEmailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: editPasswordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureEditPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureEditPassword = !obscureEditPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        obscureText: obscureEditPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton.icon(
                    icon: Icon(Icons.cancel, size: 18),
                    label: Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.save, size: 18),
                    label: Text("Save"),
                    onPressed: () async {
                      // Update the user data in the database
                      User updatedUser = User(
                        id: user.id,
                        email: editEmailController.text,
                        password: editPasswordController.text,
                        createdAt: user.createdAt, // Keep the original created_at value
                        updatedAt: DateTime.now().toIso8601String(), // Update the timestamp
                      );

                      await DatabaseHelper.instance.updateUser(updatedUser);

                      // Reload users
                      _loadUsers();

                      // Close the dialog
                      Navigator.of(context).pop();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white),
                              SizedBox(width: 16),
                              Text('User updated successfully'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // Build the form section
  Widget _buildFormSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Add New User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter user email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save User'),
              onPressed: _isLoading ? null : _saveUserData,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build list header
  Widget _buildListHeader() {
    return Row(
      children: [
        Icon(Icons.people, size: 18, color: Colors.orange.shade800),
        SizedBox(width: 8),
        Text(
          'User List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        SizedBox(width: 8),
        if (!_isLoading)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${users.length}',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Spacer(),
        if (_isLoading)
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're in landscape mode
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      drawer: CustomDrawer(), // Add the custom drawer here
      appBar: AppBar(
        title: Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout()
            : _buildPortraitLayout(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Focus on the email field
          FocusScope.of(context).requestFocus(FocusNode());
          // Scroll to the top
          Future.delayed(Duration(milliseconds: 100), () {
            emailController.clear();
            passwordController.clear();
            // Set focus to email field
            FocusScope.of(context).requestFocus(FocusNode());
          });
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
        tooltip: 'Add New User',
      ),
    );
  }

  // Portrait mode layout (stacked vertically)
  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Form section
        _buildFormSection(),
        SizedBox(height: 16),
        // List header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildListHeader(),
        ),
        SizedBox(height: 8),
        // User list
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildUserList(),
          ),
        ),
      ],
    );
  }

  // Landscape mode layout (side by side)
  Widget _buildLandscapeLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Form section in a scrollable container
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: _buildFormSection(),
            ),
          ),
        ),
        // Divider
        VerticalDivider(width: 1, thickness: 1, color: Colors.grey.shade300),
        // User list section
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: _buildListHeader(),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _buildUserList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}