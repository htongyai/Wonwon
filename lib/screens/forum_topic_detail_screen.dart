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
  bool _isSubmittingReply = false;
  String? _replyingToId;
  bool _showNestedReply = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  final ContentManagementService _contentService = ContentManagementService();
  final AuthService _authService = AuthService();
  bool _isAdmin = false;

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

    // Check admin status
    _checkAdminStatus();

    // Increment view count when topic is opened
    ForumService.incrementTopicViews(widget.topicId);
  }

  @override
  void dispose() {
    _replyController.dispose();
    _nestedReplyController.dispose();
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
        shadowColor: Colors.black.withOpacity(0.1),
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
                  if (topic != null) {
                    _showModeratorDialog(topic);
                  }
                });
              },
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Moderate Topic',
            ),
          IconButton(
            onPressed: () {
              // TODO: Add share functionality
            },
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<ForumTopic?>(
                stream: Stream.fromFuture(
                  ForumService.getTopic(widget.topicId),
                ),
                builder: (context, topicSnapshot) {
                  if (topicSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(0.1),
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
                            'Loading topic...',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (topicSnapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
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
                            'Error loading topic',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final topic = topicSnapshot.data;
                  if (topic == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
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
                            'Topic not found',
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

                  return Column(
                    children: [
                      // Topic content
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
                      // Replies section
                      Expanded(child: _buildRepliesSection(topic)),
                    ],
                  );
                },
              ),
            ),
            // Reply input section
            _buildReplyInput(),
          ],
        ),
      ),
    );
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
            color: Colors.black.withOpacity(0.08),
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
                        'PINNED',
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
                        'LOCKED',
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
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                        AppConstants.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.3),
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
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      _buildStatItem(
                        Icons.reply,
                        '${topic.replies}',
                        'Replies',
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.visibility,
                        '${topic.views}',
                        'Views',
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
              color: Colors.grey[25],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppConstants.primaryColor.withOpacity(0.1),
                                AppConstants.primaryColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
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
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                color: Colors.grey[500],
              ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
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
                  'Loading replies...',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
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
                  'Error loading replies',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
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

        final replies = snapshot.data ?? [];

        if (replies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
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
                  'No replies yet',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share your thoughts!',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: replies.length,
          itemBuilder: (context, index) {
            final reply = replies[index];
            return _buildReplyItem(reply, topic);
          },
        );
      },
    );
  }

  Widget _buildReplyItem(ForumReply reply, ForumTopic topic) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthor = currentUser?.uid == reply.authorId;
    final isTopicAuthor = currentUser?.uid == topic.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              reply.isSolution
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
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
                      ? Colors.green.withOpacity(0.05)
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
                                AppConstants.primaryColor.withOpacity(0.8),
                              ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (reply.isSolution
                                ? Colors.green
                                : AppConstants.primaryColor)
                            .withOpacity(0.3),
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
                          Text(
                            reply.authorName,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
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
                                    'SOLUTION',
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
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'MMM dd, yyyy • HH:mm',
                            ).format(reply.createdAt),
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
                // Reply actions with modern buttons
                Row(
                  children: [
                    // Like button
                    StreamBuilder<bool>(
                      stream: Stream.fromFuture(_isReplyLiked(reply.id)),
                      builder: (context, likeSnapshot) {
                        final isLiked = likeSnapshot.data ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            color:
                                isLiked
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () => _toggleReplyLike(reply.id),
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isLiked ? Colors.red : Colors.grey[600],
                            ),
                            tooltip: 'Like',
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
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () => _showNestedReplyInput(reply.id),
                          icon: Icon(
                            Icons.reply,
                            size: 18,
                            color: AppConstants.primaryColor,
                          ),
                          tooltip: 'Reply',
                        ),
                      ),
                    const SizedBox(width: 8),
                    // More options
                    PopupMenuButton<String>(
                      onSelected:
                          (value) => _handleReplyAction(value, reply, topic),
                      itemBuilder:
                          (context) => [
                            if (isTopicAuthor && !reply.isSolution)
                              const PopupMenuItem(
                                value: 'mark_solution',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Mark as Solution'),
                                  ],
                                ),
                              ),
                            if (isTopicAuthor && reply.isSolution)
                              const PopupMenuItem(
                                value: 'unmark_solution',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Unmark as Solution'),
                                  ],
                                ),
                              ),
                            if (isAuthor)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            if (_isAdmin)
                              const PopupMenuItem(
                                value: 'moderate',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Moderate'),
                                  ],
                                ),
                              ),
                          ],
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    ),
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
                  color: Colors.grey[25],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                                  color: Colors.grey.withOpacity(0.1),
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
                                            .withOpacity(0.1),
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
                                          tooltip: 'Delete',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Write a thoughtful reply...',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitReply(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSubmittingReply ? null : _submitReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child:
                  _isSubmittingReply
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Icon(Icons.send, size: 20),
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
        color: Colors.grey[25],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nestedReplyController,
              decoration: InputDecoration(
                hintText: 'Write a reply...',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
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

    setState(() {
      _isSubmittingReply = true;
    });

    try {
      await ForumService.createReply(
        topicId: widget.topicId,
        content: _replyController.text.trim(),
      );
      _replyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Reply posted successfully!',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Error posting reply: $e',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() {
        _isSubmittingReply = false;
      });
    }
  }

  Future<void> _submitNestedReply(String parentReplyId) async {
    if (_nestedReplyController.text.trim().isEmpty) return;

    try {
      await ForumService.createReply(
        topicId: widget.topicId,
        content: _nestedReplyController.text.trim(),
        parentReplyId: parentReplyId,
      );
      _nestedReplyController.clear();
      setState(() {
        _showNestedReply = false;
        _replyingToId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Reply posted successfully!',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Error posting reply: $e',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
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

  Future<void> _toggleReplyLike(String replyId) async {
    try {
      await ForumService.toggleReplyLike(widget.topicId, replyId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Error toggling like: $e',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
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

  Future<bool> _isReplyLiked(String replyId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    try {
      // getReply method removed - we'll handle this differently
      // For now, we'll just return false
      return false;
    } catch (e) {
      return false;
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
                isSolution ? 'Marked as solution!' : 'Unmarked as solution!',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Error marking solution: $e',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
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
    // Check if user has permission to delete this reply
    final canDelete = await _contentService.canDeleteContent(replyAuthorId);
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'You do not have permission to delete this reply.',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
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
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Delete Reply',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete this reply? This action cannot be undone.',
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ForumService.deleteReply(widget.topicId, replyId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Reply deleted successfully!',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Error deleting reply: $e',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
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
          (context) => AlertDialog(
            title: Text(
              'Moderate Topic',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Topic: ${topic.title}',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                _buildModeratorButtons(topic),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
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
            'Unpin Topic',
            Icons.push_pin_outlined,
            Colors.orange,
            () => _moderateTopic(topic.id, 'unpin'),
          )
        else
          _buildModeratorButton(
            'Pin Topic',
            Icons.push_pin,
            Colors.orange,
            () => _moderateTopic(topic.id, 'pin'),
          ),
        if (topic.isLocked)
          _buildModeratorButton(
            'Unlock Topic',
            Icons.lock_open,
            Colors.green,
            () => _moderateTopic(topic.id, 'unlock'),
          )
        else
          _buildModeratorButton(
            'Lock Topic',
            Icons.lock,
            Colors.red,
            () => _moderateTopic(topic.id, 'lock'),
          ),
        if (topic.isHidden)
          _buildModeratorButton(
            'Unhide Topic',
            Icons.visibility,
            Colors.green,
            () => _moderateTopic(topic.id, 'unhide'),
          )
        else
          _buildModeratorButton(
            'Hide Topic',
            Icons.visibility_off,
            Colors.orange,
            () => _moderateTopic(topic.id, 'hide'),
          ),
        _buildModeratorButton(
          'Delete Topic',
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
    Navigator.pop(context); // Close dialog

    String? reason;
    if (action == 'hide' || action == 'lock' || action == 'delete') {
      reason = await _showReasonDialog(action);
      if (reason == null) return;
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

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Topic ${action}d successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to $action topic');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _showReasonDialog(String action) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reason for ${action}ing'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter reason for ${action}ing this content...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _showReplyModeratorDialog(ForumReply reply) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Moderate Reply'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Reply by: ${reply.authorName}'),
                const SizedBox(height: 16),
                _buildReplyModeratorButtons(reply),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
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
            'Unhide Reply',
            Icons.visibility,
            Colors.green,
            () => _moderateReply(reply, 'unhide'),
          )
        else
          _buildModeratorButton(
            'Hide Reply',
            Icons.visibility_off,
            Colors.orange,
            () => _moderateReply(reply, 'hide'),
          ),
        _buildModeratorButton(
          'Delete Reply',
          Icons.delete_forever,
          Colors.red,
          () => _moderateReply(reply, 'delete'),
        ),
      ],
    );
  }

  Future<void> _moderateReply(ForumReply reply, String action) async {
    Navigator.pop(context); // Close dialog

    String? reason;
    if (action == 'hide' || action == 'delete') {
      reason = await _showReasonDialog(action);
      if (reason == null) return;
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

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply ${action}d successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to $action reply');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
