import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared/constants/app_colors.dart';
import 'package:shared/constants/app_text_styles.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/screens/login_screen.dart';
import 'package:wonwon_client/screens/terms_of_use_screen.dart';
import 'package:wonwon_client/screens/privacy_policy_screen.dart';
import 'package:wonwon_client/screens/saved_locations_screen.dart';
import 'package:shared/services/auth_service.dart';
import 'package:wonwon_client/localization/app_localizations.dart' as localization;
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:wonwon_client/widgets/auth_gate.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _userEmail;
  final _auth = FirebaseAuth.instance;
  String _appVersion = '';
  bool _isResettingPassword = false;
  StreamSubscription<User?>? _authSubscription;

  Future<String?>? _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _authService.getUserName();
    _checkLoginStatus();
    _loadSelectedLanguage();
    _loadAppVersion();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _isLoggedIn = user != null;
          _userEmail = user?.email;
        });
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    final email = isLoggedIn ? await _authService.getUserEmail() : null;

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _userEmail = email;
      });
    }
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (result == true) {
      if (!mounted) return;
      _checkLoginStatus();
    }
  }

  Future<void> _handleLogout() async {
    final messenger = ScaffoldMessenger.of(context);
    final loggedOutMsg = 'logged_out_message'.tr(context);

    AnalyticsService.safeLog(() => AnalyticsService().logLogout());
    await _authService.logout();
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(loggedOutMsg),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _loadSelectedLanguage() async {
    final locale = await localization.AppLocalizationsService.getLocale();
    if (mounted) {
      setState(() {
        _selectedLanguage = locale.languageCode;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(
          'settings'.tr(context),
          style: AppTextStyles.heading.copyWith(color: AppColors.text, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Profile / Sign-in card (top)
              _isLoggedIn ? _buildProfileCard() : _buildSignInCard(),

              // Features section (logged-in only)
              if (user != null) ...[
                _buildSectionHeader('features'.tr(context)),
                _buildGroupedContainer(
                  children: [
                    _buildNavTile(
                      icon: Icons.add_circle_outline,
                      iconColor: AppConstants.primaryColor,
                      title: 'add_new_place'.tr(context),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('coming_soon'.tr(context))),
                        );
                      },
                    ),
                    const Divider(height: 0.5, indent: 56, endIndent: 0),
                    _buildNavTile(
                      icon: Icons.bookmark_outline,
                      iconColor: AppConstants.primaryColor,
                      title: 'saved_locations'.tr(context),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SavedLocationsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],

              // Profile management section (logged-in only)
              if (_isLoggedIn) ...[
                _buildSectionHeader('profile'.tr(context)),
                _buildGroupedContainer(
                  children: [
                    _buildNavTile(
                      icon: _isResettingPassword ? Icons.hourglass_top : Icons.key_outlined,
                      iconColor: Colors.blue,
                      title: _isResettingPassword ? '${'change_password'.tr(context)}...' : 'change_password'.tr(context),
                      onTap: _isResettingPassword ? null : () async {
                        final email = _auth.currentUser?.email;
                        if (email != null && email.isNotEmpty) {
                          setState(() => _isResettingPassword = true);
                          try {
                            await _auth.sendPasswordResetEmail(email: email);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('reset_email_sent'.tr(context)),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('reset_failed'.tr(context)),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isResettingPassword = false);
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],

              // Language section
              _buildLanguageSection(),

              // Legal section
              _buildSectionHeader('legal'.tr(context)),
              _buildGroupedContainer(
                children: [
                  _buildNavTile(
                    icon: Icons.description_outlined,
                    iconColor: AppConstants.primaryColor,
                    title: 'terms_of_use'.tr(context),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TermsOfUseScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 0.5, indent: 56, endIndent: 0),
                  _buildNavTile(
                    icon: Icons.shield_outlined,
                    iconColor: AppConstants.primaryColor,
                    title: 'privacy_policy'.tr(context),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              // Destructive actions (logged-in only)
              if (_isLoggedIn) ...[
                _buildSectionHeader('account_actions'.tr(context)),
                _buildGroupedContainer(
                  children: [
                    _buildDestructiveTile(
                      icon: Icons.logout,
                      iconColor: Colors.grey.shade600,
                      title: 'logout'.tr(context),
                      titleColor: Colors.grey.shade800,
                      onTap: () => _showLogoutConfirmation(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildGroupedContainer(
                  children: [
                    _buildDestructiveTile(
                      icon: Icons.delete_outline,
                      iconColor: Colors.red.shade600,
                      title: 'delete_account'.tr(context),
                      titleColor: Colors.red.shade600,
                      onTap: () => _showDeleteAccountConfirmation(context),
                    ),
                  ],
                ),
              ],

              // Version footer
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'WonWon v$_appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HEADER — iOS-style uppercase label
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GROUPED CONTAINER — rounded card for a group of tiles
  // ---------------------------------------------------------------------------

  Widget _buildGroupedContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE CARD — logged-in state
  // ---------------------------------------------------------------------------

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.person, color: AppConstants.primaryColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String?>(
                  future: _userNameFuture,
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? 'profile_label'.tr(context);
                    return Text(
                      name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  _userEmail ?? 'user_label'.tr(context),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SIGN-IN CARD — logged-out state
  // ---------------------------------------------------------------------------

  Widget _buildSignInCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _handleLogin,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.person_outline, color: Colors.grey.shade500, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'not_logged_in'.tr(context),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'login_to_access'.tr(context),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'login'.tr(context),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
  // NAV TILE — standard navigation row
  // ---------------------------------------------------------------------------

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DESTRUCTIVE TILE — logout / delete rows
  // ---------------------------------------------------------------------------

  Widget _buildDestructiveTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LANGUAGE SECTION
  // ---------------------------------------------------------------------------

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('language'.tr(context)),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.language, color: AppConstants.primaryColor, size: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      icon: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('english'.tr(context)),
                        ),
                        DropdownMenuItem(
                          value: 'th',
                          child: Text('thai'.tr(context)),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          AnalyticsService.safeLog(() => AnalyticsService().logLanguageChange(value));
                          setState(() {
                            _selectedLanguage = value;
                          });
                          localization.AppLocalizationsService.setLocale(value);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthGate()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DIALOGS (unchanged functionality)
  // ---------------------------------------------------------------------------

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("logout".tr(context)),
          content: Text("confirm_logout".tr(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              child: Text(
                "cancel".tr(context),
                style: TextStyle(color: Colors.grey[600]),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("logout".tr(context)),
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("delete_account".tr(context)),
          content: Text("confirm_delete".tr(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              child: Text(
                "cancel".tr(context),
                style: TextStyle(color: Colors.grey[600]),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("delete".tr(context)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performAccountDeletion();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performAccountDeletion() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete saved shops subcollection
      final savedShops = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedShops')
          .get();
      for (final doc in savedShops.docs) {
        await doc.reference.delete();
      }

      // Delete repair records subcollection
      final repairRecords = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('repairRecords')
          .get();
      for (final doc in repairRecords.docs) {
        await doc.reference.delete();
      }

      // Delete the Firebase Auth account
      await user.delete();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('account_deleted_success'.tr(context)),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthGate()),
        (route) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        // User needs to re-authenticate before deleting
        messenger.showSnackBar(
          SnackBar(
            content: Text('reauth_required'.tr(context)),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('delete_account_failed'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('delete_account_failed'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS (unchanged functionality)
  // ---------------------------------------------------------------------------

}
