import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:shared/models/forum_topic.dart';
import 'package:wonwon_client/screens/forum_create_topic_screen.dart';
import 'package:wonwon_client/screens/forum_topic_detail_screen.dart';
import 'package:shared/services/forum_service.dart';
import 'package:shared/utils/responsive_size.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/widgets/performance_loading_widget.dart';
import 'package:shared/mixins/auth_state_mixin.dart';
import 'package:wonwon_client/screens/login_screen.dart';
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
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'all',
      'nameKey': 'forum_all_topics',
      'icon': FontAwesomeIcons.globe,
      'color': const Color(0xFF6366F1),
    },
    {
      'id': 'general',
      'nameKey': 'forum_general_discussion',
      'icon': FontAwesomeIcons.comments,
      'color': const Color(0xFF22C55E),
    },
    {
      'id': 'repair_tips',
      'nameKey': 'forum_repair_tips',
      'icon': FontAwesomeIcons.wrench,
      'color': const Color(0xFFF59E0B),
    },
    {
      'id': 'shop_reviews',
      'nameKey': 'forum_shop_reviews',
      'icon': FontAwesomeIcons.star,
      'color': const Color(0xFFA855F7),
    },
    {
      'id': 'questions',
      'nameKey': 'forum_questions_help',
      'icon': FontAwesomeIcons.questionCircle,
      'color': const Color(0xFFEF4444),
    },
    {
      'id': 'announcements',
      'nameKey': 'forum_announcements',
      'icon': FontAwesomeIcons.bullhorn,
      'color': const Color(0xFF14B8A6),
    },
  ];

  List<ForumTopic> _topics = [];
  bool _isLoading = true;
  String? _loadError;
  Stream<List<ForumTopic>>? _topicsStream;
  StreamSubscription<List<ForumTopic>>? _topicsSubscription;
  Timer? _searchDebounceTimer;
  int _topicLimit = 20;
  bool _hasMoreTopics = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchTag != null && widget.initialSearchTag!.isNotEmpty) {
      _searchQuery = widget.initialSearchTag!;
      _searchController.text = widget.initialSearchTag!;
      _isSearchVisible = true;
    }
    _loadTopics();
  }

  @override
  void dispose() {
    _topicsSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
      _loadError = null;
    });

    _topicsStream = ForumService.getTopics(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      limit: _topicLimit,
    );

    _topicsSubscription?.cancel();
    _topicsSubscription = _topicsStream!.listen(
      (topics) {
        if (mounted) {
          setState(() {
            _topics = topics;
            _hasMoreTopics = topics.length >= _topicLimit;
            _isLoading = false;
            _loadError = null;
            _updateFilteredTopics();
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadError = error.toString();
          });
        }
      },
    );
  }

  Future<void> _refreshTopics() async {
    _topicLimit = 20;
    _loadTopics();
  }

  void _loadMoreTopics() {
    setState(() {
      _topicLimit += 20;
    });
    _loadTopics();
  }

  List<ForumTopic> _cachedFilteredTopics = [];

  List<ForumTopic> get _filteredTopics => _cachedFilteredTopics;

  void _updateFilteredTopics() {
    if (_searchQuery.isEmpty) {
      _cachedFilteredTopics = _topics;
    } else {
      final query = _searchQuery.toLowerCase();
      _cachedFilteredTopics = _topics.where((topic) {
        return topic.title.toLowerCase().contains(query) ||
            topic.authorName.toLowerCase().contains(query) ||
            topic.content.toLowerCase().contains(query) ||
            topic.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _updateFilteredTopics();
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _loadTopics();
    });
  }

  void _searchByTag(String tag) {
    _searchController.text = tag;
    _searchQuery = tag;
    _selectedCategory = 'all';
    _isSearchVisible = true;
    _loadTopics();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'forum_just_now'.tr(context);
    if (diff.inMinutes < 60) return 'time_minutes_ago'.tr(context).replaceAll('{count}', '${diff.inMinutes}');
    if (diff.inHours < 24) return 'time_hours_ago'.tr(context).replaceAll('{count}', '${diff.inHours}');
    if (diff.inDays < 7) return 'time_short_days_ago'.tr(context).replaceAll('{count}', '${diff.inDays}');
    return 'time_short_weeks_ago'.tr(context).replaceAll('{count}', '${(diff.inDays / 7).floor()}');
  }

  Map<String, dynamic> _getCategoryForTopic(ForumTopic topic) {
    return _categories.firstWhere(
      (cat) => cat['id'] == topic.category,
      orElse: () => _categories.isNotEmpty
          ? _categories.first
          : {
              'id': 'all',
              'nameKey': 'forum_all_topics',
              'icon': FontAwesomeIcons.globe,
              'color': const Color(0xFF6366F1),
            },
    );
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
              elevation: 3,
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'forum'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppConstants.darkColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                  if (_searchQuery.isNotEmpty) {
                    _searchQuery = '';
                    _loadTopics();
                  }
                } else {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) _searchFocusNode.requestFocus();
                  });
                }
              });
            },
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: Colors.grey[700],
              size: 22,
            ),
            tooltip: 'forum_search_topics'.tr(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _isSearchVisible
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: GoogleFonts.montserrat(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'forum_search_topics'.tr(context),
                  hintStyle: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY TABS
  // ---------------------------------------------------------------------------

  Widget _buildCategoryTabs() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() => _selectedCategory = cat['id']);
                _loadTopics();
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryColor : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  (cat['nameKey'] as String).tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchField(),
        _buildCategoryTabs(),
        Expanded(child: _buildTopicsList()),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = ResponsiveBreakpoints.isDesktop(screenWidth) ? 280.0 : 260.0;

    return Row(
      children: [
        // Sidebar
        Container(
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Text(
                  'forum'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkColor,
                  ),
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: GoogleFonts.montserrat(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'forum_search_topics'.tr(context),
                    hintStyle: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 16, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'forum_categories'.tr(context).toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Category list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() => _selectedCategory = cat['id']);
                            _loadTopics();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                FaIcon(
                                  cat['icon'],
                                  size: 14,
                                  color: isSelected ? AppConstants.primaryColor : cat['color'],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    (cat['nameKey'] as String).tr(context),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? AppConstants.primaryColor : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // New topic button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToCreateTopic,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'forum_create_new_topic'.tr(context),
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedCategory == 'all'
                          ? 'forum_all_topics'.tr(context)
                          : (_categories.firstWhere(
                              (cat) => cat['id'] == _selectedCategory,
                              orElse: () => _categories.isNotEmpty
                                  ? _categories.first
                                  : {
                                      'id': 'all',
                                      'nameKey': 'forum_all_topics',
                                      'icon': FontAwesomeIcons.globe,
                                      'color': const Color(0xFF6366F1),
                                    },
                            )['nameKey'] as String)
                              .tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.darkColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_filteredTopics.length}',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFC),
                  child: _buildTopicsList(isDesktop: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TOPICS LIST
  // ---------------------------------------------------------------------------

  Widget _buildTopicsList({bool isDesktop = false}) {
    if (_isLoading) {
      return PerformanceLoadingWidget(
        message: 'forum_loading_topics'.tr(context),
        size: 50,
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'error_loading_topics'.tr(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadTopics,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('retry'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredTopics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'forum_no_topics'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'forum_try_adjusting_search'.tr(context)
                  : 'forum_be_first'.tr(context),
              style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[400]),
            ),
            if (_searchQuery.isEmpty && isDesktop) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToCreateTopic,
                icon: const Icon(Icons.add, size: 18),
                label: Text('forum_create_first'.tr(context)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final itemCount = _filteredTopics.length + (_hasMoreTopics ? 1 : 0);
    return RefreshIndicator(
      onRefresh: _refreshTopics,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        key: PageStorageKey<String>(isDesktop ? 'forum_desktop_list' : 'forum_mobile_list'),
        padding: EdgeInsets.all(isDesktop ? 20 : 12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= _filteredTopics.length) {
            // "Load More" button
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: TextButton.icon(
                  onPressed: _loadMoreTopics,
                  icon: const Icon(Icons.expand_more, size: 20),
                  label: Text('forum_load_more'.tr(context)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
            );
          }
          return RepaintBoundary(
            child: _buildTopicCard(_filteredTopics[index], isDesktop: isDesktop),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOPIC CARD
  // ---------------------------------------------------------------------------

  Widget _buildTopicCard(ForumTopic topic, {bool isDesktop = false}) {
    final category = _getCategoryForTopic(topic);
    final catColor = category['color'] as Color;

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ForumTopicDetailScreen(topicId: topic.id),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pinned / locked badges + title
                if (topic.isPinned || topic.isLocked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (topic.isPinned)
                          _buildBadge('forum_pinned'.tr(context), Colors.orange, Icons.push_pin),
                        if (topic.isPinned && topic.isLocked) const SizedBox(width: 6),
                        if (topic.isLocked)
                          _buildBadge('forum_locked'.tr(context), Colors.red, Icons.lock),
                      ],
                    ),
                  ),
                Text(
                  topic.title,
                  style: GoogleFonts.montserrat(
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.darkColor,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Author, time, replies, views
                Row(
                  children: [
                    // Author avatar
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.12),
                      child: Text(
                        topic.authorName.isNotEmpty
                            ? topic.authorName[0].toUpperCase()
                            : 'A',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        topic.authorName,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _dot(),
                    Text(
                      _formatTimeAgo(topic.lastActivity),
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500]),
                    ),
                    _dot(),
                    Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      '${topic.replies}',
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                    _dot(),
                    Icon(Icons.visibility_outlined, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(
                      '${topic.views}',
                      style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Tags row + category chip
                Row(
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (category['nameKey'] as String).tr(context),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: catColor,
                        ),
                      ),
                    ),
                    if (topic.tags.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: topic.tags.map((tag) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _searchByTag(tag),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
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
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '\u00B7',
        style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
