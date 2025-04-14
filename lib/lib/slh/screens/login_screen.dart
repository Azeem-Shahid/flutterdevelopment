import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'package:lesson1/widgets/custom_drawer.dart';

import '../models/user_model.dart';

// Define the color palette
class AppColors {
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color charcoal = Color(0xFF303030);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color midGray = Color(0xFFD9D9D9);
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authController = AuthController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    bool isSuccess = await _authController.loginUser(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login successful",
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Add a slight delay to show success message before navigating
      Future.delayed(Duration(milliseconds: 800), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Invalid email or password",
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Login',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.black),
        // Add back button only if there's a previous page to go back to
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),
      drawer: CustomDrawer(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Login Icon
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lightGray,
                        border: Border.all(
                          color: AppColors.midGray,
                          width: 2,
                        ),
                      ),
                      padding: EdgeInsets.all(20),
                      child: Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Email Field
                  Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: TextTheme(
                        bodyLarge: TextStyle(
                          color: AppColors.black,
                          fontSize: 16,
                        ),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(
                          color: AppColors.charcoal,
                          fontSize: 16,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: AppColors.charcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    child: _buildInputField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        } else if (!value.contains('@')) {
                          return "Enter a valid email";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 20),

                  // Password Field
                  Theme(
                    data: Theme.of(context).copyWith(
                      textTheme: TextTheme(
                        bodyLarge: TextStyle(
                          color: AppColors.black,
                          fontSize: 16,
                        ),
                      ),
                      inputDecorationTheme: InputDecorationTheme(
                        labelStyle: TextStyle(
                          color: AppColors.charcoal,
                          fontSize: 16,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: AppColors.charcoal,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.charcoal),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.charcoal,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
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
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter your password";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 16),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Sign Up Option
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(color: AppColors.charcoal),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => SignupScreen()),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
          color: Colors.red.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
    );
  }
}