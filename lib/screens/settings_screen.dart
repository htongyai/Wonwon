import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_colors.dart';
import 'package:wonwonw2/constants/app_text_styles.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/saved_locations_screen.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/screens/unapproved_shops_screen.dart';
import 'package:wonwonw2/screens/view_reports_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/app_localizations_service.dart' as service;
import 'package:wonwonw2/services/theme_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/widgets/section_title.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/models/repair_shop.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en'; // Default language code
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _userEmail;
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSelectedLanguage();
    _checkAdminStatus();
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
        SnackBar(
          content: Text('logged_out_message'.tr(context)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _loadSelectedLanguage() async {
    final languageCode = await service.AppLocalizationsService.getLocale();
    if (mounted) {
      setState(() {
        _selectedLanguage = languageCode; // 'en' or 'th'
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          _isAdmin = userDoc.data()?['admin'] ?? false;
        });
      }
    } catch (e) {
      appLog('Error checking admin status', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'settings'.tr(context),
          style: AppTextStyles.heading.copyWith(color: AppColors.text),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: ResponsiveSize.getScaledPadding(const EdgeInsets.all(16.0)),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Only show Features section if user is logged in
                if (user != null) ...[
                  SectionTitle(text: 'features'.tr(context)),
                  SizedBox(height: ResponsiveSize.getHeight(2)),
                  _buildSettingsCard(
                    child: Column(
                      children: [
                        _buildFeatureTile(
                          Icons.add,
                          'add_new_place'.tr(context),
                          onTap: () {},
                        ),
                        _buildFeatureTile(
                          Icons.bookmark_border,
                          'saved_locations'.tr(context),
                          onTap: () {},
                        ),
                        if (_isAdmin)
                          _buildFeatureTile(
                            Icons.access_time,
                            'unapproved_shops'.tr(context),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const UnapprovedShopsScreen(),
                                ),
                              );
                            },
                          ),
                        FutureBuilder<bool>(
                          future: _isAdminUser(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox.shrink();
                            }
                            if (snapshot.data == true) {
                              return Column(
                                children: [
                                  _buildFeatureTile(
                                    Icons.report_problem,
                                    'view_reports'.tr(context),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const ViewReportsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildFeatureTile(
                                    Icons.upload_file,
                                    'Import from Excel',
                                    onTap: _importShopsFromExcel,
                                  ),
                                ],
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ResponsiveSize.getHeight(2)),
                ],
                // Account Section
                SectionTitle(text: 'account'.tr(context)),
                SizedBox(height: ResponsiveSize.getHeight(2)),
                _isLoggedIn
                    ? _buildSettingsCard(child: _buildProfileTile())
                    : _buildSettingsCard(child: _buildLoginTile()),
                SizedBox(height: ResponsiveSize.getHeight(2)),

                // Language Section
                SectionTitle(text: 'language'.tr(context)),
                SizedBox(height: ResponsiveSize.getHeight(2)),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildLanguageOption(
                        context,
                        'thai'.tr(context),
                        'th',
                        'th',
                      ),
                      SizedBox(height: ResponsiveSize.getHeight(0.25)),
                      _buildLanguageOption(
                        context,
                        'english'.tr(context),
                        'en',
                        'en',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(2)),

                // Legal Section
                SectionTitle(text: 'legal'.tr(context)),
                SizedBox(height: ResponsiveSize.getHeight(2)),
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
                SizedBox(height: ResponsiveSize.getHeight(2)),

                // Account Actions Section - Only show if logged in
                if (_isLoggedIn) ...[
                  SectionTitle(text: 'account_actions'.tr(context)),
                  SizedBox(height: ResponsiveSize.getHeight(2)),
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
                  SizedBox(height: ResponsiveSize.getHeight(2)),
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
                          border: Border.all(color: Colors.brown, width: 2),
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
                      SizedBox(height: ResponsiveSize.getHeight(2)),
                      Text(
                        'version'.tr(context) + ' 1.0.3',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(2)),
              ],
            ),
          ),
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
      contentPadding: ResponsiveSize.getScaledPadding(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
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
      contentPadding: ResponsiveSize.getScaledPadding(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
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
          return Text(
            'profile_label'.tr(context),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          );
        },
      ),
      subtitle: Text(
        _userEmail ?? 'user_label'.tr(context),
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      onTap: () {
        // Navigate to profile screen
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageName,
    String languageCode,
    String selectedLanguage,
  ) {
    return ListTile(
      contentPadding: ResponsiveSize.getScaledPadding(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FaIcon(
            Icons.language,
            color: AppConstants.primaryColor,
            size: 16,
          ),
        ),
      ),
      title: Text(
        languageName,
        style: TextStyle(
          fontSize: 16,
          fontWeight:
              _selectedLanguage == languageCode
                  ? FontWeight.bold
                  : FontWeight.normal,
        ),
      ),
      trailing: Radio(
        value: languageCode,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedLanguage = value as String;
            });
            service.AppLocalizationsService.setLocale(value);
          }
        },
      ),
    );
  }

  Widget _buildLegalTile(String title, IconData icon, Color iconColor) {
    return ListTile(
      contentPadding: ResponsiveSize.getScaledPadding(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
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
      contentPadding: ResponsiveSize.getScaledPadding(
        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      ),
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
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: FaIcon(icon, color: AppConstants.primaryColor, size: 16),
        ),
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

  Future<bool> _isAdminUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return userDoc.data()?['admin'] ?? false;
  }

  Future<void> _importShopsFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;
      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) throw Exception('File could not be read');
      final excelFile = excel.Excel.decodeBytes(fileBytes);
      int importedCount = 0;

      for (final table in excelFile.tables.keys) {
        final sheet = excelFile.tables[table]!;
        if (sheet.maxRows < 2) continue; // skip if no data
        final headers =
            sheet.rows[0].map((cell) => cell?.value?.toString() ?? '').toList();
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          // Skip row if all columns are empty or whitespace
          if (row.every(
            (cell) =>
                cell == null ||
                cell.value == null ||
                cell.value.toString().trim().isEmpty,
          )) {
            continue;
          }
          final Map<String, dynamic> data = {};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            final value = row[j]?.value;
            if (value != null && value.toString().trim().isNotEmpty) {
              data[headers[j]] = value;
            }
          }
          try {
            List<String> paymentMethods = [];
            if (data['cash']?.toString().toLowerCase() == 'true')
              paymentMethods.add('cash');
            if (data['QR']?.toString().toLowerCase() == 'true')
              paymentMethods.add('qr');
            if (data['credit']?.toString().toLowerCase() == 'true')
              paymentMethods.add('card');
            Map<String, String> hours = {};
            final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
            for (final day in days) {
              final timeStr = data[day]?.toString() ?? '';
              if (timeStr.isNotEmpty) {
                hours[day] = timeStr;
              }
            }
            // Generate id using Firestore convention
            final String shopId =
                FirebaseFirestore.instance.collection('shops').doc().id;
            final shop = RepairShop(
              id: shopId,
              name: data['name']?.toString() ?? '',
              description: data['description']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              area: data['area']?.toString() ?? '',
              categories:
                  (data['categories'] is String)
                      ? (data['categories'] as String)
                          .split(',')
                          .map((e) => e.trim())
                          .toList()
                      : [],
              rating: double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
              amenities:
                  (data['amenities'] is String)
                      ? (data['amenities'] as String)
                          .split(',')
                          .map((e) => e.trim())
                          .toList()
                      : [],
              hours: hours,
              closingDays: [],
              latitude:
                  double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
              longitude:
                  double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
              durationMinutes:
                  int.tryParse(data['durationMinutes']?.toString() ?? '0') ?? 0,
              requiresPurchase:
                  (data['requiresPurchase']?.toString().toLowerCase() ==
                      'true'),
              photos: [],
              priceRange: data['priceRange']?.toString() ?? '₿',
              features: {},
              approved:
                  (data['isapproved']?.toString().toLowerCase() == 'true'),
              irregularHours: false,
              subServices: {},
              buildingNumber: data['buildingNumber']?.toString(),
              buildingName: data['buildingName']?.toString(),
              soi: data['soi']?.toString(),
              district: data['district']?.toString(),
              province: data['province']?.toString(),
              landmark: data['landmark']?.toString(),
              lineId: data['lineId']?.toString(),
              facebookPage: data['facebookPage']?.toString(),
              otherContacts: data['otherContacts']?.toString(),
              paymentMethods: paymentMethods.isNotEmpty ? paymentMethods : null,
              tryOnAreaAvailable:
                  (data['tryOnAreaAvailable']?.toString().toLowerCase() ==
                      'true'),
              notesOrConditions: data['notesOrConditions']?.toString(),
              usualOpeningTime: data['usualOpeningTime']?.toString(),
              usualClosingTime: data['usualClosingTime']?.toString(),
              instagramPage: data['instagramPage']?.toString(),
              phoneNumber: data['phoneNumber']?.toString(),
              buildingFloor: data['buildingFloor']?.toString(),
            );
            await ShopService().addShop(shop);
            importedCount++;
          } catch (e) {
            print('Error processing row $i: $e');
          }
        }
      }
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Import Complete'),
              content: Text('Successfully imported $importedCount shops.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Import Failed'),
              content: Text('Error: ' + e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }
}
