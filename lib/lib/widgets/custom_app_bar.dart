import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        "CS App",
        style: TextStyle(
          fontWeight: FontWeight.bold, // Make text bold
          fontSize: 23, // Slightly larger font
        ),
      ),
      centerTitle: true, // Center the title in the AppBar
      actions: [
        IconButton(
          icon: Icon(Icons.settings, size: 28, weight: 900), // Bold icon
          onPressed: () {
            // TODO: Add settings navigation
          },
        ),
      ],
      backgroundColor: Colors.orange, // Dark theme
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
