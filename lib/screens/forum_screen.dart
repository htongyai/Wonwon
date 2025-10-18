import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/forum_topic.dart';
import 'package:wonwonw2/screens/forum_create_topic_screen.dart';
import 'package:wonwonw2/screens/forum_topic_detail_screen.dart';
import 'package:wonwonw2/services/forum_service.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/performance_loading_widget.dart';
import 'package:wonwonw2/mixins/auth_state_mixin.dart';
import 'dart:async';

class ForumScreen extends StatefulWidget {
  const ForumScreen({Key? key}) : super(key: key);

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with AuthStateMixin {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'name': 'All Topics',
      'icon': FontAwesomeIcons.globe,
      'color': Colors.blue,
    },
    {
      'id': 'general',
      'name': 'General Discussion',
      'icon': FontAwesomeIcons.comments,
      'color': Colors.green,
    },
    {
      'id': 'repair_tips',
      'name': 'Repair Tips & Tricks',
      'icon': FontAwesomeIcons.wrench,
      'color': Colors.orange,
    },
    {
      'id': 'shop_reviews',
      'name': 'Shop Reviews',
      'icon': FontAwesomeIcons.star,
      'color': Colors.purple,
    },
    {
      'id': 'questions',
      'name': 'Questions & Help',
      'icon': FontAwesomeIcons.questionCircle,
      'color': Colors.red,
    },
    {
      'id': 'announcements',
      'name': 'Announcements',
      'icon': FontAwesomeIcons.bullhorn,
      'color': Colors.teal,
    },
  ];

  List<ForumTopic> _topics = [];
  bool _isLoading = true;
  // Removed unused _isRefreshing field
  Stream<List<ForumTopic>>? _topicsStream;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _loadTopics() {
    setState(() {
      _isLoading = true;
    });

    _topicsStream = ForumService.getTopics(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );

    _topicsStream!.listen(
      (topics) {
        if (mounted) {
          setState(() {
            _topics = topics;
            _isLoading = false;
            // Refresh complete
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Refresh complete
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading topics: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  Future<void> _refreshTopics() async {
    _loadTopics();
  }

  List<ForumTopic> get _filteredTopics {
    if (_searchQuery.isEmpty) {
      return _topics;
    }

    return _topics.where((topic) {
      final query = _searchQuery.toLowerCase();
      return topic.title.toLowerCase().contains(query) ||
          topic.authorName.toLowerCase().contains(query) ||
          topic.content.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;

    // Debounce search to avoid excessive API calls
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body:
          ResponsiveSize.isDesktop(context)
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth =
        screenWidth < 1200 ? 280.0 : 320.0; // Responsive sidebar width

    return Row(
      children: [
        // Sidebar with categories
        Container(
          width: sidebarWidth, // Responsive width for better experience
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.comments,
                        color: AppConstants.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'forum'.tr(context),
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.darkColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_topics.length} topics',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar in sidebar
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSearchBar(),
              ),
              // Categories
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Text(
                      'Categories',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._categories.map(
                      (category) => _buildCategoryItem(category),
                    ),
                    const SizedBox(height: 20),
                    // New Topic button in sidebar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (!isLoggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please log in to create a new topic',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          print(
                            'New Topic button clicked (desktop) - navigating to /forum/create',
                          );
                          print('Current user: ${currentUser?.email}');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => const ForumCreateTopicScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(
                          'Create New Topic',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Column(
            children: [
              // Top bar with stats and actions
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategory == 'all'
                                ? 'All Topics'
                                : _categories.firstWhere(
                                  (cat) => cat['id'] == _selectedCategory,
                                  orElse: () => _categories.first,
                                )['name'],
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.darkColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_filteredTopics.length} topics found',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sort and filter options
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Latest',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filter',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Topics list
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: _buildDesktopTopicsList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.comments,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'forum'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkColor,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (!isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to create a new topic'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  print(
                    'New Topic button clicked - navigating to /forum/create',
                  );
                  print('Current user: ${currentUser?.email}');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForumCreateTopicScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                tooltip: 'New Topic',
              ),
            ],
          ),
        ),
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: _buildSearchBar(),
        ),
        // Categories horizontal scroll
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildMobileCategoryItem(category),
              );
            },
          ),
        ),
        // Topics list
        Expanded(child: _buildTopicsList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search topics...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['id'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category['id'];
            });
            _loadTopics();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppConstants.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? AppConstants.primaryColor : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                FaIcon(
                  category['icon'],
                  color:
                      isSelected
                          ? AppConstants.primaryColor
                          : category['color'],
                  size: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category['name'],
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color:
                          isSelected
                              ? AppConstants.primaryColor
                              : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCategoryItem(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category['id'];
          });
          _loadTopics();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                category['icon'],
                color: isSelected ? Colors.white : category['color'],
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                category['name'],
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String _formatCreatedDate(DateTime createdDate) {
    final now = DateTime.now();
    final difference = now.difference(createdDate);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  Widget _buildTopicsList() {
    if (_isLoading) {
      return const PerformanceLoadingWidget(
        message: 'Loading forum topics...',
        size: 50,
      );
    }

    if (_filteredTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No topics found',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or category filter',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTopics,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTopics.length,
        itemBuilder: (context, index) {
          final topic = _filteredTopics[index];
          return _buildTopicItem(topic);
        },
      ),
    );
  }

  Widget _buildDesktopTopicsList() {
    if (_isLoading) {
      return const Center(
        child: PerformanceLoadingWidget(
          message: 'Loading forum topics...',
          size: 60,
        ),
      );
    }

    if (_filteredTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No topics found',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Be the first to start a discussion!',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  if (!isLoggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please log in to create a new topic'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForumCreateTopicScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create First Topic'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredTopics.length,
      itemBuilder: (context, index) {
        final topic = _filteredTopics[index];
        return _buildDesktopTopicItem(topic);
      },
    );
  }

  Widget _buildTopicItem(ForumTopic topic) {
    final category = _categories.firstWhere(
      (cat) => cat['id'] == topic.category,
      orElse: () => _categories.first,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: EdgeInsets.only(
        bottom: isSmallScreen ? 8 : 12,
      ), // Responsive margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ForumTopicDetailScreen(topicId: topic.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(
              isSmallScreen ? 12 : 16,
            ), // Responsive padding
            child: Row(
              children: [
                // Category icon
                Container(
                  width: isSmallScreen ? 36 : 40, // Responsive icon size
                  height: isSmallScreen ? 36 : 40, // Responsive icon size
                  decoration: BoxDecoration(
                    color: category['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FaIcon(
                      category['icon'],
                      color: category['color'],
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Topic content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (topic.isPinned)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'PINNED',
                                style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              topic.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Content excerpt with border
                      if (topic.content.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(
                            isSmallScreen ? 8 : 12,
                          ), // Responsive padding
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            // Shorter content for small screens
                            topic.content.length > (isSmallScreen ? 80 : 120)
                                ? '${topic.content.substring(0, isSmallScreen ? 80 : 120)}...'
                                : topic.content,
                            style: GoogleFonts.montserrat(
                              fontSize:
                                  isSmallScreen
                                      ? 12
                                      : 13, // Smaller font on small screens
                              color: Colors.grey[700],
                              height:
                                  1.3, // Reduced line height for compactness
                            ),
                            textAlign: TextAlign.left,
                            maxLines:
                                isSmallScreen
                                    ? 2
                                    : 3, // Limit lines on small screens
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(
                        height: 16,
                      ), // Increased spacing after excerpt box
                      // Tags
                      if (topic.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children:
                              topic.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppConstants.primaryColor
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      if (topic.tags.isNotEmpty) const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'By ${topic.authorName}',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8), // Reduced spacing
                          Icon(Icons.reply, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${topic.replies}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8), // Reduced spacing
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${topic.views}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Created and last activity dates
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Created date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Created',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          _formatCreatedDate(topic.createdAt),
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Last activity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Updated',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          _formatLastActivity(topic.lastActivity),
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (topic.isLocked)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LOCKED',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTopicItem(ForumTopic topic) {
    final category = _categories.firstWhere(
      (cat) => cat['id'] == topic.category,
      orElse: () => _categories.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ForumTopicDetailScreen(topicId: topic.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: category['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(
                      category['icon'],
                      color: category['color'],
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Topic content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (topic.isPinned)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PINNED',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              topic.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.darkColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Content excerpt with border
                      if (topic.content.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            topic.content.length > 150
                                ? '${topic.content.substring(0, 150)}...'
                                : topic.content,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 3, // Limit lines for desktop too
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(
                        height: 20,
                      ), // Increased spacing after excerpt box for desktop
                      // Tags
                      if (topic.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children:
                              topic.tags.map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppConstants.primaryColor
                                          .withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      if (topic.tags.isNotEmpty) const SizedBox(height: 12),
                      // Meta information
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppConstants.primaryColor
                                .withOpacity(0.2),
                            child: Text(
                              topic.authorName.isNotEmpty
                                  ? topic.authorName[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            topic.authorName,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Icon(Icons.reply, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            '${topic.replies}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${topic.views}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Created and last activity dates
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Created date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Created',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          _formatCreatedDate(topic.createdAt),
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Last activity
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Last activity',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          _formatLastActivity(topic.lastActivity),
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (topic.isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LOCKED',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: category['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category['name'],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: category['color'],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
