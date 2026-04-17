import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/services/forum_service.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/services/analytics_service.dart';

class ForumCreateTopicScreen extends StatefulWidget {
  const ForumCreateTopicScreen({Key? key}) : super(key: key);

  @override
  State<ForumCreateTopicScreen> createState() => _ForumCreateTopicScreenState();
}

class _ForumCreateTopicScreenState extends State<ForumCreateTopicScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedCategory = 'general';
  List<String> _tags = [];
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'general',
      'nameKey': 'general_discussion',
      'icon': FontAwesomeIcons.comments,
      'color': Colors.green,
    },
    {
      'id': 'repair_tips',
      'nameKey': 'repair_tips_tricks',
      'icon': FontAwesomeIcons.wrench,
      'color': Colors.orange,
    },
    {
      'id': 'shop_reviews',
      'nameKey': 'shop_reviews_category',
      'icon': FontAwesomeIcons.star,
      'color': Colors.purple,
    },
    {
      'id': 'questions',
      'nameKey': 'questions_help',
      'icon': FontAwesomeIcons.questionCircle,
      'color': Colors.red,
    },
    {
      'id': 'announcements',
      'nameKey': 'announcements',
      'icon': FontAwesomeIcons.bullhorn,
      'color': Colors.teal,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_submittedSuccessfully) return false;
    return _titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _tags.isNotEmpty;
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'discard_changes'.tr(context),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        content: Text(
          'discard_changes_message'.tr(context),
          style: GoogleFonts.montserrat(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'keep_editing'.tr(context),
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'discard'.tr(context),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBackButton() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (shouldDiscard && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog();
        if (shouldDiscard && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'create_new_topic'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.darkColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackButton,
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitTopic,
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(
                      'post'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
              children: [
                // Category selection
                _buildCategorySection(),
                const SizedBox(height: 24),
                // Title field
                _buildTitleField(),
                const SizedBox(height: 24),
                // Content field
                _buildContentField(),
                const SizedBox(height: 24),
                // Tags section
                _buildTagsSection(),
                const SizedBox(height: 24),
                // Guidelines
                _buildGuidelines(),
              ],
        ),
      ),
    ),
  ),
),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'select_category'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children:
                _categories
                    .map((category) => _buildCategoryOption(category))
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryOption(Map<String, dynamic> category) {
    final isSelected = _selectedCategory == category['id'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = category['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppConstants.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppConstants.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: FaIcon(
                    category['icon'],
                    color: category['color'],
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (category['nameKey'] as String).tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? AppConstants.primaryColor
                                : Colors.grey[800],
                      ),
                    ),
                    Text(
                      _getCategoryDescription(category['id']),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryDescription(String categoryId) {
    switch (categoryId) {
      case 'general':
        return 'forum_desc_general'.tr(context);
      case 'repair_tips':
        return 'forum_desc_repair_tips'.tr(context);
      case 'shop_reviews':
        return 'forum_desc_shop_reviews'.tr(context);
      case 'questions':
        return 'forum_desc_questions'.tr(context);
      case 'announcements':
        return 'forum_desc_announcements'.tr(context);
      default:
        return '';
    }
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'topic_title'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'topic_title_hint'.tr(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'title_required'.tr(context);
            }
            if (value.trim().length < 10) {
              return 'title_too_short'.tr(context);
            }
            if (value.trim().length > 100) {
              return 'title_too_long'.tr(context);
            }
            return null;
          },
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildContentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'topic_content'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: 'topic_content_hint'.tr(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppConstants.primaryColor),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'content_required'.tr(context);
            }
            if (value.trim().length < 20) {
              return 'content_too_short'.tr(context);
            }
            return null;
          },
          maxLines: 10,
          maxLength: 5000,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'tags_optional'.tr(context),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'forum_tags_help'.tr(context),
          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        // Tag input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: 'tags_hint'.tr(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppConstants.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
                onSubmitted: (value) => _addTag(value),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _addTag(_tagController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: Text('forum_add'.tr(context)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Tags display
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppConstants.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#$tag',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeTag(tag),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }

  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'community_guidelines'.tr(context),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'forum_guidelines_text'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().toLowerCase();
    if (trimmedTag.isNotEmpty &&
        !_tags.contains(trimmedTag) &&
        _tags.length < 5) {
      setState(() {
        _tags.add(trimmedTag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitTopic() async {
    appLog('_submitTopic called');
    if (!_formKey.currentState!.validate()) {
      appLog('Form validation failed');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      appLog('User not authenticated - cannot create topic');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('forum_login_to_create'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    appLog('Form validation passed, submitting topic...');
    setState(() {
      _isSubmitting = true;
    });

    try {
      appLog('Calling ForumService.createTopic...');
      final topicId = await ForumService.createTopic(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        tags: _tags,
      );
      appLog('Topic created with ID: $topicId');
      AnalyticsService.safeLog(() => AnalyticsService().logCreateTopic(topicId));

      if (mounted) {
        _submittedSuccessfully = true;
        messenger.showSnackBar(
          SnackBar(
            content: Text('topic_created'.tr(context)),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      appLog('Error creating topic: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text('error_creating_topic'.tr(context).replaceAll('{error}', e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
