import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/models/forum_topic.dart';
import 'package:wonwonw2/models/forum_reply.dart';
import 'package:wonwonw2/utils/app_logger.dart';

class ForumService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Topics collection
  static CollectionReference get _topicsCollection =>
      _firestore.collection('forum_topics');

  // Replies collection
  static CollectionReference get _repliesCollection =>
      _firestore.collection('forum_replies');

  // Get current user
  static User? get _currentUser => _auth.currentUser;

  // Create a new topic
  static Future<String> createTopic({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('User must be logged in to create a topic');
      }

      final topicData = {
        'title': title.trim(),
        'content': content.trim(),
        'authorId': _currentUser!.uid,
        'authorName':
            _currentUser!.displayName ?? _currentUser!.email ?? 'Anonymous',
        'category': category,
        'createdAt': Timestamp.now(),
        'lastActivity': Timestamp.now(),
        'replies': 0,
        'views': 0,
        'isPinned': false,
        'isLocked': false,
        'tags': tags,
        'metadata': {},
      };

      appLog('Attempting to create topic with data: $topicData');
      final docRef = await _topicsCollection.add(topicData);
      appLog('Topic created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      appLog('Error creating topic: $e');
      rethrow;
    }
  }

  // Get all topics with optional filtering
  static Stream<List<ForumTopic>> getTopics({
    String? category,
    String? searchQuery,
    bool? isPinned,
    int limit = 50,
  }) {
    try {
      Query query = _topicsCollection
          .orderBy('lastActivity', descending: true)
          .limit(limit);

      return query.snapshots().map((snapshot) {
        List<ForumTopic> topics = [];

        for (var doc in snapshot.docs) {
          try {
            final topic = ForumTopic.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );

            // Apply category filter in memory
            if (category != null && category != 'all') {
              if (topic.category != category) {
                continue;
              }
            }

            // Apply pinned filter in memory
            if (isPinned != null) {
              if (topic.isPinned != isPinned) {
                continue;
              }
            }

            // Apply search filter if provided
            if (searchQuery != null && searchQuery.isNotEmpty) {
              final query = searchQuery.toLowerCase();
              final matchesTitle = topic.title.toLowerCase().contains(query);
              final matchesAuthor = topic.authorName.toLowerCase().contains(
                query,
              );
              final matchesContent = topic.content.toLowerCase().contains(
                query,
              );

              if (!matchesTitle && !matchesAuthor && !matchesContent) {
                continue;
              }
            }

            topics.add(topic);
          } catch (e) {
            appLog('Error parsing topic ${doc.id}: $e');
          }
        }

        return topics;
      });
    } catch (e) {
      appLog('Error getting topics: $e');
      return Stream.value([]);
    }
  }

  // Get a single topic by ID
  static Future<ForumTopic?> getTopic(String topicId) async {
    try {
      final doc = await _topicsCollection.doc(topicId).get();
      if (doc.exists) {
        return ForumTopic.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      appLog('Error getting topic $topicId: $e');
      return null;
    }
  }

  // Update topic views
  static Future<void> incrementTopicViews(String topicId) async {
    try {
      await _topicsCollection.doc(topicId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      appLog('Error incrementing topic views: $e');
    }
  }

  // Update topic last activity
  static Future<void> updateTopicLastActivity(String topicId) async {
    try {
      await _topicsCollection.doc(topicId).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      appLog('Error updating topic last activity: $e');
    }
  }

  // Create a reply to a topic
  static Future<String> createReply({
    required String topicId,
    required String content,
    String? parentReplyId,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('User must be logged in to create a reply');
      }

      final replyData = {
        'topicId': topicId,
        'content': content.trim(),
        'authorId': _currentUser!.uid,
        'authorName':
            _currentUser!.displayName ?? _currentUser!.email ?? 'Anonymous',
        'createdAt': Timestamp.now(),
        'editedAt': null,
        'likes': 0,
        'likedBy': [],
        'isSolution': false,
        'parentReplyId': parentReplyId,
        'metadata': {},
      };

      appLog('Creating reply with data: $replyData');
      final docRef = await _repliesCollection.add(replyData);

      // Update topic's reply count and last activity
      await _topicsCollection.doc(topicId).update({
        'replies': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
      });

      appLog('Reply created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      appLog('Error creating reply: $e');
      rethrow;
    }
  }

  // Get replies for a topic
  static Stream<List<ForumReply>> getReplies(String topicId) {
    try {
      return _repliesCollection
          .where('topicId', isEqualTo: topicId)
          .snapshots()
          .map((snapshot) {
            appLog('Got ${snapshot.docs.length} replies for topic $topicId');
            List<ForumReply> replies = [];

            for (var doc in snapshot.docs) {
              try {
                final reply = ForumReply.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                // Filter out non-top-level replies in memory to avoid composite index
                if (reply.parentReplyId == null) {
                  replies.add(reply);
                }
              } catch (e) {
                appLog('Error parsing reply ${doc.id}: $e');
              }
            }

            // Sort by createdAt in memory to avoid composite index requirement
            replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            appLog('Successfully parsed ${replies.length} top-level replies');
            return replies;
          });
    } catch (e) {
      appLog('Error getting replies for topic $topicId: $e');
      return Stream.value([]);
    }
  }

  // Get nested replies for a specific reply
  static Stream<List<ForumReply>> getNestedReplies(String parentReplyId) {
    try {
      return _repliesCollection
          .where('parentReplyId', isEqualTo: parentReplyId)
          .snapshots()
          .map((snapshot) {
            List<ForumReply> replies = [];

            for (var doc in snapshot.docs) {
              try {
                final reply = ForumReply.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
                replies.add(reply);
              } catch (e) {
                appLog('Error parsing nested reply ${doc.id}: $e');
              }
            }

            // Sort by createdAt in memory to avoid composite index requirement
            replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));

            return replies;
          });
    } catch (e) {
      appLog('Error getting nested replies: $e');
      return Stream.value([]);
    }
  }

  // Like/unlike a reply
  static Future<void> toggleReplyLike(String replyId) async {
    try {
      if (_currentUser == null) {
        throw Exception('User must be logged in to like a reply');
      }

      final userId = _currentUser!.uid;
      final replyDoc = await _repliesCollection.doc(replyId).get();

      if (!replyDoc.exists) {
        throw Exception('Reply not found');
      }

      final replyData = replyDoc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(replyData['likedBy'] ?? []);
      final currentLikes = replyData['likes'] ?? 0;

      if (likedBy.contains(userId)) {
        // Unlike
        likedBy.remove(userId);
        await _repliesCollection.doc(replyId).update({
          'likes': currentLikes - 1,
          'likedBy': likedBy,
        });
      } else {
        // Like
        likedBy.add(userId);
        await _repliesCollection.doc(replyId).update({
          'likes': currentLikes + 1,
          'likedBy': likedBy,
        });
      }
    } catch (e) {
      appLog('Error toggling reply like: $e');
      rethrow;
    }
  }

  // Mark reply as solution
  static Future<void> markReplyAsSolution(
    String replyId,
    bool isSolution,
  ) async {
    try {
      await _repliesCollection.doc(replyId).update({'isSolution': isSolution});
    } catch (e) {
      appLog('Error marking reply as solution: $e');
      rethrow;
    }
  }

  // Delete a topic (only by author or admin)
  static Future<void> deleteTopic(String topicId) async {
    try {
      if (_currentUser == null) {
        throw Exception('User must be logged in to delete a topic');
      }

      final topic = await getTopic(topicId);
      if (topic == null) {
        throw Exception('Topic not found');
      }

      // Check if user is author or admin
      if (topic.authorId != _currentUser!.uid) {
        // TODO: Add admin check here
        throw Exception('Only the author can delete this topic');
      }

      // Delete all replies first
      final repliesSnapshot =
          await _repliesCollection.where('topicId', isEqualTo: topicId).get();

      for (var doc in repliesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the topic
      await _topicsCollection.doc(topicId).delete();
      appLog('Topic deleted successfully: $topicId');
    } catch (e) {
      appLog('Error deleting topic: $e');
      rethrow;
    }
  }

  // Delete a reply (only by author or admin)
  static Future<void> deleteReply(String replyId) async {
    try {
      if (_currentUser == null) {
        throw Exception('User must be logged in to delete a reply');
      }

      final replyDoc = await _repliesCollection.doc(replyId).get();
      if (!replyDoc.exists) {
        throw Exception('Reply not found');
      }

      final replyData = replyDoc.data() as Map<String, dynamic>;
      final authorId = replyData['authorId'];
      final topicId = replyData['topicId'];

      // Check if user is author or admin
      if (authorId != _currentUser!.uid) {
        // TODO: Add admin check here
        throw Exception('Only the author can delete this reply');
      }

      // Delete the reply
      await _repliesCollection.doc(replyId).delete();

      // Update topic's reply count
      await _topicsCollection.doc(topicId).update({
        'replies': FieldValue.increment(-1),
      });

      appLog('Reply deleted successfully: $replyId');
    } catch (e) {
      appLog('Error deleting reply: $e');
      rethrow;
    }
  }

  // Get a single reply by ID
  static Future<ForumReply?> getReply(String replyId) async {
    try {
      final doc = await _repliesCollection.doc(replyId).get();
      if (doc.exists) {
        return ForumReply.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      appLog('Error getting reply $replyId: $e');
      return null;
    }
  }

  // Add sample data for testing
  static Future<void> addSampleData() async {
    try {
      if (_currentUser == null) {
        throw Exception('User must be logged in to add sample data');
      }

      final sampleTopics = [
        {
          'title': 'Best repair shop for iPhone screen replacement in Bangkok?',
          'content':
              'I recently dropped my iPhone and the screen is cracked. Can anyone recommend a reliable repair shop in Bangkok that offers good quality screen replacement at a reasonable price? I\'m looking for somewhere that uses genuine or high-quality replacement parts.',
          'category': 'questions',
          'tags': ['iphone', 'screen', 'bangkok', 'repair'],
        },
        {
          'title': 'How to fix a broken zipper at home - DIY guide',
          'content':
              'Here\'s a step-by-step guide to fix a broken zipper at home:\n\n1. First, identify the problem - is it a missing tooth, stuck slider, or broken pull?\n2. For stuck zippers, try using a pencil or soap to lubricate\n3. For missing teeth, you can replace individual teeth with repair kits\n4. Always work slowly and carefully to avoid making it worse\n\nThis has saved me money on several occasions!',
          'category': 'repair_tips',
          'tags': ['zipper', 'diy', 'clothing', 'repair'],
        },
        {
          'title':
              'New repair shop opening in Central Plaza - Grand Opening Special!',
          'content':
              'We\'re excited to announce the opening of our new repair shop in Central Plaza! We specialize in electronics, watches, and jewelry repair. To celebrate our grand opening, we\'re offering 20% off all repairs for the first week. Come visit us on the 3rd floor near the food court!',
          'category': 'announcements',
          'tags': ['new shop', 'central plaza', 'grand opening', 'discount'],
        },
        {
          'title':
              'Excellent service at Central Plaza repair shop - Highly recommended!',
          'content':
              'I had my watch repaired at the Central Plaza repair shop and I couldn\'t be happier with the service. The staff was professional, the repair was done quickly, and the price was very reasonable. They even cleaned my watch for free! I\'ll definitely be going back for any future repairs.',
          'category': 'shop_reviews',
          'tags': [
            'recommended',
            'watch repair',
            'good service',
            'central plaza',
          ],
        },
        {
          'title':
              'Discussion: How has the repair industry changed in the last 5 years?',
          'content':
              'I\'ve been in the repair business for over 10 years and I\'ve noticed some significant changes recently. The rise of smartphones has created new opportunities, but also new challenges with parts availability and technical complexity. What are your thoughts on how the industry is evolving?',
          'category': 'general',
          'tags': ['industry', 'trends', 'discussion', 'repair business'],
        },
      ];

      for (final topicData in sampleTopics) {
        await createTopic(
          title: topicData['title'] as String,
          content: topicData['content'] as String,
          category: topicData['category'] as String,
          tags: List<String>.from(topicData['tags'] as List),
        );
      }

      appLog('Sample data added successfully');
    } catch (e) {
      appLog('Error adding sample data: $e');
      rethrow;
    }
  }

  // Test Firebase connectivity
  static Future<bool> testFirebaseConnection() async {
    try {
      final testDoc = await _topicsCollection.add({
        'test': true,
        'timestamp': Timestamp.now(),
      });
      await testDoc.delete();
      appLog('Firebase connection test successful');
      return true;
    } catch (e) {
      appLog('Firebase connection test failed: $e');
      return false;
    }
  }

  // Add sample reply for testing
  static Future<String> addSampleReply(String topicId) async {
    try {
      if (_currentUser == null) {
        throw Exception('User must be logged in to add sample reply');
      }

      final replyData = {
        'topicId': topicId,
        'content': 'This is a sample reply for testing purposes.',
        'authorId': _currentUser!.uid,
        'authorName':
            _currentUser!.displayName ?? _currentUser!.email ?? 'Anonymous',
        'createdAt': Timestamp.now(),
        'editedAt': null,
        'likes': 0,
        'likedBy': [],
        'isSolution': false,
        'parentReplyId': null,
        'metadata': {},
      };

      appLog('Adding sample reply with data: $replyData');
      final docRef = await _repliesCollection.add(replyData);

      // Update topic's reply count and last activity
      await _topicsCollection.doc(topicId).update({
        'replies': FieldValue.increment(1),
        'lastActivity': Timestamp.now(),
      });

      appLog('Sample reply created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      appLog('Error creating sample reply: $e');
      rethrow;
    }
  }

  // Get forum statistics
  static Future<Map<String, dynamic>> getForumStats() async {
    try {
      final topicsSnapshot = await _topicsCollection.get();
      final repliesSnapshot = await _repliesCollection.get();

      int totalTopics = topicsSnapshot.docs.length;
      int totalReplies = repliesSnapshot.docs.length;
      int totalViews = 0;

      for (var doc in topicsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalViews += (data['views'] ?? 0) as int;
      }

      return {
        'totalTopics': totalTopics,
        'totalReplies': totalReplies,
        'totalViews': totalViews,
      };
    } catch (e) {
      appLog('Error getting forum stats: $e');
      return {'totalTopics': 0, 'totalReplies': 0, 'totalViews': 0};
    }
  }
}
