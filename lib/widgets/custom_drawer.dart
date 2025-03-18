import 'package:flutter/material.dart';
import 'package:lesson1/screens/home_screen.dart';
import 'package:lesson1/screens/calculator_screen.dart';
import 'package:lesson1/screens/cgpa_screen.dart';
import 'package:lesson1/screens/name_screen.dart';
import 'package:lesson1/screens/button_screen.dart';
import 'package:lesson1/screens/cycle_name_screen.dart';
import 'package:lesson1/screens/name_button_screen.dart';
import 'package:lesson1/screens/register_screen.dart';

import 'package:lesson1/slh/screens/signup_screen.dart';
import 'package:lesson1/slh/screens/login_screen.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.black, // Dark theme
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.orange),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle, size: 70, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      "Azeem Shahid",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(context, Icons.home, "Home", HomeScreen()),
                  _buildDrawerItem(context, Icons.calculate, "Calculator", CalculatorScreen()),
                  _buildDrawerItem(context, Icons.school, "CGPA Result", CGPAResultScreen()),

                  Divider(color: Colors.grey),

                  _buildDrawerItem(context, Icons.person, "Name Screen", NameScreen()),
                  _buildDrawerItem(context, Icons.touch_app, "Button Screen", ButtonScreen()),
                  _buildDrawerItem(context, Icons.loop, "Cycle Name Screen", CycleNameScreen()),
                  _buildDrawerItem(context, Icons.person, "Name & Button", NameButtonScreen()),

                  Divider(color: Colors.grey),

                  _buildDrawerItem(context, Icons.person_add, "Signup", SignupScreen()),
                  _buildDrawerItem(context, Icons.login, "Login", LoginScreen()),

                  _buildDrawerItem(context, Icons.settings, "Settings", null), // Placeholder for Settings
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to reduce duplicate code
  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, Widget? screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (screen != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
    );
  }
}
