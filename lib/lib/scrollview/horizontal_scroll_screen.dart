import 'package:flutter/material.dart';
import 'assets.dart';
import 'widgets/image_card.dart';

class HorizontalScrollScreen extends StatefulWidget {
  const HorizontalScrollScreen({Key? key}) : super(key: key);

  @override
  State<HorizontalScrollScreen> createState() => _HorizontalScrollScreenState();
}

class _HorizontalScrollScreenState extends State<HorizontalScrollScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _categories = ['All', 'Nature', 'Animals', 'Architecture', 'Abstract'];
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showImageDetail(BuildContext context, String imageUrl, bool isLocal, String title, String category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  height: 5,
                  width: 40,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: Colors.white,
                        automaticallyImplyLeading: false,
                        title: Text(
                          title,
                          style: TextStyle(color: Colors.black87),
                        ),
                        actions: [
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.black87),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: imageUrl,
                              child: isLocal
                                  ? Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 300,
                              )
                                  : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 300,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Chip(
                                    label: Text(category),
                                    backgroundColor: Colors.blue.shade100,
                                    labelStyle: TextStyle(color: Colors.blue.shade800),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                                        'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                                        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                                        'nisi ut aliquip ex ea commodo consequat.',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Discover',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                expandedTitleScale: 1.5,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.black87),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Category Filter
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((category) =>
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              }
                            },
                            selectedColor: Colors.blue.shade100,
                            labelStyle: TextStyle(
                              color: _selectedCategory == category
                                  ? Colors.blue.shade800
                                  : Colors.black54,
                              fontWeight: _selectedCategory == category
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                    ).toList(),
                  ),
                ),
              ),
            ),

            // Featured Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Images
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: Assets.urlImages.length,
                  itemBuilder: (context, index) {
                    final imageUrl = Assets.urlImages[index];
                    return ImageCard(
                      imageUrl: imageUrl,
                      isLocal: false,
                      width: 180,
                      height: 240,
                      title: 'Item ${index + 1}',
                      subtitle: 'Category: ${_categories[index % _categories.length]}',
                      onTap: () {
                        _showImageDetail(
                            context,
                            imageUrl,
                            false,
                            'Item ${index + 1}',
                            _categories[index % _categories.length]
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Local Images Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Local Collection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Local Images Horizontal Scroll
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: Assets.localImages.length,
                  itemBuilder: (context, index) {
                    final imageUrl = Assets.localImages[index];
                    return ImageCard(
                      imageUrl: imageUrl,
                      isLocal: true,
                      width: 140,
                      height: 160,
                      title: 'Local ${index + 1}',
                      onTap: () {
                        _showImageDetail(
                            context,
                            imageUrl,
                            true,
                            'Local ${index + 1}',
                            'Local Collection'
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Popular This Week Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popular This Week',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See All',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Popular Images (Different layout)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: Assets.urlImages.length,
                  itemBuilder: (context, index) {
                    // Use reversed order to show different images
                    final reversedIndex = Assets.urlImages.length - 1 - index;
                    final imageUrl = Assets.urlImages[reversedIndex];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _showImageDetail(
                                        context,
                                        imageUrl,
                                        false,
                                        'Popular ${index + 1}',
                                        'Weekly Highlights'
                                    );
                                  },
                                  child: Image.network(
                                    imageUrl,
                                    width: 160,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          (4 + (index / 10)).toStringAsFixed(1),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Popular ${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${1200 - (index * 100)} views',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Footer spacing
            SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }
}