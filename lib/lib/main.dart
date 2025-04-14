import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'slh/screens/home_screen.dart';
import 'slh/screens/login_screen.dart';
import 'slh/utils/shared_prefs.dart';
import 'dart:developer' as developer;

import 'scrollview/horizontal_scroll_screen.dart';
import 'scrollview/vertical_scroll_screen.dart';
import 'scrollview/custom_scroll_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure async operations work
  final bool isLoggedIn = await checkLoginStatus(); // Check login state
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> checkLoginStatus() async {
  try {
    return await SharedPrefs.isLoggedIn();
  } catch (e) {
    developer.log('Error using SharedPrefs utility, falling back to direct method: $e');
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF000000),
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF000000)),
          titleTextStyle: TextStyle(
            color: Color(0xFF000000),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF000000),
          secondary: Color(0xFF303030),
          error: Color(0xFFD32F2F),
        ),
      ),
      home: isLoggedIn ? HomeScreen() : LoginScreen(),
      routes: {
        '/horizontal': (context) => HorizontalScrollScreen(),
        '/vertical': (context) => VerticalScrollScreen(),
        '/custom': (context) => CustomScrollScreen(),
      },
    );
  }
}
