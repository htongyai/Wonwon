import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_colors.dart';
import 'package:wonwonw2/constants/app_text_styles.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/saved_locations_screen.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/screens/unapproved_shops_screen.dart';
import 'package:wonwonw2/screens/view_reports_screen.dart';
import 'package:wonwonw2/screens/users_list_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/user_service.dart';
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
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadSelectedLanguage();
    _checkAdminStatus();
    _loadAppVersion();
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

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
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
                                    Icons.people,
                                    'Users List',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const UsersListScreen(),
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
                _buildLanguageSection(),

                // Profile Section - Only show if logged in
                if (_isLoggedIn) ...[_buildProfileSection()],

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
                        '${'version'.tr(context)} $_appVersion',
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

  Widget _buildLanguageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(text: 'language'.tr(context)),
        SizedBox(height: ResponsiveSize.getHeight(2)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text('english'.tr(context)),
                ),
                DropdownMenuItem(value: 'th', child: Text('thai'.tr(context))),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  service.AppLocalizationsService.setLocale(value);
                  // Refresh the app
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
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
    final userService = UserService();
    return await userService.isCurrentUserAdmin();
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
      int failedCount = 0;
      List<String> failedRows = [];

      for (final table in excelFile.tables.keys) {
        final sheet = excelFile.tables[table]!;
        if (sheet.maxRows < 2) continue; // skip if no data

        // Get headers and validate required columns
        final headers =
            sheet.rows[0]
                .map(
                  (cell) => cell?.value?.toString().trim().toLowerCase() ?? '',
                )
                .toList();
        final requiredColumns = [
          'name',
          'description',
          'address',
          'area',
          'categories',
          'latitude',
          'longitude',
          'rating',
          'amenities',
          'durationminutes',
          'requirespurchase',
          'pricerange',
          'buildingnumber',
          'buildingname',
          'soi',
          'district',
          'province',
          'landmark',
          'lineid',
          'facebookpage',
          'othercontacts',
          'cash',
          'qr',
          'credit',
          'mon',
          'tue',
          'wed',
          'thu',
          'fri',
          'sat',
          'sun',
          'instagrampage',
          'phonenumber',
          'buildingfloor',
          'isapproved',
          'verification_status',
          'image_url',
          'paymentmethods',
          'tryonareaavailable',
          'notesorconditions',
          'usualopeningtime',
          'gmap link',
          'note',
        ];

        // Validate headers
        final missingColumns =
            requiredColumns
                .where((col) => !headers.contains(col.toLowerCase()))
                .toList();
        if (missingColumns.isNotEmpty) {
          final foundHeaders = headers.where((h) => h.isNotEmpty).join(', ');
          throw Exception(
            'Missing required columns: ${missingColumns.join(", ")}\n\nFound headers in file: $foundHeaders',
          );
        }

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

          try {
            final Map<String, dynamic> data = {};
            for (int j = 0; j < headers.length && j < row.length; j++) {
              final value = row[j]?.value;
              if (value != null && value.toString().trim().isNotEmpty) {
                data[headers[j]] = value;
              }
            }

            // Process opening hours
            Map<String, String> hours = {};
            final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
            for (final day in days) {
              final timeStr = data[day]?.toString().trim() ?? '';
              if (timeStr.isEmpty || timeStr.toLowerCase() == 'closed') {
                hours[day] = 'Closed';
              } else {
                // Convert periods to colons
                final normalized = timeStr.replaceAll('.', ':');
                final parts = normalized.split('-');
                if (parts.length == 2) {
                  final openingTime = parts[0].trim();
                  final closingTime = parts[1].trim();
                  hours[day] = '$openingTime - $closingTime';
                } else {
                  hours[day] = 'Closed';
                }
              }
            }

            // Process payment methods - check both individual columns and combined column
            List<String> paymentMethods = [];

            // Check individual payment method columns
            if (data['cash']?.toString().toLowerCase() == 'true') {
              paymentMethods.add('cash');
            }
            if (data['qr']?.toString().toLowerCase() == 'true') {
              paymentMethods.add('qr');
            }
            if (data['credit']?.toString().toLowerCase() == 'true') {
              paymentMethods.add('card');
            }

            // If no individual methods found, try the combined column
            if (paymentMethods.isEmpty && data['paymentmethods'] != null) {
              paymentMethods =
                  data['paymentmethods']
                      .toString()
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
            }

            // Generate a unique ID for the shop
            final shopId = const Uuid().v4();

            // Get verification status from Excel or verify coordinates
            String verificationStatus =
                data['verification_status']?.toString() ?? '';
            if (verificationStatus.isEmpty) {
              final lat =
                  double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
              final lng =
                  double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;
              verificationStatus = _verifyGeocoding(
                lat,
                lng,
                data['address']?.toString() ?? '',
              );
            }

            // Process image URL
            String? imageUrl = data['image_url']?.toString();
            if (imageUrl == null || imageUrl.trim().isEmpty) {
              imageUrl = null;
            }

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
                  int.tryParse(data['durationminutes']?.toString() ?? '0') ?? 0,
              requiresPurchase:
                  (data['requirespurchase']?.toString().toLowerCase() ==
                      'true'),
              photos: imageUrl != null ? [imageUrl] : [],
              priceRange: data['pricerange']?.toString() ?? '₿',
              features: {},
              approved:
                  (data['isapproved']?.toString().toLowerCase() == 'true'),
              irregularHours: false,
              subServices: {},
              buildingNumber: data['buildingnumber']?.toString(),
              buildingName: data['buildingname']?.toString(),
              soi: data['soi']?.toString(),
              district: data['district']?.toString(),
              province: data['province']?.toString(),
              landmark: data['landmark']?.toString(),
              lineId: data['lineid']?.toString(),
              facebookPage: data['facebookpage']?.toString(),
              otherContacts: data['othercontacts']?.toString(),
              paymentMethods: paymentMethods.isNotEmpty ? paymentMethods : null,
              tryOnAreaAvailable:
                  (data['tryonareaavailable']?.toString().toLowerCase() ==
                      'true'),
              notesOrConditions: data['notesorconditions']?.toString(),
              usualOpeningTime: data['usualopeningtime']?.toString(),
              instagramPage: data['instagrampage']?.toString(),
              phoneNumber: data['phonenumber']?.toString(),
              buildingFloor: data['buildingfloor']?.toString(),
            );

            // Add to Firestore with verification status and additional data
            await FirebaseFirestore.instance
                .collection('shops')
                .doc(shopId)
                .set({
                  ...shop.toMap(),
                  'verification_status': verificationStatus,
                  'gMap_link': data['gmap link']?.toString(),
                  'note': data['note']?.toString(),
                });

            importedCount++;
          } catch (e) {
            failedCount++;
            failedRows.add('Row ${i + 1}: ${e.toString()}');
          }
        }
      }

      // Show import results
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Import Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Successfully imported $importedCount shops.'),
                  if (failedCount > 0) ...[
                    const SizedBox(height: 8),
                    Text('Failed to import $failedCount shops:'),
                    const SizedBox(height: 4),
                    ...failedRows.map(
                      (error) => Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
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
              content: Text('Error: ${e.toString()}'),
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

  String _verifyGeocoding(double lat, double lng, String address) {
    // Basic validation of coordinates
    if (lat == 0.0 && lng == 0.0) {
      return 'Invalid coordinates';
    }

    // Check if coordinates are within reasonable bounds (Thailand)
    if (lat < 5.0 || lat > 20.0 || lng < 97.0 || lng > 106.0) {
      return 'Coordinates outside Thailand';
    }

    // If we have both coordinates and address, mark as verified
    if (address.isNotEmpty) {
      return 'Verified (Simulated)';
    }

    return 'Unverified';
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(text: 'profile'.tr(context)),
        SizedBox(height: ResponsiveSize.getHeight(2)),
        _buildSettingsCard(
          child: Column(
            children: [
              _buildProfileTile(),
              const Divider(height: 1, thickness: 0.5),
              _buildActionTile(
                'change_password',
                FontAwesomeIcons.key,
                Colors.blue,
                onTap: () {
                  // Navigate to change password screen
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
