import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/responsive_breakpoints.dart';
import 'package:wonwonw2/models/forum_topic.dart';
import 'package:wonwonw2/screens/forum_create_topic_screen.dart';
import 'package:wonwonw2/screens/forum_topic_detail_screen.dart';
import 'package:wonwonw2/services/forum_service.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/performance_loading_widget.dart';
import 'package:wonwonw2/mixins/auth_state_mixin.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'dart:async';

class ForumScreen extends StatefulWidget {
  final String? initialSearchTag;

  const ForumScreen({Key? key, this.initialSearchTag}) : super(key: key);

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> with AuthStateMixin {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'nameKey': 'forum_all_topics',
      'icon': FontAwesomeIcons.globe,
      'color': Colors.blue,
    },
    {
      'id': 'general',
      'nameKey': 'forum_general_discussion',
      'icon': FontAwesomeIcons.comments,
      'color': Colors.green,
    },
    {
      'id': 'repair_tips',
      'nameKey': 'forum_repair_tips',
      'icon': FontAwesomeIcons.wrench,
      'color': Colors.orange,
    },
    {
      'id': 'shop_reviews',
      'nameKey': 'forum_shop_reviews',
      'icon': FontAwesomeIcons.star,
      'color': Colors.purple,
    },
    {
      'id': 'questions',
      'nameKey': 'forum_questions_help',
      'icon': FontAwesomeIcons.questionCircle,
      'color': Colors.red,
    },
    {
      'id': 'announcements',
      'nameKey': 'forum_announcements',
      'icon': FontAwesomeIcons.bullhorn,
      'color': Colors.teal,
    },
  ];

  List<ForumTopic> _topics = [];
  bool _isLoading = true;
  // Removed unused _isRefreshing field
  Stream<List<ForumTopic>>? _topicsStream;
  StreamSubscription<List<ForumTopic>>? _topicsSubscription;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchTag != null && widget.initialSearchTag!.isNotEmpty) {
      _searchQuery = widget.initialSearchTag!;
      _searchController.text = widget.initialSearchTag!;
    }
    _loadTopics();
  }

  @override
  void dispose() {
    _topicsSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToCreateTopic() {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('forum_login_to_create'.tr(context)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'login'.tr(context),
            textColor: Colors.white,
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              if (result == true && mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ForumCreateTopicScreen(),
                  ),
                );
              }
            },
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForumCreateTopicScreen(),
      ),
    );
  }

  void _loadTopics() {
    setState(() {
      _isLoading = true;
    });

    _topicsStream = ForumService.getTopics(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
    );

    _topicsSubscription?.cancel();
    _topicsSubscription = _topicsStream!.listen(
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
          });
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_loading_topics'.tr(context).replaceAll('{error}', error.toString())),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
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
          topic.content.toLowerCase().contains(query) ||
          topic.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadTopics();
    });
  }

  void _searchByTag(String tag) {
    _searchController.text = tag;
    _searchQuery = tag;
    _selectedCategory = 'all';
    _loadTopics();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSize.isTablet(context);
    final isDesktop = ResponsiveSize.isDesktop(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isDesktop
              ? _buildDesktopLayout()
              : isTablet
                  ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 768),
                      child: _buildMobileLayout(),
                    ),
                  )
                  : _buildMobileLayout(),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              heroTag: 'forum_create_topic',
              onPressed: _navigateToCreateTopic,
              backgroundColor: AppConstants.primaryColor,
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
    );
  }

  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth =
        ResponsiveBreakpoints.isDesktop(screenWidth)
            ? 320.0
            : 280.0; // Responsive sidebar width

    return Row(
      children: [
        // Sidebar with categories
        Container(
          width: sidebarWidth, // Responsive width for better experience
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                    bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
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
                            'forum_topic_count'.tr(context).replaceAll('{count}', '${_topics.length}'),
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
                      'forum_categories'.tr(context),
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
                        onPressed: _navigateToCreateTopic,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(
                          'forum_create_new_topic'.tr(context),
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
                    bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                                ? 'forum_all_topics'.tr(context)
                                : (_categories.firstWhere(
                                  (cat) => cat['id'] == _selectedCategory,
                                  orElse: () => _categories.first,
                                )['nameKey'] as String).tr(context),
                            style: GoogleFonts.montserrat(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.darkColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'forum_topics_found'.tr(context).replaceAll('{count}', '${_filteredTopics.length}'),
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
                                'forum_latest'.tr(context),
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
                                'forum_filter'.tr(context),
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
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                onPressed: _navigateToCreateTopic,
                icon: const Icon(Icons.add),
                tooltip: 'forum_new_topic'.tr(context),
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
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
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
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'forum_search_topics'.tr(context),
          hintStyle: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[500],
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        style: GoogleFonts.montserrat(fontSize: 14),
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
                      ? AppConstants.primaryColor.withValues(alpha: 0.1)
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
                    (category['nameKey'] as String).tr(context),
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
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _selectedCategory = category['id'];
        });
        _loadTopics();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              category['icon'],
              color: isSelected ? Colors.white : AppConstants.darkColor,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              (category['nameKey'] as String).tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppConstants.darkColor,
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
      return 'time_minutes_ago'.tr(context).replaceAll('{count}', '${difference.inMinutes}');
    } else if (difference.inHours < 24) {
      return 'time_hours_ago'.tr(context).replaceAll('{count}', '${difference.inHours}');
    } else if (difference.inDays < 7) {
      return 'time_short_days_ago'.tr(context).replaceAll('{count}', '${difference.inDays}');
    } else {
      return 'time_short_weeks_ago'.tr(context).replaceAll('{count}', '${(difference.inDays / 7).floor()}');
    }
  }

  Widget _buildTopicsList() {
    if (_isLoading) {
      return PerformanceLoadingWidget(
        message: 'forum_loading_topics'.tr(context),
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
              'forum_no_topics'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'forum_try_adjusting_search'.tr(context),
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
      color: AppConstants.primaryColor,
      child: ListView.builder(
        key: const PageStorageKey<String>('forum_topics_list'),
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTopics.length,
        itemBuilder: (context, index) {
          final topic = _filteredTopics[index];
          return RepaintBoundary(
            child: _buildTopicItem(topic),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTopicsList() {
    if (_isLoading) {
      return Center(
        child: PerformanceLoadingWidget(
          message: 'forum_loading_topics'.tr(context),
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
                color: Colors.grey.withValues(alpha: 0.1),
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
              'forum_no_topics'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'forum_try_adjusting_terms'.tr(context)
                  : 'forum_be_first'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _navigateToCreateTopic,
                icon: const Icon(Icons.add),
                label: Text('forum_create_first'.tr(context)),
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

    return RefreshIndicator(
      onRefresh: _refreshTopics,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        key: const PageStorageKey<String>('forum_desktop_topics_list'),
        padding: const EdgeInsets.all(24),
        itemCount: _filteredTopics.length,
        itemBuilder: (context, index) {
          final topic = _filteredTopics[index];
          return RepaintBoundary(
            child: _buildDesktopTopicItem(topic),
          );
        },
      ),
    );
  }

  Widget _buildTopicItem(ForumTopic topic) {
    final category = _categories.firstWhere(
      (cat) => cat['id'] == topic.category,
      orElse: () => _categories.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (topic.isPinned)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'forum_pinned'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (topic.isLocked)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'forum_locked'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                if (topic.isPinned || topic.isLocked) const SizedBox(height: 8),
                Text(
                  topic.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'forum_by_author'.tr(context).replaceAll('{author}', topic.authorName) +
                      '  ·  ${_formatLastActivity(topic.lastActivity)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (topic.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        topic.tags.map((tag) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _searchByTag(tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 15, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${topic.replies}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.visibility_outlined, size: 15, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      '${topic.views}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (category['nameKey'] as String).tr(context),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
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

  Widget _buildDesktopTopicItem(ForumTopic topic) {
    final category = _categories.firstWhere(
      (cat) => cat['id'] == topic.category,
      orElse: () => _categories.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (topic.isPinned)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'forum_pinned'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (topic.isLocked)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'forum_locked'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        topic.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.darkColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.15),
                      child: Text(
                        topic.authorName.isNotEmpty
                            ? topic.authorName[0].toUpperCase()
                            : 'A',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      topic.authorName,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·  ${_formatLastActivity(topic.lastActivity)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (topic.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children:
                        topic.tags.map((tag) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _searchByTag(tag),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[400]),
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
                    Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      '${topic.views}',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            category['icon'],
                            color: category['color'],
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (category['nameKey'] as String).tr(context),
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: category['color'],
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
        ),
      ),
    );
  }
}
