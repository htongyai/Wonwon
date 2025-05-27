import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/saved_locations_screen.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'English'; // Default language
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSelectedLanguage();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    final email = isLoggedIn ? await _authService.getUserEmail() : null;

    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _userEmail = email;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    if (result == true) {
      _checkLoginStatus();
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userEmail = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have been logged out'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadSelectedLanguage() async {
    final locale = await AppLocalizationsService.getLocale();
    if (mounted) {
      setState(() {
        _selectedLanguage = locale.languageCode == 'en' ? 'English' : 'Thai';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Section
                        _buildSectionTitle('account'.tr(context)),
                        const SizedBox(height: 12),
                        _isLoggedIn
                            ? _buildSettingsCard(child: _buildProfileTile())
                            : _buildSettingsCard(child: _buildLoginTile()),
                        const SizedBox(height: 32),

                        // Features Section
                        _buildSectionTitle('features'.tr(context)),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          child: Column(
                            children: [
                              _buildFeatureTile(
                                'add_new_place'.tr(context),
                                FontAwesomeIcons.plus,
                                AppConstants.primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const AddShopScreen(),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              _buildFeatureTile(
                                'saved_locations'.tr(context),
                                FontAwesomeIcons.bookmark,
                                AppConstants.primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const SavedLocationsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Language Section
                        _buildSectionTitle('language'.tr(context)),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: _buildLanguageDropdown(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Legal Section
                        _buildSectionTitle('legal'.tr(context)),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          child: Column(
                            children: [
                              _buildLegalTile(
                                'terms_of_use'.tr(context),
                                FontAwesomeIcons.fileLines,
                                AppConstants.primaryColor.withOpacity(0.7),
                              ),
                              const Divider(height: 1, thickness: 0.5),
                              _buildLegalTile(
                                'privacy_policy'.tr(context),
                                FontAwesomeIcons.shieldHalved,
                                AppConstants.primaryColor.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Account Actions Section - Only show if logged in
                        if (_isLoggedIn) ...[
                          _buildSectionTitle('Account Actions'),
                          const SizedBox(height: 12),
                          _buildSettingsCard(
                            child: Column(
                              children: [
                                _buildActionTile(
                                  'logout',
                                  FontAwesomeIcons.rightFromBracket,
                                  Colors.red.shade700,
                                  onTap: () {
                                    _showLogoutConfirmation(context);
                                  },
                                ),
                                const Divider(height: 1, thickness: 0.5),
                                _buildActionTile(
                                  'delete_account',
                                  FontAwesomeIcons.trash,
                                  Colors.red.shade700,
                                  onTap: () {
                                    _showDeleteAccountConfirmation(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // App Version
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.brown,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.asset(
                                    'assets/rlogo.jpg',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'version'.tr(context) + ' 1.0.3',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppConstants.darkColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLoginTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_outline, color: Colors.white, size: 30),
      ),
      title: Text(
        'not_logged_in'.tr(context),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'login_to_access'.tr(context),
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      trailing: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text('login'.tr(context)),
      ),
      onTap: _handleLogin,
    );
  }

  Widget _buildProfileTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 30),
      ),
      title: FutureBuilder<String?>(
        future: _authService.getUserName(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Text(
              snapshot.data!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            );
          }
          return const Text(
            'Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          );
        },
      ),
      subtitle: Text(
        _userEmail ?? 'User',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      onTap: () {
        // Navigate to profile screen
      },
    );
  }

  Widget _buildLanguageDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // English language button
          Container(
            width:
                MediaQuery.of(context).size.width * 0.45 -
                40, // 45% of width minus padding
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedLanguage != 'English') {
                  setState(() {
                    _selectedLanguage = 'English';
                  });
                  await AppLocalizationsService.setLocale('en');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selectedLanguage == 'English'
                        ? Colors.brown
                        : Colors.grey.shade100,
                foregroundColor:
                    _selectedLanguage == 'English'
                        ? Colors.white
                        : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color:
                        _selectedLanguage == 'English'
                            ? Colors.brown
                            : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/flag_us.png',
                      width: 24,
                      height: 20,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.flag, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'english'.tr(context),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          _selectedLanguage == 'English'
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Thai language button
          Container(
            width:
                MediaQuery.of(context).size.width * 0.45 -
                40, // 45% of width minus padding
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedLanguage != 'Thai') {
                  setState(() {
                    _selectedLanguage = 'Thai';
                  });
                  await AppLocalizationsService.setLocale('th');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selectedLanguage == 'Thai'
                        ? Colors.brown
                        : Colors.grey.shade100,
                foregroundColor:
                    _selectedLanguage == 'Thai'
                        ? Colors.white
                        : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color:
                        _selectedLanguage == 'Thai'
                            ? Colors.brown
                            : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/images/flag_th.png',
                      width: 24,
                      height: 20,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.flag, size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'thai'.tr(context),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          _selectedLanguage == 'Thai'
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalTile(String title, IconData icon, Color iconColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: FaIcon(icon, color: iconColor, size: 16)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: () {
        // Navigate to legal screen
      },
    );
  }

  Widget _buildActionTile(
    String titleKey,
    IconData icon,
    Color iconColor, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: FaIcon(icon, color: iconColor, size: 16)),
      ),
      title: Text(
        titleKey.tr(context),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: iconColor,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFeatureTile(
    String title,
    IconData icon,
    Color iconColor, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: FaIcon(icon, color: iconColor, size: 16)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

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
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
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
                // Implement delete account logic
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
