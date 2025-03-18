import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width
      padding: EdgeInsets.symmetric(vertical: 18), // Increased padding for better spacing
      color: Colors.orange, // Footer background color
      child: Center(
        child: Text(
          "© 2025 CS App | All Rights Reserved",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16, // Slightly larger font for better readability
            fontWeight: FontWeight.bold, // Bold text for emphasis
            letterSpacing: 0.5, // Improves readability
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
