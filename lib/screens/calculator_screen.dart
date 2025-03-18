import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'calculator_button.dart';
import '../widgets/custom_footer.dart';
import '../widgets/custom_drawer.dart';

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String input = "";
  String result = "0";
  String lastResult = "";

  void onButtonPressed(String value) {
    setState(() {
      if (value == "C") {
        input = "";
        result = "0";
        lastResult = "";
      } else if (value == "⌫") {
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1);
        }
      } else if (value == "=") {
        try {
          result = _calculateResult(input);
          lastResult = result;
        } catch (e) {
          result = "Error";
        }
      } else if (value == "ANS") {
        input += lastResult;
      } else if (value == "!") {
        if (input.isNotEmpty) {
          try {
            int number = int.parse(input);
            input = factorial(number).toString();
          } catch (e) {
            result = "Error";
          }
        }
      } else {
        input += value;
      }
    });
  }

  int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);
  }

  String _calculateResult(String expression) {
    try {
      double eval = _evaluateExpression(expression);
      return eval.toString();
    } catch (e) {
      return "Error";
    }
  }

  double _evaluateExpression(String expr) {
    expr = expr.replaceAll("×", "*").replaceAll("÷", "/");

    try {
      Parser p = Parser();
      Expression exp = p.parse(expr);
      ContextModel cm = ContextModel();
      return exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      return double.nan;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Calculator",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.06,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          _buildDisplay(screenWidth),
          Divider(color: Colors.white24),
          _buildButtons(screenWidth),
          CustomFooter(),
        ],
      ),
    );
  }

  Widget _buildDisplay(double screenWidth) {
    return Expanded(
      child: Container(
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                input.isEmpty ? "0" : input,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                result,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons(double screenWidth) {
    return Column(
      children: [
        _buildButtonRow(["C", "⌫", "ANS", "÷"], screenWidth),
        _buildButtonRow(["7", "8", "9", "×"], screenWidth),
        _buildButtonRow(["4", "5", "6", "-"], screenWidth),
        _buildButtonRow(["1", "2", "3", "+"], screenWidth),
        _buildButtonRow(["0", ".", "=", "!"], screenWidth),
      ],
    );
  }

  Widget _buildButtonRow(List<String> labels, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: labels.map((label) {
        return Flexible(
          child: CalculatorButton(label, onButtonPressed),
        );
      }).toList(),
    );
  }
}
