import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart'; // Import Custom Drawer

class NameButtonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Name & Button Screen"), // Screen title
        backgroundColor: Colors.orange, // App bar color
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back), // Back arrow icon
        //   onPressed: () => Navigator.pop(context), // Navigate back
        // ),
      ),
      drawer: CustomDrawer(), // Custom Drawer added
      body: _buildBody(context), // Body refactored into a separate method
    );
  }

  /// Builds the main body UI
  Widget _buildBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNameText(), // Static name display
          SizedBox(height: 20),
          _buildButton(context), // Button to show message
        ],
      ),
    );
  }

  /// Displays the static name
  Widget _buildNameText() {
    return Text(
      "Azeem Shahid",
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  /// Button that shows a SnackBar message when clicked
  Widget _buildButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Button Clicked!"),
            duration: Duration(seconds: 2), // Message disappears after 2 sec
          ),
        );
      },
      child: Text("Click Me"),
    );
  }
}
