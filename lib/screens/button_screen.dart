import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';

class ButtonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Button Screen')),
      drawer: CustomDrawer(),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // No functionality for now
          },
          child: Text("Click Me"),
        ),
      ),
    );
  }
}
