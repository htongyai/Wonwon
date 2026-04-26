import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/models/forum_topic.dart';
import 'package:shared/models/forum_reply.dart';
import 'package:shared/services/forum_service.dart';
import 'package:shared/services/content_management_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwon_client/screens/login_screen.dart';
import 'package:wonwon_client/screens/forum_screen.dart';
import 'package:shared/services/analytics_service.dart';

class ForumTopicDetailScreen extends StatefulWidget {
  final String topicId;

  /// When provided, the screen is being rendered inline (e.g. desktop two-pane
  /// layout) and should call this instead of popping the navigator to go back.
  final VoidCallback? onBack;

  const ForumTopicDetailScreen({
    Key? key,
    required this.topicId,
    this.onBack,
  }) : super(key: key);

  @override
  State<ForumTopicDetailScreen> createState() => _ForumTopicDetailScreenState();
}

class _ForumTopicDetailScreenState extends State<ForumTopicDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final TextEditingController _nestedReplyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ContentManagementService _contentService = ContentManagementService();

  bool _isSubmittingReply = false;
  bool _isSubmittingNestedReply = false;
  String? _replyingToId;
  int _replyCharCount = 0;

  ForumTopic? _topic;
  bool _isLoadingTopic = true;
  String? _topicError;

  @override
  void initState() {
    super.initState();
    _loadTopic();
    ForumService.incrementTopicViews(widget.topicId).catchError((e) {
      // Non-critical — silently handle view count failures
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _nestedReplyController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  // ---------------------------------------------------------------------------
  // TIME FORMATTING
  // ---------------------------------------------------------------------------

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'forum_just_now'.tr(context);
    if (diff.inMinutes < 60) return 'time_minutes_ago'.tr(context).replaceAll('{count}', '${diff.inMinutes}');
    if (diff.inHours < 24) return 'time_hours_ago'.tr(context).replaceAll('{count}', '${diff.inHours}');
    if (diff.inDays < 7) return 'time_short_days_ago'.tr(context).replaceAll('{count}', '${diff.inDays}');
    return 'time_short_weeks_ago'.tr(context).replaceAll('{count}', '${(diff.inDays / 7).floor()}');
  }

  // ---------------------------------------------------------------------------
  // CATEGORY HELPERS
  // ---------------------------------------------------------------------------

  static const _categoryColors = <String, Color>{
    'all': Color(0xFF6366F1),
    'general': Color(0xFF22C55E),
    'repair_tips': Color(0xFFF59E0B),
    'shop_reviews': Color(0xFFA855F7),
    'questions': Color(0xFFEF4444),
    'announcements': Color(0xFF14B8A6),
  };

  static const _categoryLabels = <String, String>{
    'general': 'forum_general_discussion',
    'repair_tips': 'forum_repair_tips',
    'shop_reviews': 'forum_shop_reviews',
    'questions': 'forum_questions_help',
    'announcements': 'forum_announcements',
  };

  Color _catColor(String cat) => _categoryColors[cat] ?? const Color(0xFF6366F1);

  String _catLabel(String cat) {
    final key = _categoryLabels[cat];
    return key != null ? key.tr(context) : cat;
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final onBack = widget.onBack;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: onBack == null,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
        title: Text(
          _topic?.title ?? 'forum'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color:
                isDark ? theme.colorScheme.onSurface : AppConstants.darkColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
            color:
                isDark ? theme.colorScheme.onSurface : AppConstants.darkColor),
        actions: [
          if (_topic != null &&
              _topic!.authorId == FirebaseAuth.instance.currentUser?.uid)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') _showDeleteTopicDialog();
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(child: _buildBody()),
              if (_topic != null && !_topic!.isLocked)
                _buildReplyInput()
              else if (_topic != null && _topic!.isLocked)
                _buildLockedBanner(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    final theme = Theme.of(context);
    if (_isLoadingTopic) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'loading'.tr(context),
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
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
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'error_loading_topic'.tr(context),
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              'please_try_again'.tr(context),
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadTopic,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('retry'.tr(context)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            Icon(Icons.forum_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'topic_not_found'.tr(context),
              style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return _buildRepliesSection(topic);
  }

  // ---------------------------------------------------------------------------
  // TOPIC CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildTopicContent(ForumTopic topic) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges
          if (topic.isPinned || topic.isLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (topic.isPinned) _buildBadge('forum_pinned'.tr(context), Colors.orange, Icons.push_pin),
                  if (topic.isPinned && topic.isLocked) const SizedBox(width: 8),
                  if (topic.isLocked) _buildBadge('forum_locked'.tr(context), Colors.red, Icons.lock),
                ],
              ),
            ),
          // Title
          Text(
            topic.title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color:
                  isDark ? theme.colorScheme.onSurface : AppConstants.darkColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  topic.authorName.isNotEmpty ? topic.authorName[0].toUpperCase() : 'A',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.authorName,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _formatRelativeTime(topic.createdAt),
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Category chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _catColor(topic.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _catLabel(topic.category),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _catColor(topic.category),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),
          // Content
          Text(
            topic.content,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              height: 1.7,
              color: theme.colorScheme.onSurface,
            ),
          ),
          // Tags
          if (topic.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: topic.tags.map((tag) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ForumScreen(initialSearchTag: tag),
                      ),
                    );
                  },
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${topic.replies}',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Text(
                'forum_replies_label'.tr(context),
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 20),
              Icon(Icons.visibility_outlined,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${topic.views}',
                style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Text(
                'forum_views_label'.tr(context),
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPLIES SECTION
  // ---------------------------------------------------------------------------

  Widget _buildRepliesSection(ForumTopic topic) {
    return StreamBuilder<List<ForumReply>>(
      stream: ForumService.getReplies(widget.topicId),
      builder: (context, snapshot) {
        final allReplies = snapshot.data ?? [];
        final isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;

        // Split into top-level and nested replies (avoids N+1 queries)
        final topLevelReplies = allReplies.where((r) => r.parentReplyId == null).toList();
        final nestedByParent = <String, List<ForumReply>>{};
        for (final reply in allReplies) {
          if (reply.parentReplyId != null) {
            nestedByParent.putIfAbsent(reply.parentReplyId!, () => []).add(reply);
          }
        }

        return RefreshIndicator(
          onRefresh: () async => _loadTopic(),
          color: AppConstants.primaryColor,
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _buildTopicContent(topic),
              const SizedBox(height: 16),
              // Replies header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'forum_reply_count'.tr(context).replaceAll('{count}', '${allReplies.length}'),
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (isWaiting)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                      ),
                    ),
                  ),
                )
              else if (hasError)
                _buildErrorState()
              else if (topLevelReplies.isEmpty)
                _buildEmptyReplies()
              else
                ...topLevelReplies.map((reply) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildReplyCard(reply, topic, nestedReplies: nestedByParent[reply.id] ?? []),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyReplies() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'no_replies_yet'.tr(context),
              style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              'be_first_to_reply'.tr(context),
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 36, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'error_loading_replies'.tr(context),
              style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadTopic,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text('retry'.tr(context)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPLY CARD
  // ---------------------------------------------------------------------------

  Widget _buildReplyCard(ForumReply reply, ForumTopic topic, {List<ForumReply> nestedReplies = const []}) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthor = currentUser?.uid == reply.authorId;
    final isTopicAuthor = currentUser?.uid == topic.authorId;
    final isOP = reply.authorId == topic.authorId;
    final isLiked = currentUser != null && reply.likedBy.contains(currentUser.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reply.isSolution ? Colors.green.shade300 : theme.dividerColor,
          width: reply.isSolution ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: reply.isSolution
                      ? Colors.green.withValues(alpha: 0.12)
                      : AppConstants.primaryColor.withValues(alpha: 0.12),
                  child: Text(
                    reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : 'A',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: reply.isSolution ? Colors.green : AppConstants.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          reply.authorName,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOP) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OP',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ],
                      if (reply.isSolution) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 10, color: Colors.green),
                              const SizedBox(width: 3),
                              Text(
                                'forum_solution'.tr(context),
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  _formatRelativeTime(reply.createdAt),
                  style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                if (isTopicAuthor || isAuthor)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    padding: EdgeInsets.zero,
                    onSelected: (value) => _handleReplyAction(value, reply, topic),
                    itemBuilder: (context) => [
                      if (isTopicAuthor && !reply.isSolution)
                        PopupMenuItem(
                          value: 'mark_solution',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text('mark_as_solution'.tr(context), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      if (isTopicAuthor && reply.isSolution)
                        PopupMenuItem(
                          value: 'unmark_solution',
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Text('unmark_as_solution'.tr(context), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      if (isAuthor)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Text('delete_action'.tr(context), style: const TextStyle(color: Colors.red, fontSize: 14)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Text(
              reply.content,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Actions row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: Row(
              children: [
                // Reply button
                if (!topic.isLocked)
                  TextButton.icon(
                    onPressed: () => _showNestedReplyInput(reply.id),
                    icon: Icon(Icons.reply,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    label: Text(
                      'reply_tooltip'.tr(context),
                      style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                const Spacer(),
                // Like button
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _toggleReplyLike(reply.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isLiked
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        if (reply.likes > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${reply.likes}',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Nested reply input
          if (_replyingToId == reply.id)
            _buildNestedReplyInput(reply.id),
          // Nested replies (pre-fetched, no N+1 queries)
          if (nestedReplies.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: theme.dividerColor, width: 2),
                ),
              ),
              child: Column(
                children: nestedReplies.map((nested) => _buildNestedReply(
                  nested,
                  parentAuthorName: reply.authorName,
                  isTopicLocked: topic.isLocked,
                  parentReplyId: reply.id,
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NESTED REPLY
  // ---------------------------------------------------------------------------

  Widget _buildNestedReply(ForumReply reply, {bool isTopicLocked = false, String? parentReplyId, String? parentAuthorName}) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isLiked = currentUser != null && reply.likedBy.contains(currentUser.uid);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 0, 0),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppConstants.primaryColor.withValues(alpha: 0.35),
              width: 2.5,
            ),
          ),
        ),
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parentAuthorName != null && parentAuthorName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.subdirectory_arrow_right_rounded,
                        size: 12, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${'replying_to'.tr(context)} @$parentAuthorName',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  reply.authorName.isNotEmpty ? reply.authorName[0].toUpperCase() : 'A',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reply.authorName,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatRelativeTime(reply.createdAt),
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
              if (reply.authorId == currentUser?.uid)
                IconButton(
                  onPressed: () => _deleteReply(reply.id, reply.authorId),
                  icon: Icon(Icons.close,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'delete_tooltip'.tr(context),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 2, bottom: 0),
            child: Text(
              reply.content,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Actions: reply + like
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Row(
              children: [
                // Reply button (replies to the parent, mentioning this user)
                if (!isTopicLocked && parentReplyId != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _showNestedReplyInput(parentReplyId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.reply,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'reply_tooltip'.tr(context),
                            style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                // Like button
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => _toggleReplyLike(reply.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isLiked
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        if (reply.likes > 0) ...[
                          const SizedBox(width: 3),
                          Text(
                            '${reply.likes}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isLiked
                                  ? Colors.red
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPLY INPUT (bottom)
  // ---------------------------------------------------------------------------

  Widget _buildReplyInput() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _replyController,
                onChanged: (text) {
                  setState(() => _replyCharCount = text.trim().length);
                },
                decoration: InputDecoration(
                  hintText: 'write_reply_hint'.tr(context),
                  hintStyle: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                maxLines: 4,
                minLines: 1,
                maxLength: 5000,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.colorScheme.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _replyCharCount > 0
                ? AppConstants.primaryColor
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _isSubmittingReply || _replyCharCount == 0 ? null : _submitReply,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
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
                        color: _replyCharCount > 0
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBanner() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline,
              size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'topic_locked_no_replies'.tr(context),
            style: GoogleFonts.montserrat(
                fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NESTED REPLY INPUT
  // ---------------------------------------------------------------------------

  Widget _buildNestedReplyInput(String parentReplyId) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _nestedReplyController,
                decoration: InputDecoration(
                  hintText: 'write_reply_short'.tr(context),
                  hintStyle: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitNestedReply(parentReplyId),
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: theme.colorScheme.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _isSubmittingNestedReply ? null : () => _submitNestedReply(parentReplyId),
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                child: _isSubmittingNestedReply
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _replyingToId = null;
                _nestedReplyController.clear();
              });
            },
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              child: Icon(Icons.close,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  void _showNestedReplyInput(String replyId) {
    setState(() {
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
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    if (!mounted) return;
    setState(() => _isSubmittingReply = true);

    try {
      await ForumService.createReply(
        topicId: widget.topicId,
        content: _replyController.text.trim(),
      );
      AnalyticsService.safeLog(() => AnalyticsService().logReplyToTopic(widget.topicId));
      if (!mounted) return;
      _replyController.clear();
      setState(() => _replyCharCount = 0);
      _loadTopic();
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
      _showSnack('reply_posted'.tr(context), Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnack('error_posting_reply'.tr(context), Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false);
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
        _replyingToId = null;
      });
      _loadTopic();
      _showSnack('reply_posted'.tr(context), Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnack('error_posting_reply'.tr(context), Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmittingNestedReply = false);
      }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr(context), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ForumService.deleteTopic(widget.topicId);
      if (!mounted) return;
      _showSnack('topic_deleted'.tr(context), Colors.green);
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('error_deleting_topic'.tr(context), Colors.red);
    }
  }

  Future<void> _toggleReplyLike(String replyId) async {
    try {
      await ForumService.toggleReplyLike(widget.topicId, replyId);
      AnalyticsService.safeLog(() => AnalyticsService().logLikeContent(contentId: replyId, contentType: 'forum_reply'));
    } catch (e) {
      if (!mounted) return;
      _showSnack('error_generic'.tr(context), Colors.red);
    }
  }

  void _handleReplyAction(String action, ForumReply reply, ForumTopic topic) async {
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
    }
  }

  Future<void> _markReplyAsSolution(String replyId, bool isSolution) async {
    try {
      await ForumService.markReplyAsSolution(widget.topicId, replyId, isSolution);
      if (!mounted) return;
      _showSnack(
        isSolution ? 'marked_as_solution'.tr(context) : 'unmarked_as_solution'.tr(context),
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('error_generic'.tr(context), Colors.red);
    }
  }

  Future<void> _deleteReply(String replyId, String replyAuthorId) async {
    final canDelete = await _contentService.canDeleteContent(replyAuthorId);
    if (!mounted) return;
    if (!canDelete) {
      _showSnack('no_permission_delete'.tr(context), Colors.red);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 8),
            Text(
              'delete_reply_title'.tr(context),
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'delete_reply_confirm'.tr(context),
          style: GoogleFonts.montserrat(fontSize: 14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr(context)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('delete_button'.tr(context)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ForumService.deleteReply(widget.topicId, replyId);
        if (!mounted) return;
        _loadTopic();
        _showSnack('reply_deleted'.tr(context), Colors.green);
      } catch (e) {
        if (!mounted) return;
        _showSnack('error_generic'.tr(context), Colors.red);
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
