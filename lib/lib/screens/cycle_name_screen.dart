import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart'; // Import Custom Drawer

class CycleNameScreen extends StatefulWidget {
  @override
  _CycleNameScreenState createState() => _CycleNameScreenState();
}

class _CycleNameScreenState extends State<CycleNameScreen> {
  final List<String> names = ["Azeem Shahid", "John Doe", "Jane Smith"];
  int index = 0;

  void changeName() => setState(() => index = (index + 1) % names.length); // Optimized function

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cycle Name Screen"),
        backgroundColor: Colors.orange,
        // leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      drawer: CustomDrawer(), // Added Custom Drawer
      body: _buildBody(),
    );
  }

  /// Builds the main body UI
  Widget _buildBody() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(names[index], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          ElevatedButton(onPressed: changeName, child: Text("Change Name")),
        ],
      ),
    );
  }
}
