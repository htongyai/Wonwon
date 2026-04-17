import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted draft of a forum topic the user is composing.
class ForumDraft {
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final DateTime savedAt;

  ForumDraft({
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'category': category,
        'tags': tags,
        'savedAt': savedAt.millisecondsSinceEpoch,
      };

  factory ForumDraft.fromJson(Map<String, dynamic> m) => ForumDraft(
        title: m['title'] as String? ?? '',
        content: m['content'] as String? ?? '',
        category: m['category'] as String? ?? 'general',
        tags: (m['tags'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        savedAt: DateTime.fromMillisecondsSinceEpoch(
          (m['savedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
        ),
      );

  bool get isEmpty =>
      title.trim().isEmpty && content.trim().isEmpty && tags.isEmpty;
}

/// Reads and writes a single forum-topic draft from SharedPreferences.
class ForumDraftStore {
  ForumDraftStore._();
  static final ForumDraftStore _instance = ForumDraftStore._();
  factory ForumDraftStore() => _instance;

  static const _prefsKey = 'forum_create_topic_draft_v1';

  Future<ForumDraft?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      final draft = ForumDraft.fromJson(map);
      if (draft.isEmpty) return null;
      return draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ForumDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, json.encode(draft.toJson()));
    } catch (_) {
      // Non-fatal
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
