import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/models/repair_record.dart';
import 'package:wonwonw2/models/user.dart' as app_user;
import 'package:wonwonw2/services/user_service.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';
import 'package:wonwonw2/widgets/common/shimmer_loading.dart';

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
  bool _isAdmin = false;
  bool _uploadingImage = false;
  Future<List<RepairRecord>>? _repairRecordsFuture;
  int _savedCount = 0;
  int _repairCount = 0;

  @override
  void onInitState() {
    _user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _setupUserDataListener(_user!.uid);
      _fetchAdminStatus(_user!.uid);
      _repairRecordsFuture = _fetchRepairRecords();
      _fetchCounts();
    }

    // Use the mixin's automatic subscription management
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
        _fetchAdminStatus(user.uid);
        _repairRecordsFuture = _fetchRepairRecords();
        _fetchCounts();
      } else {
        setState(() {
          _isAdmin = false;
          _userData = null;
          _repairRecordsFuture = null;
          _savedCount = 0;
          _repairCount = 0;
        });
      }
    });
  }

  void _setupUserDataListener(String uid) {
    // Use the mixin's automatic subscription management
    listenToStream(
      FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      (snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _userData = app_user.User.fromMap(snapshot.data()!, snapshot.id);
            _loading = false;
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

  Future<void> _fetchAdminStatus(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      setState(() {
        _isAdmin =
            doc.data()?['admin'] == true || doc.data()?['accountType'] == 'admin';
      });
    } catch (e) {
      appLog('Error fetching admin status: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
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
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_uploading_image'.tr(context).replaceAll('{error}', '$e')),
          backgroundColor: Colors.red,
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
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_removing_image'.tr(context).replaceAll('{error}', '$e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<RepairRecord>> _fetchRepairRecords() async {
    if (_user == null) return [];
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .collection('repairRecords')
              .orderBy('date', descending: true)
              .limit(50)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure the ID is included
        return RepairRecord.fromMap(data);
      }).toList();
    } catch (e) {
      appLog('Error fetching repair records: $e');
      return [];
    }
  }

  Future<void> _fetchCounts() async {
    if (_user == null) return;
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('savedShops')
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('repairRecords')
            .get(),
      ]);
      if (!mounted) return;
      setState(() {
        _savedCount = results[0].docs.length;
        _repairCount = results[1].docs.length;
      });
    } catch (e) {
      appLog('Error fetching counts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: ShimmerProfileCard(avatarRadius: 40, showStats: true),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 64,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'login_to_view_profile'.tr(context),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'please_login_to_view_profile'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 220,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: Text('log_in'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr(context), style: GoogleFonts.montserrat()),
      ),
      body: Column(
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Profile image section
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.primaryColor.withValues(alpha: 0.3),
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 12),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            _userData?.profileImageUrl != null
                                ? getCachedImage(
                                  imageUrl: _userData?.profileImageUrl ?? '',
                                  imageType: ImageType.profile,
                                  priority: MemoryPriority.high,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  placeholder: Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: Container(
                                    color: AppConstants.primaryColor
                                        .withValues(alpha: 0.15),
                                    child: Icon(
                                      Icons.person,
                                      size: 48,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                )
                                : Container(
                                  color: AppConstants.primaryColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 48,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                      ),
                    ),
                    // Upload button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed:
                              _uploadingImage ? null : _uploadProfileImage,
                          icon:
                              _uploadingImage
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          tooltip: 'upload_profile_image'.tr(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User info
                Column(
                  children: [
                    Text(
                      _userData?.name.isNotEmpty == true
                          ? _userData!.name
                          : _user!.email ?? 'user_fallback'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!.email ?? '',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isAdmin) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'admin'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Stats row
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        _savedCount,
                        'saved'.tr(context),
                        Icons.bookmark_rounded,
                      ),
                      _buildStatItem(
                        _repairCount,
                        'repairs'.tr(context),
                        Icons.build_rounded,
                      ),
                      _buildStatItem(
                        0,
                        'reviews'.tr(context),
                        Icons.star_rounded,
                      ),
                    ],
                  ),
                ),

                // Action buttons
                const SizedBox(height: 16),
                if (_userData?.profileImageUrl != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteProfileImage,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text('remove_image'.tr(context)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _uploadingImage ? null : _uploadProfileImage,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      _userData?.profileImageUrl != null
                          ? 'change_image'.tr(context)
                          : 'upload_image'.tr(context),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),

                // Admin Dashboard Button — disabled, admin is a separate app
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'repair_history'.tr(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RepairRecord>>(
              future: _repairRecordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ShimmerRepairRecordList(itemCount: 4);
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'no_repair_records'.tr(context),
                      style: GoogleFonts.montserrat(),
                    ),
                  );
                }
                final records = snapshot.data!;
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _buildRepairRecordCard(record);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppConstants.primaryColor),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: count),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Text(
            '$value',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryTextColor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRepairRecordCard(RepairRecord record) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RepairRecordDetailScreen(record: record),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FontAwesomeIcons.screwdriverWrench,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            record.shopName,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppConstants.primaryTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            record.itemFixed,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record.category,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record.subService,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        record.date.toLocal().toString().split(' ')[0],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (record.satisfactionRating != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            record.satisfactionRating ?? 0,
                            (index) => Icon(
                              Icons.thumb_up,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RepairRecordDetailScreen extends StatelessWidget {
  final RepairRecord record;
  const RepairRecordDetailScreen({Key? key, required this.record})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('repair_record_details'.tr(context)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
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
                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          FontAwesomeIcons.screwdriverWrench,
                          color: AppConstants.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.shopName,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              record.itemFixed,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          record.category,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          record.subService,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Details section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'details'.tr(context),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    context,
                    Icons.calendar_today,
                    'date'.tr(context),
                    record.date.toLocal().toString().split(' ')[0],
                  ),
                  if (record.price != null)
                    _buildDetailItem(
                      context,
                      Icons.payments_outlined,
                      'price'.tr(context),
                      '฿${record.price!.toStringAsFixed(0)}',
                    ),
                  if (record.duration != null)
                    _buildDetailItem(
                      context,
                      Icons.timer,
                      'duration'.tr(context),
                      '${record.duration?.inDays ?? 0} ' + 'days'.tr(context),
                    ),
                  if (record.satisfactionRating != null)
                    _buildDetailItem(
                      context,
                      Icons.thumb_up,
                      'satisfaction'.tr(context),
                      '${record.satisfactionRating}/5',
                    ),
                  if (record.notes != null && record.notes!.isNotEmpty)
                    _buildDetailItem(
                      context,
                      Icons.notes,
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

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    color: AppConstants.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
