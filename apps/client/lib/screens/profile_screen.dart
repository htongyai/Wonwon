import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/models/repair_record.dart';
import 'package:shared/models/user.dart' as app_user;
import 'package:shared/services/user_service.dart';
import 'package:wonwon_client/screens/login_screen.dart';
import 'package:wonwon_client/screens/settings_screen.dart';
import 'package:wonwon_client/widgets/sustainability/impact_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/mixins/widget_disposal_mixin.dart';
import 'package:shared/services/optimized_image_cache_manager.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:shared/services/unified_memory_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetDisposalMixin<ProfileScreen> {
  firebase_auth.User? _user;
  app_user.User? _userData;
  bool _loading = true;
  bool _uploadingImage = false;
  Future<List<RepairRecord>>? _repairRecordsFuture;
  int _savedCount = 0;
  int _repairCount = 0;
  int _reviewCount = 0;

  @override
  void onInitState() {
    _user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (_user != null) _loading = false;

    listenToStream(firebase_auth.FirebaseAuth.instance.authStateChanges(), (
      user,
    ) {
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
      if (user != null) {
        _setupUserDataListener(user.uid);
        _repairRecordsFuture = _fetchRepairRecords();
        _fetchCounts();
      } else {
        setState(() {
          _userData = null;
          _repairRecordsFuture = null;
          _savedCount = 0;
          _repairCount = 0;
          _reviewCount = 0;
        });
      }
    });
  }

  void _setupUserDataListener(String uid) {
    // Primary listener on the user doc — picks up profile field changes
    // AND the denormalized `reviewCount` that ReviewService now
    // maintains (so the profile stat updates the moment a review is
    // written or deleted, without requiring a page refresh).
    listenToStream(
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      (snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data() ?? {};
          setState(() {
            _userData = app_user.User.fromMap(data, snapshot.id);
            _loading = false;
            final denormalized = (data['reviewCount'] as num?)?.toInt();
            // Only trust the denormalized counter if it's present —
            // otherwise the one-shot _fetchCounts seed still wins.
            if (denormalized != null) {
              _reviewCount = denormalized;
            }
          });
        }
      },
      onError: (error) {
        appLog('Error listening to user data: $error');
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      },
    );

    // Real-time saved-shop count via the user's savedShops subcollection.
    // Cheap to listen on (scoped to the signed-in user's own data).
    listenToStream(
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('savedShops')
          .snapshots(),
      (snapshot) {
        if (mounted) {
          setState(() => _savedCount = snapshot.docs.length);
        }
      },
      onError: (e) => appLog('savedShops stream error: $e'),
    );

    // Real-time repair-record count via the user's repairRecords
    // subcollection — same reactivity as saved shops.
    listenToStream(
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('repairRecords')
          .snapshots(),
      (snapshot) {
        if (mounted) {
          setState(() => _repairCount = snapshot.docs.length);
        }
      },
      onError: (e) => appLog('repairRecords stream error: $e'),
    );
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;
    try {
      final userData = await UserService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      appLog('Error fetching user data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    setState(() {
      _uploadingImage = true;
    });

    try {
      final imageUrl = await UserService.uploadProfileImage();
      if (!mounted) return;
      if (imageUrl != null) {
        await _fetchUserData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_image_updated'.tr(context)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_uploading_image'.tr(context)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      final success = await UserService.deleteProfileImage();
      if (!mounted) return;
      if (success) {
        await _fetchUserData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile_image_removed'.tr(context)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_removing_image'.tr(context)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<List<RepairRecord>> _fetchRepairRecords() async {
    final user = _user;
    if (user == null) return [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('repairRecords')
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      final records = snapshot.docs.map((doc) {
        return RepairRecord.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
      if (mounted) {
        setState(() => _repairCount = records.length);
      }
      return records;
    } catch (e) {
      appLog('Error fetching repair records: $e');
      return [];
    }
  }

  Future<void> _fetchCounts() async {
    final user = _user;
    if (user == null) return;
    try {
      // Fetch saved shops count
      final savedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedShops')
          .get();
      if (!mounted) return;
      setState(() {
        _savedCount = savedSnapshot.docs.length;
      });

      // Short-circuit the expensive shop-by-shop review scan if the
      // user doc already has a denormalized reviewCount — that field
      // is the source of truth going forward, maintained atomically by
      // ReviewService. The stream listener on the user doc already
      // wires it into `_reviewCount`, so we don't need to recompute.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final existingCounter =
          (userDoc.data()?['reviewCount'] as num?)?.toInt();
      if (existingCounter != null) {
        if (mounted) {
          setState(() => _reviewCount = existingCounter);
        }
        return;
      }

      // Legacy path: user doc hasn't been seeded yet. Count reviews
      // across shops once, then persist the value so future reads are
      // cheap and realtime.
      int reviewCount = 0;
      final shopsSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .get();
      // Query reviews in parallel for efficiency
      final reviewFutures = <Future<QuerySnapshot>>[];
      for (final shopDoc in shopsSnapshot.docs) {
        reviewFutures.add(
          FirebaseFirestore.instance
              .collection('shops')
              .doc(shopDoc.id)
              .collection('review')
              .where('userId', isEqualTo: user.uid)
              .get(),
        );
      }
      final reviewSnapshots = await Future.wait(reviewFutures);
      for (final snapshot in reviewSnapshots) {
        reviewCount += snapshot.docs.length;
      }
      if (!mounted) return;
      setState(() {
        _reviewCount = reviewCount;
      });

      // Seed the user doc so subsequent loads skip the scan and the
      // stream listener picks up atomic increments.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'reviewCount': reviewCount}, SetOptions(merge: true));
      } catch (e) {
        appLog('Failed to seed user reviewCount: $e');
      }
    } catch (e) {
      appLog('Error fetching counts: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppConstants.primaryColor,
                  ),
                ),
                title: Text(
                  _userData?.profileImageUrl != null
                      ? 'change_image'.tr(context)
                      : 'upload_image'.tr(context),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _uploadProfileImage();
                },
              ),
              if (_userData?.profileImageUrl != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    'remove_image'.tr(context),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfileImage();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return _buildUnauthenticatedView();
    }

    return _buildAuthenticatedView();
  }

  // ---------------------------------------------------------------------------
  // Unauthenticated
  // ---------------------------------------------------------------------------
  Widget _buildUnauthenticatedView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'profile'.tr(context),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'login_to_view_profile'.tr(context),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'please_login_to_view_profile'.tr(context),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'log_in'.tr(context),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Authenticated
  // ---------------------------------------------------------------------------
  Widget _buildAuthenticatedView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FA);
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'profile'.tr(context),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        backgroundColor: theme.cardColor,
        elevation: 0,
        scrolledUnderElevation: .5,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'settings'.tr(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _repairRecordsFuture = _fetchRepairRecords();
          await _fetchCounts();
          await _fetchUserData();
        },
        color: AppConstants.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ---- Profile header card ----
              Container(
                width: double.infinity,
                color: theme.cardColor,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  children: [
                    // Avatar with edit badge
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _uploadingImage ? null : _showImageOptions,
                        customBorder: const CircleBorder(),
                        child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConstants.primaryColor
                                    .withValues(alpha: 0.2),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _userData?.profileImageUrl != null
                                  ? getCachedImage(
                                      imageUrl:
                                          _userData?.profileImageUrl ?? '',
                                      imageType: ImageType.profile,
                                      priority: MemoryPriority.high,
                                      fit: BoxFit.cover,
                                      width: 96,
                                      height: 96,
                                      placeholder: Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: _buildAvatarFallback(),
                                    )
                                  : _buildAvatarFallback(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.cardColor,
                                  width: 2.5,
                                ),
                              ),
                              child: _uploadingImage
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      _userData?.name.isNotEmpty == true
                          ? _userData!.name
                          : _user!.email ?? 'user_fallback'.tr(context),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      _user!.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Edit profile button
                    OutlinedButton(
                      onPressed: _uploadingImage ? null : _showImageOptions,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                        side: BorderSide(
                          color: AppConstants.primaryColor.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        'edit_profile'.tr(context),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ---- Stats row ----
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        count: _repairCount,
                        label: 'repairs'.tr(context),
                        icon: FontAwesomeIcons.screwdriverWrench,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.dividerColor,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        count: _savedCount,
                        label: 'saved'.tr(context),
                        icon: Icons.bookmark_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.dividerColor,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        count: _reviewCount,
                        label: 'reviews'.tr(context),
                        icon: Icons.star_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---- Sustainability impact card ----
              FutureBuilder<List<RepairRecord>>(
                future: _repairRecordsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ImpactCard(records: snapshot.data!);
                },
              ),

              // ---- Repair summary analytics card ----
              FutureBuilder<List<RepairRecord>>(
                future: _repairRecordsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _buildRepairSummaryCard(snapshot.data!);
                },
              ),

              // ---- Recent Activity header ----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'repair_history'.tr(context),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ---- Repair history list ----
              FutureBuilder<List<RepairRecord>>(
                future: _repairRecordsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyHistory();
                  }
                  final records = snapshot.data!;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildRepairRecordCard(records[index]);
                    },
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Aggregated summary of the user's repair history — total spent, avg
  /// satisfaction, top category, and a simple insight. Shown above the
  /// repair records list when at least one record exists.
  Widget _buildRepairSummaryCard(List<RepairRecord> records) {
    double totalSpent = 0;
    int totalRepairs = records.length;
    double totalSatisfaction = 0;
    int satisfactionCount = 0;
    final categoryCounts = <String, int>{};

    for (final r in records) {
      totalSpent += r.price ?? 0;
      if (r.satisfactionRating != null) {
        totalSatisfaction += r.satisfactionRating!;
        satisfactionCount++;
      }
      categoryCounts.update(r.category, (v) => v + 1, ifAbsent: () => 1);
    }

    final avgSatisfaction =
        satisfactionCount == 0 ? 0.0 : totalSatisfaction / satisfactionCount;

    String? topCategory;
    int topCount = 0;
    for (final e in categoryCounts.entries) {
      if (e.value > topCount) {
        topCount = e.value;
        topCategory = e.key;
      }
    }

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded,
                    size: 18, color: AppConstants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'repair_summary_title'.tr(context),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _summaryStat(
                    value: totalRepairs.toString(),
                    label: 'summary_repairs'.tr(context),
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: theme.dividerColor),
                Expanded(
                  child: _summaryStat(
                    value:
                        '฿${totalSpent.toStringAsFixed(0)}',
                    label: 'summary_spent'.tr(context),
                  ),
                ),
                Container(
                    width: 1,
                    height: 40,
                    color: theme.dividerColor),
                Expanded(
                  child: _summaryStat(
                    value: satisfactionCount == 0
                        ? '—'
                        : '${avgSatisfaction.toStringAsFixed(1)}/5',
                    label: 'summary_satisfaction'.tr(context),
                  ),
                ),
              ],
            ),
            if (topCategory != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded,
                        size: 12, color: AppConstants.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'summary_top_category'
                          .tr(context)
                          .replaceFirst(
                              '{category}', 'category_$topCategory'.tr(context)),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryStat({required String value, required String label}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: AppConstants.primaryColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        size: 44,
        color: AppConstants.primaryColor,
      ),
    );
  }

  Widget _buildStatItem({
    required int count,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistory() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.screwdriverWrench,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'no_repair_records'.tr(context),
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRepairRecordCard(RepairRecord record) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RepairRecordDetailScreen(record: record),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  FontAwesomeIcons.screwdriverWrench,
                  color: AppConstants.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.shopName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.itemFixed,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTag(record.category),
                        _buildTag(record.subService),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(record.date.toLocal()),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (record.satisfactionRating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        record.satisfactionRating ?? 0,
                        (index) => const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 14,
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

  Widget _buildTag(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// =============================================================================
// Repair Record Detail Screen
// =============================================================================
class RepairRecordDetailScreen extends StatelessWidget {
  final RepairRecord record;
  const RepairRecordDetailScreen({Key? key, required this.record})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'repair_record_details'.tr(context),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: .5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          FontAwesomeIcons.screwdriverWrench,
                          color: AppConstants.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.shopName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.itemFixed,
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(record.category),
                      _buildChip(record.subService),
                    ],
                  ),
                ],
              ),
            ),

            // Details
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'details'.tr(context),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    'date'.tr(context),
                    DateFormat('yyyy-MM-dd').format(record.date.toLocal()),
                  ),
                  if (record.price != null)
                    _buildDetailRow(
                      Icons.payments_outlined,
                      'price'.tr(context),
                      '${record.price!.toStringAsFixed(0)} THB',
                    ),
                  if (record.duration != null)
                    _buildDetailRow(
                      Icons.timer_outlined,
                      'duration'.tr(context),
                      '${record.duration?.inDays ?? 0} ${'days'.tr(context)}',
                    ),
                  if (record.satisfactionRating != null)
                    _buildDetailRow(
                      Icons.thumb_up_outlined,
                      'satisfaction'.tr(context),
                      '${record.satisfactionRating}/5',
                    ),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    _buildDetailRow(
                      Icons.notes_outlined,
                      'notes'.tr(context),
                      record.notes ?? '',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
                fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                          fontSize: 15, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
