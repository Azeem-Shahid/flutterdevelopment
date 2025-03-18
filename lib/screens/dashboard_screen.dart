import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserController _userController = UserController();
  List<Map<String, String>> allUsers = [];
  List<Map<String, String>> filteredUsers = [];
  bool _isLoading = true;
  String _filterStatus = 'All'; // 'All', 'Active', 'Inactive'
  TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Define gradient colors
  final Color purpleColor = Color(0xFF7E3FF2);
  final Color tealColor = Color(0xFF3FCDDA);

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      // Clear existing data first
      setState(() {
        allUsers = [];
        filteredUsers = [];
      });

      // Fetch fresh data
      List<Map<String, String>> loadedUsers = await _userController.getUsers();

      // Sort by createdAt timestamp (newest first)
      loadedUsers.sort((a, b) {
        // If createdAt is not available, put the entry at the end
        if (a['createdAt'] == null) return 1;
        if (b['createdAt'] == null) return -1;

        // Parse timestamps and sort in descending order (newest first)
        DateTime dateA = DateTime.parse(a['createdAt']!);
        DateTime dateB = DateTime.parse(b['createdAt']!);
        return dateB.compareTo(dateA);
      });

      setState(() {
        allUsers = loadedUsers;
        _filterUsers();
        _isLoading = false;
      });

      // Show success message
      _showSuccessToast('Users refreshed successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorToast('Error loading users: ${e.toString()}');
    }
  }

  void _showSuccessToast(String message) {
    // Ensure any existing SnackBar is dismissed to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      elevation: 10, // Higher elevation for better z-index
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      duration: Duration(seconds: 2),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showErrorToast(String message) {
    // Ensure any existing SnackBar is dismissed to prevent stacking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      elevation: 10, // Higher elevation for better z-index
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      duration: Duration(seconds: 3),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _filterUsers() {
    setState(() {
      filteredUsers = allUsers.where((user) {
        // Apply status filter
        if (_filterStatus != 'All' && user['status'] != _filterStatus) {
          return false;
        }

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          final String name = user['name']?.toLowerCase() ?? '';
          final String email = user['email']?.toLowerCase() ?? '';
          final String searchText = _searchController.text.toLowerCase();
          return name.contains(searchText) || email.contains(searchText);
        }

        return true;
      }).toList();
    });
  }

  int get _totalUsers => allUsers.length;
  int get _activeUsers => allUsers.where((user) => user['status'] == 'Active').length;
  int get _inactiveUsers => allUsers.where((user) => user['status'] == 'Inactive').length;

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: purpleColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              purpleColor,
              tealColor,
            ],
          ),
        ),
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        )
            : CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Search and filter section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.normal,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

            // Filter buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _filterButton('All', purpleColor)),
                    SizedBox(width: 8),
                    Expanded(child: _filterButton('Active', Colors.green)),
                    SizedBox(width: 8),
                    Expanded(child: _filterButton('Inactive', Colors.red)),
                  ],
                ),
              ),
            ),

            // Stats Cards - Responsive row
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate card width based on available space
                    // Subtract spacing between cards (8px * 2) from total width and divide by 3
                    final cardWidth = (constraints.maxWidth - 16) / 3;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                            'Total',
                            _totalUsers.toString(),
                            Colors.white,
                            Icons.people_alt,
                            width: cardWidth
                        ),
                        _buildStatCard(
                            'Active',
                            _activeUsers.toString(),
                            Colors.green.shade50,
                            Icons.check_circle,
                            iconColor: Colors.green,
                            textColor: Colors.green.shade800,
                            width: cardWidth
                        ),
                        _buildStatCard(
                            'Inactive',
                            _inactiveUsers.toString(),
                            Colors.red.shade50,
                            Icons.cancel,
                            iconColor: Colors.red,
                            textColor: Colors.red.shade800,
                            width: cardWidth
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // User count indicator
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Showing ${filteredUsers.length} of ${allUsers.length} users',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    if (_filterStatus != 'All' || _searchController.text.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _filterStatus = 'All';
                            _searchController.clear();
                            _filterUsers();
                          });
                        },
                        icon: Icon(Icons.clear, color: Colors.white, size: 16),
                        label: Text(
                          'Clear filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // User List with bottom padding
            filteredUsers.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: 64,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Users Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final user = filteredUsers[index];
                    final isActive = user['status'] == 'Active';
                    final createdAtString = _formatTimestamp(user['createdAt']);

                    // Check if this is the last item
                    final bool isLastItem = index == filteredUsers.length - 1;

                    return Container(
                      margin: EdgeInsets.only(
                        bottom: isLastItem ? 24 : 12, // Add extra margin for the last item
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              color: isActive ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [purpleColor, tealColor],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  user['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (createdAtString.isNotEmpty)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  createdAtString,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    user['email'] ?? 'No email',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: purpleColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              color: purpleColor,
                              size: 16,
                            ),
                          ),
                          onPressed: () => _navigateToProfile(user['key']!),
                        ),
                        onTap: () => _navigateToProfile(user['key']!),
                      ),
                    );
                  },
                  childCount: filteredUsers.length,
                ),
              ),
            ),

            // Add padding at the bottom to ensure proper spacing
            SliverToBoxAdapter(
              child: SizedBox(height: 80), // Space for FloatingActionButton
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context); // Go back to register screen
        },
        backgroundColor: tealColor,
        child: Icon(Icons.add),
        tooltip: 'Add New User',
      ),
    );
  }

  Future<void> _navigateToProfile(String userKey) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userKey: userKey),
      ),
    );

    if (result == true) {
      _loadUsers(); // Refresh the list if user was updated
    }
  }

  Widget _filterButton(String status, Color color) {
    final isSelected = _filterStatus == status;

    return IntrinsicWidth(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _filterStatus = status;
            _filterUsers();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.white,
          foregroundColor: isSelected ? Colors.white : color,
          elevation: isSelected ? 2 : 0,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color, width: 1.5),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color bgColor, IconData icon, {
    Color? iconColor,
    Color? textColor,
    double? width,
  }) {
    return Container(
      width: width,
      height: 80, // Slightly increased height to accommodate the icon
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? textColor ?? Colors.black87,
              ),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}