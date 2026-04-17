import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/models/forum_topic.dart';
import 'package:wonwonw2/models/forum_reply.dart';
import 'package:wonwonw2/services/forum_service.dart';
import 'package:wonwonw2/services/content_management_service.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/forum_screen.dart';
import 'package:wonwonw2/services/analytics_service.dart';

class ForumTopicDetailScreen extends StatefulWidget {
  final String topicId;

  const ForumTopicDetailScreen({Key? key, required this.topicId})
    : super(key: key);

  @override
  State<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen>
    with TickerProviderStateMixin {
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _nestedReplyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmittingReply = false;
  String? _replyingToId;
  bool _showNestedReply = false;
  bool _isSubmittingNestedReply = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final ContentManagementService _contentService = ContentManagementService();
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  ForumTopic? _topic;
  bool _isLoadingTopic = true;
  String? _topicError;
  int _replyCharCount = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    _loadTopic();

    // Check admin status
    _checkAdminStatus();

    // Increment view count when topic is opened
    ForumService.incrementTopicViews(widget.topicId);
  }

  Future<void> _loadTopic() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTopic = true;
      _topicError = null;
    });
    try {
      final topic = await ForumService.getTopic(widget.topicId);
      if (!mounted) return;
      setState(() {
        _topic = topic;
        _isLoadingTopic = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _topicError = e.toString();
        _isLoadingTopic = false;
      });
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _nestedReplyController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'forum'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        iconTheme: const IconThemeData(color: AppConstants.darkColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              onPressed: () {
                // Get the current topic to show moderator dialog
                ForumService.getTopic(widget.topicId).then((topic) {
                  if (!mounted) return;
                  if (topic != null) {
                    _showModeratorDialog(topic);
                  }
                });
              },
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'moderate_topic_tooltip'.tr(context),
            ),
          if (_topic != null && _topic!.authorId == FirebaseAuth.instance.currentUser?.uid)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteTopicDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'delete_topic'.tr(context),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Expanded(
                  child: _buildTopicBody(),
                ),
                if (_topic != null && !_topic!.isLocked)
                  _buildReplyInput()
                else if (_topic != null && _topic!.isLocked)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'topic_locked_no_replies'.tr(context),
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
        ),
      ),
    );
  }

  Widget _buildTopicBody() {
    if (_isLoadingTopic) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'loading'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_topicError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'error_loading_topic'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'please_try_again'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTopic,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('retry'.tr(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final topic = _topic;
    if (topic == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'topic_not_found'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return _buildRepliesSection(topic);
  }

  Widget _buildTopicContent(ForumTopic topic) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic header with badges
          Row(
            children: [
              if (topic.isPinned)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.push_pin, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'forum_pinned'.tr(context).toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              if (topic.isLocked)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.redAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'forum_locked'.tr(context).toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Text(
                  topic.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Topic metadata with enhanced design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryColor,
                        AppConstants.primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      topic.authorName.isNotEmpty
                          ? topic.authorName[0].toUpperCase()
                          : 'A',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.authorName,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • HH:mm',
                            ).format(topic.createdAt),
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Topic stats with modern design
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatItem(
                        Icons.reply,
                        '${topic.replies}',
                        'forum_replies_label'.tr(context),
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.visibility,
                        '${topic.views}',
                        'forum_views_label'.tr(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Topic content with better typography
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Text(
              topic.content,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                height: 1.7,
                color: Colors.grey[800],
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (topic.tags.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  topic.tags
                      .map(
                        (tag) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ForumScreen(initialSearchTag: tag),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppConstants.primaryColor.withValues(alpha: 0.1),
                                    AppConstants.primaryColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tag,
                                    size: 14,
                                    color: AppConstants.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tag,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: AppConstants.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.grey[500],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepliesSection(ForumTopic topic) {
    return StreamBuilder<List<ForumReply>>(
      stream: ForumService.getReplies(widget.topicId),
      builder: (context, snapshot) {
        final replies = snapshot.data ?? [];
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;

        return RefreshIndicator(
          onRefresh: () async {
            await _loadTopic();
          },
          color: AppConstants.primaryColor,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _slideController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: _buildTopicContent(topic),
              ),
              const SizedBox(height: 16),
              if (isWaiting)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppConstants.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'loading_replies'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 30,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'error_loading_replies'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'please_try_again'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadTopic,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text('retry'.tr(context)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (replies.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_replies_yet'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'be_first_to_reply'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'forum_reply_count'.tr(context).replaceAll('{count}', '${replies.length}'),
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.sort, size: 18, color: Colors.grey[500]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...replies.map((reply) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildReplyItem(reply, topic),
                )),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'forum_just_now'.tr(context);
    if (diff.inMinutes < 60) return 'time_minutes_ago'.tr(context).replaceAll('{count}', '${diff.inMinutes}');
    if (diff.inHours < 24) return 'time_hours_ago'.tr(context).replaceAll('{count}', '${diff.inHours}');
    if (diff.inDays < 7) return 'time_short_days_ago'.tr(context).replaceAll('{count}', '${diff.inDays}');
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  Widget _buildReplyItem(ForumReply reply, ForumTopic topic) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthor = currentUser?.uid == reply.authorId;
    final isTopicAuthor = currentUser?.uid == topic.authorId;
    final isOP = reply.authorId == topic.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              reply.isSolution
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
          width: reply.isSolution ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Reply header with modern design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  reply.isSolution
                      ? Colors.green.withValues(alpha: 0.05)
                      : Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          reply.isSolution
                              ? [Colors.green, Colors.greenAccent]
                              : [
                                AppConstants.primaryColor,
                                AppConstants.primaryColor.withValues(alpha: 0.8),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (reply.isSolution
                                ? Colors.green
                                : AppConstants.primaryColor)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      reply.authorName.isNotEmpty
                          ? reply.authorName[0].toUpperCase()
                          : 'A',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              reply.authorName,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOP) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'OP',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.primaryColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          if (reply.isSolution) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.green, Colors.greenAccent],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'forum_solution'.tr(context).toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRelativeTime(reply.createdAt),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Reply actions with modern buttons
                Row(
                  children: [
                    // Like button
                    Builder(
                      builder: (context) {
                        final isLiked = currentUser != null &&
                            reply.likedBy.contains(currentUser.uid);
                        return Container(
                          decoration: BoxDecoration(
                            color:
                                isLiked
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () => _toggleReplyLike(reply.id),
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isLiked ? Colors.red : Colors.grey[600],
                            ),
                            tooltip: 'like_tooltip'.tr(context),
                          ),
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${reply.likes}',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Reply button
                    if (!topic.isLocked)
                      Container(
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => _showNestedReplyInput(reply.id),
                          icon: Icon(
                            Icons.reply,
                            size: 18,
                            color: AppConstants.primaryColor,
                          ),
                          tooltip: 'reply_tooltip'.tr(context),
                        ),
                      ),
                    if (isTopicAuthor || isAuthor || _isAdmin) ...[
                      const SizedBox(width: 8),
                      // More options
                      PopupMenuButton<String>(
                        onSelected:
                            (value) => _handleReplyAction(value, reply, topic),
                        itemBuilder:
                            (context) => [
                              if (isTopicAuthor && !reply.isSolution)
                                PopupMenuItem(
                                  value: 'mark_solution',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text('mark_as_solution'.tr(context)),
                                    ],
                                  ),
                                ),
                              if (isTopicAuthor && reply.isSolution)
                                PopupMenuItem(
                                  value: 'unmark_solution',
                                  child: Row(
                                    children: [
                                      Icon(Icons.cancel, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('unmark_as_solution'.tr(context)),
                                    ],
                                  ),
                                ),
                              if (isAuthor)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('delete_action'.tr(context)),
                                    ],
                                  ),
                                ),
                              if (_isAdmin)
                                PopupMenuItem(
                                  value: 'moderate',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Text('moderate_action'.tr(context)),
                                    ],
                                  ),
                                ),
                            ],
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Reply content
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                reply.content,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.grey[800],
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          // Nested replies
          if (_showNestedReply && _replyingToId == reply.id)
            _buildNestedReplyInput(reply.id),
          // Show nested replies
          StreamBuilder<List<ForumReply>>(
            stream: ForumService.getNestedReplies(widget.topicId, reply.id),
            builder: (context, nestedSnapshot) {
              final nestedReplies = nestedSnapshot.data ?? [];
              if (nestedReplies.isEmpty) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children:
                      nestedReplies
                          .map(
                            (nestedReply) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppConstants
                                            .primaryColor
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          nestedReply.authorName.isNotEmpty
                                              ? nestedReply.authorName[0]
                                                  .toUpperCase()
                                              : 'A',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppConstants.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nestedReply.authorName,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'MMM dd, yyyy • HH:mm',
                                              ).format(nestedReply.createdAt),
                                              style: GoogleFonts.montserrat(
                                                fontSize: 11,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (nestedReply.authorId ==
                                          currentUser?.uid)
                                        IconButton(
                                          onPressed:
                                              () => _deleteReply(
                                                nestedReply.id,
                                                nestedReply.authorId,
                                              ),
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          tooltip: 'delete_tooltip'.tr(context),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        nestedReply.content,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: Colors.grey[800],
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _replyCharCount > 0
                    ? AppConstants.primaryColor.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _replyController,
                  onChanged: (text) {
                    setState(() {
                      _replyCharCount = text.trim().length;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'write_reply_hint'.tr(context),
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  maxLength: 5000,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  textInputAction: TextInputAction.newline,
                  style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  child: Row(
                    children: [
                      if (_replyCharCount > 0)
                        Text(
                          '$_replyCharCount / 5000',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: _replyCharCount > 4500 ? Colors.orange : Colors.grey[400],
                          ),
                        ),
                      const Spacer(),
                      Material(
                        color: _replyCharCount > 0
                            ? AppConstants.primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _isSubmittingReply || _replyCharCount == 0
                              ? null
                              : _submitReply,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: _isSubmittingReply
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: _replyCharCount > 0 ? Colors.white : Colors.grey[500],
                                  ),
                          ),
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
  }

  Widget _buildNestedReplyInput(String parentReplyId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nestedReplyController,
              decoration: InputDecoration(
                hintText: 'write_reply_short'.tr(context),
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppConstants.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitNestedReply(parentReplyId),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () => _submitNestedReply(parentReplyId),
              icon: const Icon(Icons.send, size: 18, color: Colors.white),
              tooltip: 'send'.tr(context),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _showNestedReply = false;
                  _replyingToId = null;
                  _nestedReplyController.clear();
                });
              },
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              tooltip: 'cancel'.tr(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showNestedReplyInput(String replyId) {
    setState(() {
      _showNestedReply = true;
      _replyingToId = replyId;
      _nestedReplyController.clear();
    });
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      if (result != true || !mounted) return;
      // Re-check after login
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmittingReply = true;
    });

    try {
      await ForumService.createReply(
        topicId: widget.topicId,
        content: _replyController.text.trim(),
      );
      AnalyticsService.safeLog(() => AnalyticsService().logReplyToTopic(widget.topicId));
      if (!mounted) return;
      _replyController.clear();
      setState(() { _replyCharCount = 0; });
      _loadTopic();
      // Auto-scroll to the bottom to show the new reply
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'reply_posted'.tr(context),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'error_posting_reply'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReply = false;
        });
      }
    }
  }

  Future<void> _submitNestedReply(String parentReplyId) async {
    if (_nestedReplyController.text.trim().isEmpty) return;
    if (_isSubmittingNestedReply) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      if (result != true || !mounted) return;
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    setState(() => _isSubmittingNestedReply = true);
    try {
      await ForumService.createReply(
        topicId: widget.topicId,
        content: _nestedReplyController.text.trim(),
        parentReplyId: parentReplyId,
      );
      if (!mounted) return;
      _nestedReplyController.clear();
      setState(() {
        _showNestedReply = false;
        _replyingToId = null;
        _isSubmittingNestedReply = false;
      });
      _loadTopic();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'reply_posted'.tr(context),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingNestedReply = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'error_posting_reply'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _showDeleteTopicDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'delete_topic'.tr(context),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          'delete_topic_confirm'.tr(context),
          style: GoogleFonts.montserrat(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'delete'.tr(context),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ForumService.deleteTopic(widget.topicId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('topic_deleted'.tr(context)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_deleting_topic'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleReplyLike(String replyId) async {
    try {
      await ForumService.toggleReplyLike(widget.topicId, replyId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'error_generic'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }


  void _handleReplyAction(
    String action,
    ForumReply reply,
    ForumTopic topic,
  ) async {
    switch (action) {
      case 'mark_solution':
        await _markReplyAsSolution(reply.id, true);
        break;
      case 'unmark_solution':
        await _markReplyAsSolution(reply.id, false);
        break;
      case 'delete':
        await _deleteReply(reply.id, reply.authorId);
        break;
      case 'moderate':
        _showReplyModeratorDialog(reply);
        break;
    }
  }

  Future<void> _markReplyAsSolution(String replyId, bool isSolution) async {
    try {
      await ForumService.markReplyAsSolution(
        widget.topicId,
        replyId,
        isSolution,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSolution ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                isSolution
                    ? 'marked_as_solution'.tr(context)
                    : 'unmarked_as_solution'.tr(context),
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'error_generic'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _deleteReply(String replyId, String replyAuthorId) async {
    final canDelete = await _contentService.canDeleteContent(replyAuthorId);
    if (!mounted) return;
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'no_permission_delete'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'delete_reply_title'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'delete_reply_confirm'.tr(context),
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'cancel'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'delete_button'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ForumService.deleteReply(widget.topicId, replyId);
        if (!mounted) return;
        _loadTopic();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'reply_deleted'.tr(context),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'error_generic'.tr(context),
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // ==================== MODERATOR METHODS ====================

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _authService.isAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
      appLog('Error checking admin status: $e');
    }
  }

  void _showModeratorDialog(ForumTopic topic) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'moderate_topic'.tr(context),
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  topic.title,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                _buildModeratorButtons(topic),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
            ],
          ),
    );
  }

  Widget _buildModeratorButtons(ForumTopic topic) {
    return Column(
      children: [
        if (topic.isPinned)
          _buildModeratorButton(
            'mod_unpin_topic'.tr(context),
            Icons.push_pin_outlined,
            Colors.orange,
            () => _moderateTopic(topic.id, 'unpin'),
          )
        else
          _buildModeratorButton(
            'mod_pin_topic'.tr(context),
            Icons.push_pin,
            Colors.orange,
            () => _moderateTopic(topic.id, 'pin'),
          ),
        if (topic.isLocked)
          _buildModeratorButton(
            'mod_unlock_topic'.tr(context),
            Icons.lock_open,
            Colors.green,
            () => _moderateTopic(topic.id, 'unlock'),
          )
        else
          _buildModeratorButton(
            'mod_lock_topic'.tr(context),
            Icons.lock,
            Colors.red,
            () => _moderateTopic(topic.id, 'lock'),
          ),
        if (topic.isHidden)
          _buildModeratorButton(
            'mod_unhide_topic'.tr(context),
            Icons.visibility,
            Colors.green,
            () => _moderateTopic(topic.id, 'unhide'),
          )
        else
          _buildModeratorButton(
            'mod_hide_topic'.tr(context),
            Icons.visibility_off,
            Colors.orange,
            () => _moderateTopic(topic.id, 'hide'),
          ),
        _buildModeratorButton(
          'mod_delete_topic'.tr(context),
          Icons.delete_forever,
          Colors.red,
          () => _moderateTopic(topic.id, 'delete'),
        ),
      ],
    );
  }

  Widget _buildModeratorButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _moderateTopic(String topicId, String action) async {
    Navigator.pop(context);

    String? reason;
    if (action == 'hide' || action == 'lock' || action == 'delete') {
      reason = await _showReasonDialog(action);
      if (reason == null || !mounted) return;
    }

    try {
      bool success = false;
      switch (action) {
        case 'pin':
          success = await ForumService.pinTopic(topicId);
          break;
        case 'unpin':
          success = await ForumService.unpinTopic(topicId);
          break;
        case 'lock':
          success = await ForumService.lockTopic(topicId, reason!);
          break;
        case 'unlock':
          success = await ForumService.unlockTopic(topicId);
          break;
        case 'hide':
          success = await ForumService.hideTopic(topicId, reason!);
          break;
        case 'unhide':
          success = await ForumService.unhideTopic(topicId);
          break;
        case 'delete':
          success = await ForumService.adminDeleteTopic(topicId, reason!);
          break;
      }

      if (!mounted) return;

      if (success) {
        if (action == 'delete') {
          Navigator.of(context).pop();
        } else {
          _loadTopic();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('topic_action_success'.tr(context).replaceAll('{action}', action)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to $action topic');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr(context)), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _showReasonDialog(String action) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('reason_for_action'.tr(context).replaceAll('{action}', action)),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'enter_reason_hint'.tr(context).replaceAll('{action}', action),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('confirm_button'.tr(context)),
              ),
            ],
          ),
    );
    controller.dispose();
    return result;
  }

  void _showReplyModeratorDialog(ForumReply reply) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('moderate_reply_dialog'.tr(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('reply_by'.tr(context).replaceAll('{name}', reply.authorName)),
                const SizedBox(height: 16),
                _buildReplyModeratorButtons(reply),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
            ],
          ),
    );
  }

  Widget _buildReplyModeratorButtons(ForumReply reply) {
    return Column(
      children: [
        if (reply.isHidden)
          _buildModeratorButton(
            'mod_unhide_reply'.tr(context),
            Icons.visibility,
            Colors.green,
            () => _moderateReply(reply, 'unhide'),
          )
        else
          _buildModeratorButton(
            'mod_hide_reply'.tr(context),
            Icons.visibility_off,
            Colors.orange,
            () => _moderateReply(reply, 'hide'),
          ),
        _buildModeratorButton(
          'mod_delete_reply'.tr(context),
          Icons.delete_forever,
          Colors.red,
          () => _moderateReply(reply, 'delete'),
        ),
      ],
    );
  }

  Future<void> _moderateReply(ForumReply reply, String action) async {
    Navigator.pop(context);

    String? reason;
    if (action == 'hide' || action == 'delete') {
      reason = await _showReasonDialog(action);
      if (reason == null || !mounted) return;
    }

    try {
      bool success = false;
      switch (action) {
        case 'hide':
          success = await ForumService.hideReply(
            widget.topicId,
            reply.id,
            reason!,
          );
          break;
        case 'unhide':
          success = await ForumService.unhideReply(widget.topicId, reply.id);
          break;
        case 'delete':
          success = await ForumService.adminDeleteReply(
            widget.topicId,
            reply.id,
            reason!,
          );
          break;
      }

      if (!mounted) return;

      if (success) {
        _loadTopic();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('reply_action_success'.tr(context).replaceAll('{action}', action)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to $action reply');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error_generic'.tr(context)), backgroundColor: Colors.red),
      );
    }
  }
}
