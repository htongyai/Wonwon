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
import 'package:wonwonw2/screens/admin_dashboard_main_screen.dart';
import 'package:wonwonw2/mixins/widget_disposal_mixin.dart';
import 'package:wonwonw2/services/optimized_image_cache_manager.dart';
import 'package:wonwonw2/services/unified_memory_manager.dart';

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

  @override
  void onInitState() {
    _user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _setupUserDataListener(_user!.uid);
      _fetchAdminStatus(_user!.uid);
    }

    // Use the mixin's automatic subscription management
    listenToStream(firebase_auth.FirebaseAuth.instance.authStateChanges(), (
      user,
    ) {
      setState(() {
        _user = user;
        _loading = false;
      });
      if (user != null) {
        _setupUserDataListener(user.uid);
        _fetchAdminStatus(user.uid);
      } else {
        setState(() {
          _isAdmin = false;
          _userData = null;
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
        print('Error listening to user data: $error');
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
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchAdminStatus(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _isAdmin =
          doc.data()?['admin'] == true || doc.data()?['accountType'] == 'admin';
    });
  }

  Future<void> _uploadProfileImage() async {
    setState(() {
      _uploadingImage = true;
    });

    try {
      final imageUrl = await UserService.uploadProfileImage();
      if (imageUrl != null) {
        await _fetchUserData(); // Refresh user data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      final success = await UserService.deleteProfileImage();
      if (success) {
        await _fetchUserData(); // Refresh user data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing image: $e'),
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
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure the ID is included
        return RepairRecord.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching repair records: $e');
      return [];
    }
  }

  // Disposal is now handled automatically by WidgetDisposalMixin

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please log in to view your profile',
              style: GoogleFonts.montserrat(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Log In'),
            ),
          ],
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
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            _userData?.profileImageUrl != null
                                ? getCachedImage(
                                  imageUrl: _userData!.profileImageUrl!,
                                  imageType: ImageType.profile,
                                  priority: MemoryPriority.high,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                  placeholder: Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: Container(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.15),
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: AppConstants.primaryColor,
                                    ),
                                  ),
                                )
                                : Container(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.15,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
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
                              color: Colors.black.withOpacity(0.2),
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
                          tooltip: 'Upload Profile Image',
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
                          : _user!.email ?? 'User',
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
                          'Admin',
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

                // Action buttons
                const SizedBox(height: 16),
                if (_userData?.profileImageUrl != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _deleteProfileImage,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove Image'),
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
                          ? 'Change Image'
                          : 'Upload Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),

                // Admin Dashboard Button
                if (_isAdmin) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) => const AdminDashboardMainScreen(),
                          ),
                        );
                      },
                      icon: const FaIcon(FontAwesomeIcons.userShield, size: 18),
                      label: const Text('Admin Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'repair_history'.tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<RepairRecord>>(
              future: _fetchRepairRecords(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
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
                      color: AppConstants.primaryColor.withOpacity(0.1),
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
                        Text(
                          record.shopName,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppConstants.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.itemFixed,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
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
                                record.category,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                record.subService,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  color: Colors.grey[700],
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
                            record.satisfactionRating!,
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
                    color: Colors.black.withOpacity(0.05),
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
                          color: AppConstants.primaryColor.withOpacity(0.1),
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
                  Row(
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
                      const SizedBox(width: 8),
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
                      Icons.attach_money,
                      'price'.tr(context),
                      '${record.price} THB',
                    ),
                  if (record.duration != null)
                    _buildDetailItem(
                      context,
                      Icons.timer,
                      'duration'.tr(context),
                      '${record.duration!.inDays} ' + 'days'.tr(context),
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
                      record.notes!,
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
