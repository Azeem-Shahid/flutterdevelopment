import 'package:flutter/material.dart';

class CalculatorButton extends StatelessWidget {
  final String label;
  final Function(String) onPressed;

  CalculatorButton(this.label, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      child: ElevatedButton(
        onPressed: () => onPressed(label),
        style: ElevatedButton.styleFrom(
          shape: CircleBorder(),
          padding: EdgeInsets.all(20),
          backgroundColor: _getButtonColor(label),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }

  Color _getButtonColor(String label) {
    if (label == "C") return Colors.red;
    if (label == "=") return Colors.green;
    if (label == "⌫" || label == "÷" || label == "×" || label == "-" || label == "+")
      return Colors.orange;
    return Colors.grey[850]!;
  }
}
