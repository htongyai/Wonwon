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

class DesktopProfileScreen extends StatefulWidget {
  const DesktopProfileScreen({Key? key}) : super(key: key);

  @override
  State<DesktopProfileScreen> createState() => _DesktopProfileScreenState();
}

class _DesktopProfileScreenState extends State<DesktopProfileScreen> {
  firebase_auth.User? _user;
  app_user.User? _userData;
  bool _loading = true;
  bool _isAdmin = false;
  bool _uploadingImage = false;
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _setupUserDataListener(_user!.uid);
      _fetchAdminStatus(_user!.uid);
    }
    _authStateSubscription = firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((user) {
          // Double check that widget is still mounted and subscription is active
          if (mounted && _authStateSubscription != null) {
            setState(() {
              _user = user;
              _loading = false;
            });
            if (user != null) {
              _setupUserDataListener(user.uid);
              _fetchAdminStatus(user.uid);
            } else {
              _userDataSubscription?.cancel();
              if (mounted) {
                setState(() {
                  _isAdmin = false;
                  _userData = null;
                });
              }
            }
          }
        });
  }

  void _setupUserDataListener(String uid) {
    _userDataSubscription?.cancel();
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && mounted && _userDataSubscription != null) {
              setState(() {
                _userData = app_user.User.fromMap(
                  snapshot.data()!,
                  snapshot.id,
                );
                _loading = false;
              });
            }
          },
          onError: (error) {
            print('Error listening to user data: $error');
            if (mounted && _userDataSubscription != null) {
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
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchAdminStatus(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() {
        _isAdmin =
            doc.data()?['admin'] == true ||
            doc.data()?['accountType'] == 'admin';
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (mounted) {
      setState(() {
        _uploadingImage = true;
      });
    }

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
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
      }
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
        data['id'] = doc.id;
        return RepairRecord.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error fetching repair records: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    _userDataSubscription = null;
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    super.dispose();
  }

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
              style: GoogleFonts.montserrat(fontSize: 18),
            ),
            const SizedBox(height: 24),
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
      body: Container(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar - Profile info
            Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child:
                                _userData?.profileImageUrl != null
                                    ? Image.network(
                                      _userData!.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.15),
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppConstants.primaryColor,
                                          ),
                                        );
                                      },
                                    )
                                    : Container(
                                      color: AppConstants.primaryColor
                                          .withOpacity(0.15),
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
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
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              tooltip: 'Upload Profile Image',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User info
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _userData?.name.isNotEmpty == true
                              ? _userData!.name
                              : _user!.email ?? 'User',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user!.email ?? '',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_isAdmin) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Admin',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  if (_userData?.profileImageUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _deleteProfileImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove Profile Image'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploadingImage ? null : _uploadProfileImage,
                      icon: const Icon(Icons.edit),
                      label: Text(
                        _userData?.profileImageUrl != null
                            ? 'Change Image'
                            : 'Upload Image',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 32),

            // Right content - Repair history
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.history,
                          color: AppConstants.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'repair_history'.tr(context),
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: FutureBuilder<List<RepairRecord>>(
                        future: _fetchRepairRecords(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'no_repair_records'.tr(context),
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairRecordCard(RepairRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  record.shopName,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.darkColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.category,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            record.itemFixed,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              record.notes!,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Date: ${record.date.toString().split(' ')[0]}',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (record.price != null && record.price! > 0) ...[
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Price: \$${record.price!.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ],
          ),
          if (record.satisfactionRating != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber[600]),
                const SizedBox(width: 8),
                Text(
                  'Rating: ${record.satisfactionRating}/5',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
