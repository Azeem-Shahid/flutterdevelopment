import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'package:lesson1/widgets/custom_drawer.dart';
import 'package:lesson1/slh/screens/login_screen.dart'; // Import for navigation

// Define the color palette based on the provided image
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

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController();

  // Controllers for text fields
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  String? selectedGender;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isPasswordVisible = false;

  // Track current step
  int _currentStep = 0;

  // Function to pick an image
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      int imageSize = await imageFile.length(); // Get file size

      if (imageSize > 400 * 1024) { // Validate file size (400KB)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Image must be less than 400KB',
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
      } else {
        setState(() {
          _image = imageFile;
        });
      }
    }
  }

  void _signup() async {
    if (!_validateAllFields()) {
      return;
    }

    UserModel newUser = UserModel(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      city: cityController.text,
      address: addressController.text,
      gender: selectedGender!,
      imagePath: _image?.path, // Save image path
    );

    bool isRegistered = await _authController.registerUser(newUser);

    if (isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signup Successful!',
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

      // Navigate to login screen only after successful registration
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Signup Failed! Please check your inputs.',
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

  // Validate all fields
  bool _validateAllFields() {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile image is required',
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
        return false;
      }

      if (selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select your gender',
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
        return false;
      }
      return true;
    }
    return false;
  }

  // Validate step 1 before proceeding
  bool _validateStep1() {
    if (nameController.text.isEmpty) {
      _showErrorSnackBar('Full Name is required');
      return false;
    }

    if (emailController.text.isEmpty) {
      _showErrorSnackBar('Email Address is required');
      return false;
    }

    if (!emailController.text.contains('@')) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }

    if (_image == null) {
      _showErrorSnackBar('Profile image is required');
      return false;
    }

    return true;
  }

  // Validate step 2 before proceeding
  bool _validateStep2() {
    if (passwordController.text.isEmpty) {
      _showErrorSnackBar('Password is required');
      return false;
    }

    if (passwordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters');
      return false;
    }

    if (selectedGender == null) {
      _showErrorSnackBar('Please select your gender');
      return false;
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Create Account',
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
        // Add back button only if there's a previous page to go back to
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        actions: [
          // Progress indicator in app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentStep >= 0 ? AppColors.black : AppColors.midGray,
                    ),
                  ),
                  SizedBox(width: 5),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentStep >= 1 ? AppColors.black : AppColors.midGray,
                    ),
                  ),
                  SizedBox(width: 5),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentStep >= 2 ? AppColors.black : AppColors.midGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                  Center(
                    child: Text(
                      'Join Us',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Create your profile to get started',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.charcoal,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Stepper for better form organization
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: AppColors.black,
                        secondary: AppColors.charcoal,
                      ),
                    ),
                    child: Stepper(
                      type: StepperType.vertical,
                      currentStep: _currentStep,
                      controlsBuilder: (context, details) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: [
                              if (_currentStep > 0)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: details.onStepCancel,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.charcoal,
                                      side: BorderSide(color: AppColors.charcoal),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Text(
                                      'Previous',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              if (_currentStep > 0) SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: details.onStepContinue,
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
                                    _currentStep < 2 ? 'Next' : 'Create Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onStepContinue: () {
                        if (_currentStep == 0) {
                          if (_validateStep1()) {
                            setState(() {
                              _currentStep += 1;
                            });
                          }
                        } else if (_currentStep == 1) {
                          if (_validateStep2()) {
                            setState(() {
                              _currentStep += 1;
                            });
                          }
                        } else {
                          _signup();
                        }
                      },
                      onStepCancel: () {
                        if (_currentStep > 0) {
                          setState(() {
                            _currentStep -= 1;
                          });
                        }
                      },
                      onStepTapped: (step) {
                        // Only allow tapping to a step if all previous steps are validated
                        if (step < _currentStep) {
                          setState(() {
                            _currentStep = step;
                          });
                        } else if (step > _currentStep) {
                          if (step == 1 && _currentStep == 0) {
                            if (_validateStep1()) {
                              setState(() {
                                _currentStep = step;
                              });
                            }
                          } else if (step == 2 && _currentStep == 1) {
                            if (_validateStep2()) {
                              setState(() {
                                _currentStep = step;
                              });
                            }
                          }
                        }
                      },
                      steps: [
                        // Step 1: Profile Information
                        Step(
                          title: Text(
                            'Profile Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          content: Column(
                            children: [
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
                                        backgroundImage: _image != null ? FileImage(_image!) : null,
                                        child: _image == null
                                            ? Icon(Icons.person, size: 60, color: AppColors.charcoal)
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _pickImage,
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
                              if (_image == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Profile image is required',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 24),

                              // Name Field
                              _buildInputField(
                                controller: nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (value) => value!.isEmpty ? 'Full Name is required' : null,
                              ),
                              SizedBox(height: 16),

                              // Email Field
                              _buildInputField(
                                controller: emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) =>
                                value!.isEmpty ? 'Email Address is required' :
                                !value.contains('@') ? 'Enter a valid email' : null,
                              ),
                            ],
                          ),
                          isActive: _currentStep >= 0,
                          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                        ),

                        // Step 2: Security
                        Step(
                          title: Text(
                            'Security',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          content: Column(
                            children: [
                              // Password Field
                              TextFormField(
                                controller: passwordController,
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
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                validator: (value) => value!.isEmpty ? 'Password is required' :
                                value.length < 6 ? 'Password must be at least 6 characters' : null,
                              ),
                              SizedBox(height: 16),

                              // Password strength indicator
                              if (passwordController.text.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Strength:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.charcoal,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: passwordController.text.length < 6
                                          ? 0.3
                                          : passwordController.text.length < 10
                                          ? 0.6
                                          : 1.0,
                                      backgroundColor: AppColors.midGray,
                                      color: passwordController.text.length < 6
                                          ? AppColors.error
                                          : passwordController.text.length < 10
                                          ? Colors.orange
                                          : AppColors.success,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      passwordController.text.length < 6
                                          ? 'Weak'
                                          : passwordController.text.length < 10
                                          ? 'Medium'
                                          : 'Strong',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: passwordController.text.length < 6
                                            ? AppColors.error
                                            : passwordController.text.length < 10
                                            ? Colors.orange
                                            : AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                              SizedBox(height: 16),

                              // Gender Selection
                              Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              SizedBox(height: 12),

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
                                          _buildGenderOption('Male', Icons.male),
                                          SizedBox(width: 24),
                                          _buildGenderOption('Female', Icons.female),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedGender == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Gender selection is required',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          isActive: _currentStep >= 1,
                          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                        ),

                        // Step 3: Location
                        Step(
                          title: Text(
                            'Location Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          content: Column(
                            children: [
                              // City Field
                              _buildInputField(
                                controller: cityController,
                                label: 'City',
                                icon: Icons.location_city_outlined,
                                validator: (value) => value!.isEmpty ? 'City is required' : null,
                              ),
                              SizedBox(height: 16),

                              // Address Field
                              _buildInputField(
                                controller: addressController,
                                label: 'Address',
                                icon: Icons.home_outlined,
                                validator: (value) => value!.isEmpty ? 'Address is required' : null,
                              ),
                              SizedBox(height: 24),

                              // Terms and conditions checkbox
                              Row(
                                children: [
                                  Checkbox(
                                    value: true, // You can make this dynamic
                                    onChanged: (value) {},
                                    activeColor: AppColors.black,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'I agree to the Terms of Service and Privacy Policy',
                                      style: TextStyle(
                                        color: AppColors.charcoal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isActive: _currentStep >= 2,
                          state: StepState.indexed,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Login Option
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.charcoal,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to login page
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
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
          color: AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderOption(String value, IconData icon) {
    final isSelected = selectedGender == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedGender = value;
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
}