// lib/widgets/custom_drawer.dart
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
import 'package:lesson1/slh/screens/login_screen.dart' as slh;
import 'package:lesson1/sqlite/database_helper.dart';
import 'package:lesson1/sqlite/abc_screen.dart';
import 'package:lesson1/sqlite/user.dart';
import 'package:lesson1/sqlite/user_management_screen.dart';
import 'package:lesson1/screens/subject_marks_screen.dart'; // Import the subject marks screen
import 'package:lesson1/api/api_data.dart'; // Import the API data file
import 'package:lesson1/api/student_grade_screen.dart'; // Import the new student grades screen
import 'package:lesson1/api/add_grade_form.dart'; // Import the add grade form
import 'package:lesson1/api/student_grade_screen.dart';
class CustomDrawer extends StatefulWidget {
  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _drawerContentsOpacity;
  late Animation<Offset> _drawerItemSlide;
  Set<String> _expandedCategories = {'Main', 'SQLite', 'API'}; // Added 'API' to initially expanded categories
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _drawerContentsOpacity = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _drawerItemSlide = Tween<Offset>(
      begin: Offset(-1, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Define menu items
  List<Map<String, dynamic>> get _menuItems => [
    {
      'title': 'Home',
      'icon': Icons.home,
      'screen': HomeScreen(),
      'category': 'Main'
    },
    {
      'title': 'Calculator',
      'icon': Icons.calculate,
      'screen': CalculatorScreen(),
      'category': 'Main'
    },
    {
      'title': 'CGPA Result',
      'icon': Icons.school,
      'screen': CGPAResultScreen(),
      'category': 'Main'
    },
    {
      'title': 'Subject Marks',
      'icon': Icons.assignment,
      'screen': SubjectMarksScreen(),
      'category': 'Main'
    },
    // Student Results API Section
    {
      'title': 'Student Results',
      'icon': Icons.analytics,
      'screen': StudentResultsPage(),
      'category': 'API'
    },
    {
      'title': 'Grades Manager',
      'icon': Icons.grade,
      'screen': StudentGradeScreen(),
      'category': 'API'
    },
    {
      'title': 'Add Grade',
      'icon': Icons.add_chart,
      'screen': AddGradeForm(onGradeAdded: () {}),
      'category': 'API'
    },
    {
      'title': 'Name Screen',
      'icon': Icons.person,
      'screen': NameScreen(),
      'category': 'Basic UI'
    },
    {
      'title': 'Button Screen',
      'icon': Icons.touch_app,
      'screen': ButtonScreen(),
      'category': 'Basic UI'
    },
    {
      'title': 'Cycle Name Screen',
      'icon': Icons.loop,
      'screen': CycleNameScreen(),
      'category': 'Basic UI'
    },
    {
      'title': 'Name & Button',
      'icon': Icons.person_search,
      'screen': NameButtonScreen(),
      'category': 'Basic UI'
    },
    {
      'title': 'Signup',
      'icon': Icons.person_add,
      'screen': SignupScreen(),
      'category': 'Authentication'
    },
    {
      'title': 'SLH Login',
      'icon': Icons.login,
      'screen': slh.LoginScreen(),
      'category': 'Authentication'
    },
    {
      'title': 'ABC Screen',
      'icon': Icons.admin_panel_settings,
      'screen': ABC_Screen(),
      'category': 'SQLite'
    },
    {
      'title': 'User Management',
      'icon': Icons.manage_accounts,
      'screen': UserManagementScreen(),
      'category': 'SQLite'
    },
    {
      'title': 'Horizontal Scroll',
      'icon': Icons.horizontal_rule,
      'route': '/horizontal',
      'category': 'Scroll Views'
    },
    {
      'title': 'Vertical Scroll',
      'icon': Icons.vertical_align_bottom,
      'route': '/vertical',
      'category': 'Scroll Views'
    },
    {
      'title': 'Grid Scroll',
      'icon': Icons.grid_view,
      'route': '/custom',
      'category': 'Scroll Views'
    },
    {
      'title': 'Settings',
      'icon': Icons.settings,
      'screen': null,
      'category': 'System'
    },
  ];

  // Group menu items by category
  Map<String, List<Map<String, dynamic>>> get _groupedMenuItems {
    Map<String, List<Map<String, dynamic>>> result = {};

    for (var item in _menuItems) {
      String category = item['category'] ?? 'Other';
      if (!result.containsKey(category)) {
        result[category] = [];
      }
      result[category]!.add(item);
    }

    return result;
  }

  // Build category section
  Widget _buildCategorySection(String category, List<Map<String, dynamic>> items) {
    bool isExpanded = _expandedCategories.contains(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(category);
                } else {
                  _expandedCategories.add(category);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
        Divider(color: Colors.grey.shade700, thickness: 0.5, indent: 16, endIndent: 16),
        if (isExpanded)
          AnimatedOpacity(
            opacity: isExpanded ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            child: Column(
              children: items.asMap().entries.map((entry) {
                int idx = entry.key;
                var item = entry.value;
                int itemIndex = _menuItems.indexWhere((menuItem) =>
                menuItem['title'] == item['title'] && menuItem['icon'] == item['icon']);
                return _buildDrawerItem(
                  context,
                  item['icon'],
                  item['title'],
                  item['screen'],
                  item['route'],
                  (idx * 0.05), // stagger animation
                  (itemIndex == _currentIndex),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // Helper function for navigating to screens directly
  Widget _buildDrawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget? screen,
      String? route,
      double delay,
      bool isSelected,
      ) {
    return FadeTransition(
      opacity: _drawerContentsOpacity,
      child: SlideTransition(
        position: _drawerItemSlide,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.transparent,
          ),
          child: ListTile(
            leading: Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.white,
              size: 22,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onTap: () {
              setState(() {
                _currentIndex = _menuItems.indexWhere((item) =>
                item['title'] == title && item['icon'] == icon);
              });

              Navigator.pop(context);
              if (screen != null) {
                // Special case for Add Grade form
                if (title == 'Add Grade') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddGradeForm(
                        onGradeAdded: () {
                          // Refresh logic if needed
                        },
                      ),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => screen,
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        var begin = Offset(1.0, 0.0);
                        var end = Offset.zero;
                        var curve = Curves.ease;

                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ),
                  );
                }
              } else if (route != null) {
                Navigator.pushNamed(context, route);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get active route name to highlight current screen
    ModalRoute? route = ModalRoute.of(context);
    if (route != null) {
      for (int i = 0; i < _menuItems.length; i++) {
        if (_menuItems[i]['route'] == route.settings.name) {
          _currentIndex = i;
          break;
        }
      }
    }

    return Drawer(
      child: Container(
        color: Colors.black, // Dark theme
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.orange.shade900, Colors.orange],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        radius: 40,
                        child: Icon(
                            Icons.account_circle,
                            size: 70,
                            color: Colors.white
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Azeem Shahid",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 8),
                children: _groupedMenuItems.entries.map((entry) {
                  return _buildCategorySection(entry.key, entry.value);
                }).toList(),
              ),
            ),
            Divider(color: Colors.grey.shade800),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white70),
              title: Text(
                'App Version 1.0.0',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}