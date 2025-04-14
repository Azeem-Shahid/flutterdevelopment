import 'package:flutter/material.dart';
import 'assets.dart';
import 'widgets/image_card.dart';

class VerticalScrollScreen extends StatefulWidget {
  const VerticalScrollScreen({Key? key}) : super(key: key);

  @override
  State<VerticalScrollScreen> createState() => _VerticalScrollScreenState();
}

class _VerticalScrollScreenState extends State<VerticalScrollScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    _scrollController.addListener(() {
      setState(() {
        _showBackToTopButton = _scrollController.offset >= 300;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              title: const Text('Gallery', style: TextStyle(color: Colors.black87)),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.view_module, color: Colors.black87),
                  onPressed: () {
                    // Toggle view type
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  onPressed: () {},
                ),
              ],
            ),

            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore your collection',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Browse through your images and discover new content',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Local Images Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.photo_library, size: 20, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Text(
                      'Local Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Local Images Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final imageUrl = Assets.localImages[index];
                    return ImageCard(
                      imageUrl: imageUrl,
                      isLocal: true,
                      title: 'Local ${index + 1}',
                      onTap: () {
                        _showImageDetail(context, imageUrl, true);
                      },
                    );
                  },
                  childCount: Assets.localImages.length,
                ),
              ),
            ),

            // Network Images Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.cloud, size: 20, color: Colors.teal[700]),
                    SizedBox(width: 8),
                    Text(
                      'Online Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Network Images - Staggered Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    // Create a repeating pattern with different aspect ratios
                    double aspectRatio = 1.0;
                    if (index % 5 == 0) aspectRatio = 1.0; // Square
                    if (index % 5 == 1) aspectRatio = 0.8; // Portrait
                    if (index % 5 == 2) aspectRatio = 1.0; // Square
                    if (index % 5 == 3) aspectRatio = 1.5; // Landscape
                    if (index % 5 == 4) aspectRatio = 1.0; // Square

                    final imageUrl = Assets.urlImages[index % Assets.urlImages.length];
                    return AspectRatio(
                      aspectRatio: aspectRatio,
                      child: ImageCard(
                        imageUrl: imageUrl,
                        isLocal: false,
                        title: 'Network ${index + 1}',
                        onTap: () {
                          _showImageDetail(context, imageUrl, false);
                        },
                      ),
                    );
                  },
                  childCount: 15, // Display more images by repeating
                ),
              ),
            ),

            // Footer Space
            SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        mini: true,
        onPressed: _scrollToTop,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.arrow_upward),
      )
          : null,
    );
  }

  void _showImageDetail(BuildContext context, String imageUrl, bool isLocal) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Image with pinch to zoom
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: isLocal
                      ? Image.asset(imageUrl)
                      : Image.network(imageUrl),
                ),
                // Close button
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}