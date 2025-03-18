import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lesson1/slh/screens/login_screen.dart';
import 'package:lesson1/widgets/custom_drawer.dart';
import '../models/user_model.dart';
import '../utils/shared_prefs.dart';
import '../controllers/auth_controller.dart';
import 'dart:developer' as developer;

// Define the color palette
class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF303030);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color midGray = Color(0xFFD9D9D9);
  static const Color success = Color(0xFF4CAF50); // Green color for success
  static const Color error = Color(0xFFD32F2F); // Red color for errors
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = '';
  String? imagePath;
  UserModel? currentUser;
  final AuthController _authController = AuthController();
  final ImagePicker _picker = ImagePicker();

  // Controllers for editing user information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedGender;
  File? _newImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Use SharedPrefs to check login status
      final isLoggedIn = await SharedPrefs.isLoggedIn();

      if (!isLoggedIn) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
        return;
      }

      // Get the full user data
      final user = await SharedPrefs.getUser();

      if (user != null && mounted) {
        setState(() {
          currentUser = user;
          username = user.name;
          imagePath = user.imagePath;

          // If name is empty, try to extract from email
          if (username.isEmpty && user.email.contains('@')) {
            username = user.email.split('@')[0];
            // Capitalize first letter
            username = username[0].toUpperCase() + username.substring(1);
          }

          // Initialize controllers with current user data
          _nameController.text = user.name;
          _emailController.text = user.email;
          _cityController.text = user.city;
          _addressController.text = user.address;
          _passwordController.text = user.password;
          _selectedGender = user.gender;
        });

        developer.log('Retrieved user data - Name: $username, Image: $imagePath');
      } else {
        developer.log('No user data found even though logged in');
      }
    } catch (e) {
      developer.log('Error checking login status: $e');

      // Fallback to old method if SharedPrefs fails
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (mounted) {
        setState(() {
          username = prefs.getString('name') ?? prefs.getString('email') ?? 'User';
          imagePath = prefs.getString('imagePath');

          // Extract name from email if email is present
          if (username.contains('@')) {
            username = username.split('@')[0];
            // Capitalize first letter
            username = username[0].toUpperCase() + username.substring(1);
          }
        });
      }

      if (!isLoggedIn && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      int imageSize = await imageFile.length(); // Get file size

      if (imageSize > 400 * 1024) { // Validate file size (400KB)
        _showErrorSnackBar('Image must be less than 400KB');
      } else {
        setState(() {
          _newImage = imageFile;
        });
      }
    }
  }

  Future<void> _updateUserProfile() async {
    if (_validateUpdateForm()) {
      try {
        // Create updated user model with all fields
        UserModel updatedUser = UserModel(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          city: _cityController.text,
          address: _addressController.text,
          gender: _selectedGender!,
          // Use new image if selected, otherwise keep the existing one
          imagePath: _newImage?.path ?? imagePath,
        );

        // Save the updated user
        await SharedPrefs.saveUser(updatedUser);

        // Refresh user data
        setState(() {
          currentUser = updatedUser;
          username = updatedUser.name;
          imagePath = updatedUser.imagePath;
          _newImage = null; // Reset new image
        });

        _showSuccessSnackBar('Profile updated successfully');
        Navigator.of(context).pop(); // Close the edit dialog
      } catch (e) {
        developer.log('Error updating profile: $e');
        _showErrorSnackBar('Failed to update profile: ${e.toString()}');
      }
    }
  }

  bool _validateUpdateForm() {
    if (_nameController.text.isEmpty) {
      _showErrorSnackBar('Name is required');
      return false;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showErrorSnackBar('Valid email is required');
      return false;
    }
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return false;
    }
    if (_cityController.text.isEmpty) {
      _showErrorSnackBar('City is required');
      return false;
    }
    if (_addressController.text.isEmpty) {
      _showErrorSnackBar('Address is required');
      return false;
    }
    if (_selectedGender == null) {
      _showErrorSnackBar('Gender selection is required');
      return false;
    }
    // Image validation
    if (imagePath == null && _newImage == null) {
      _showErrorSnackBar('Profile image is required');
      return false;
    }
    return true;
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Account Deletion",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          content: Text(
            "Are you sure you want to delete your account? This action cannot be undone.",
            style: TextStyle(color: AppColors.white),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Cancel",
                style: TextStyle(color: AppColors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text("Delete Account"),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        // Clear all user data
        await SharedPrefs.clearUserData();
        _showSuccessSnackBar("Account deleted successfully");

        // Navigate to login screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }
      } catch (e) {
        developer.log('Error deleting account: $e');
        _showErrorSnackBar("Failed to delete account");
      }
    }
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Logout",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: AppColors.white),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Cancel",
                style: TextStyle(color: AppColors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text("Logout"),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        // Use SharedPrefs to logout
        await SharedPrefs.setLoggedIn(false);
      } catch (e) {
        developer.log('Error in SharedPrefs logout: $e');

        // Fallback to old method
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }

      // Show logout confirmation
      _showSuccessSnackBar("You have been logged out");
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Profile Picture
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.midGray,
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.lightGray,
                                  backgroundImage: _newImage != null
                                      ? FileImage(_newImage!)
                                      : (imagePath != null ? FileImage(File(imagePath!)) : null),
                                  child: (_newImage == null && imagePath == null)
                                      ? Icon(Icons.person, size: 60, color: AppColors.charcoal)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    await _pickImage();
                                    // Need to update the dialog state
                                    setState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.charcoal,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Name Field
                        _buildInputField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        SizedBox(height: 12),

                        // Email Field
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 12),

                        // Password Field
                        _buildInputField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        SizedBox(height: 12),

                        // City Field
                        _buildInputField(
                          controller: _cityController,
                          label: 'City',
                          icon: Icons.location_city_outlined,
                        ),
                        SizedBox(height: 12),

                        // Address Field
                        _buildInputField(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.home_outlined,
                        ),
                        SizedBox(height: 12),

                        // Gender Selection
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 8),

                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGray,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.midGray),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: AppColors.charcoal),
                              SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    _buildGenderOption('Male', Icons.male, setState),
                                    SizedBox(width: 24),
                                    _buildGenderOption('Female', Icons.female, setState),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.charcoal,
                                  side: BorderSide(color: AppColors.charcoal),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _updateUserProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.black,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          "Home",
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.black,
        ),
        actions: [
          // Profile image in app bar
          if (imagePath != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: _showEditProfileDialog,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.midGray,
                  backgroundImage: FileImage(File(imagePath!)),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.charcoal),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section with profile image
              Row(
                children: [
                  // Profile image
                  if (imagePath != null)
                    Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.midGray,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Image.file(
                          File(imagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      margin: EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightGray,
                        border: Border.all(
                          color: AppColors.midGray,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.charcoal,
                      ),
                    ),

                  // Welcome text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome,",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.charcoal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // User details section
              if (currentUser != null)
                Container(
                  margin: EdgeInsets.symmetric(vertical: 24),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.midGray),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email, 'Email', currentUser!.email),
                      Divider(color: AppColors.midGray),
                      _buildInfoRow(Icons.location_city, 'City', currentUser!.city),
                      Divider(color: AppColors.midGray),
                      _buildInfoRow(Icons.person, 'Gender', currentUser!.gender),
                      Divider(color: AppColors.midGray),
                      _buildInfoRow(Icons.home, 'Address', currentUser!.address),
                    ],
                  ),
                ),

              SizedBox(height: 24),

              // Section title
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 16),

              // Dashboard Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.edit,
                      title: "Edit Profile",
                      onTap: _showEditProfileDialog,
                    ),
                    _buildDashboardCard(
                      icon: Icons.delete,
                      title: "Delete Account",
                      onTap: _deleteAccount,
                      color: AppColors.error,
                    ),
                    _buildDashboardCard(
                      icon: Icons.settings,
                      title: "Settings",
                      onTap: () {
                        // Navigate to settings screen
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.help_outline,
                      title: "Help",
                      onTap: () {
                        // Navigate to help screen
                      },
                    ),
                  ],
                ),
              ),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      style: TextStyle(
        color: AppColors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.charcoal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.midGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.midGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.charcoal, width: 2),
        ),
        filled: true,
        fillColor: AppColors.lightGray,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorStyle: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, IconData icon, StateSetter setState) {
    final isSelected = _selectedGender == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGender = value;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.charcoal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.charcoal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.charcoal,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.midGray, width: 1),
        ),
        color: AppColors.lightGray,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color ?? AppColors.charcoal,
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color != null ? color : AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.charcoal, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.charcoal,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}