import 'package:flutter/material.dart';
import 'assets.dart';
import 'widgets/image_card.dart';

class CustomScrollScreen extends StatefulWidget {
  const CustomScrollScreen({Key? key}) : super(key: key);

  @override
  State<CustomScrollScreen> createState() => _CustomScrollScreenState();
}

class _CustomScrollScreenState extends State<CustomScrollScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Local', 'Network'];
  int _selectedTab = 0;
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _getImagesForTab() {
    switch (_selectedTab) {
      case 0: // All
        return [...Assets.localImages, ...Assets.urlImages];
      case 1: // Local
        return Assets.localImages;
      case 2: // Network
        return Assets.urlImages;
      default:
        return [];
    }
  }

  List<bool> _getIsLocalForTab() {
    switch (_selectedTab) {
      case 0: // All
        return [
          ...List.generate(Assets.localImages.length, (_) => true),
          ...List.generate(Assets.urlImages.length, (_) => false)
        ];
      case 1: // Local
        return List.generate(Assets.localImages.length, (_) => true);
      case 2: // Network
        return List.generate(Assets.urlImages.length, (_) => false);
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _getImagesForTab();
    final isLocalList = _getIsLocalForTab();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Media Library',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isListView ? Icons.grid_view : Icons.view_list,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              // Handle menu selection
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sort',
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 20, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Sort'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Filter'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
        ),
      ),
      body: _isListView ? _buildListView(images, isLocalList) : _buildGridView(images, isLocalList),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new image action
          _showAddOptions(context);
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildGridView(List<String> images, List<bool> isLocalList) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: GridView.builder(
        key: ValueKey('grid'),
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ImageCard(
            imageUrl: images[index],
            isLocal: isLocalList[index],
            title: isLocalList[index]
                ? 'Local ${index + 1}'
                : 'Network ${index + 1}',
            onTap: () {
              _showImageOptions(context, images[index], isLocalList[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildListView(List<String> images, List<bool> isLocalList) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: ListView.builder(
        key: ValueKey('list'),
        padding: EdgeInsets.all(8),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: EdgeInsets.all(8),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: isLocalList[index]
                      ? Image.asset(
                    images[index],
                    fit: BoxFit.cover,
                  )
                      : Image.network(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                isLocalList[index] ? 'Local Image ${index + 1}' : 'Network Image ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isLocalList[index] ? 'Local storage' : 'Cloud storage',
                style: TextStyle(fontSize: 12),
              ),
              trailing: Icon(Icons.more_vert),
              onTap: () {
                _showImageOptions(context, images[index], isLocalList[index]);
              },
            ),
          );
        },
      ),
    );
  }

  void _showImageOptions(BuildContext context, String imageUrl, bool isLocal) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.fullscreen, color: Colors.blue),
                title: Text('View full size'),
                onTap: () {
                  Navigator.pop(context);
                  _showFullImage(context, imageUrl, isLocal);
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: Colors.blue),
                title: Text('Image details'),
                onTap: () {
                  Navigator.pop(context);
                  // Show image details
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: Colors.blue),
                title: Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Share image
                },
              ),
              if (isLocal)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    // Delete image
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showFullImage(BuildContext context, String imageUrl, bool isLocal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(Icons.share),
                onPressed: () {
                  // Share image
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: isLocal
                  ? Image.asset(imageUrl)
                  : Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.blue),
                title: Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Open camera
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Open gallery
                },
              ),
              ListTile(
                leading: Icon(Icons.link, color: Colors.blue),
                title: Text('Add from URL'),
                onTap: () {
                  Navigator.pop(context);
                  // Add URL dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }
}