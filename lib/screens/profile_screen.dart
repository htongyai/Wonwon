import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/models/repair_record.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _fetchAdminStatus(_user!.uid);
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
        _loading = false;
      });
      if (user != null) {
        _fetchAdminStatus(user.uid);
      } else {
        setState(() {
          _isAdmin = false;
        });
      }
    });
  }

  Future<void> _fetchAdminStatus(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _isAdmin = doc.data()?['admin'] == true;
    });
  }

  Future<List<RepairRecord>> _fetchRepairRecords() async {
    if (_user == null) return [];
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('repairRecords')
            .orderBy('date', descending: true)
            .get();
    return snapshot.docs
        .map((doc) => RepairRecord.fromMap(doc.data()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('profile'.tr(context), style: GoogleFonts.montserrat()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'please_login_to_view_profile'.tr(context),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        _user = FirebaseAuth.instance.currentUser;
                      });
                    }
                  },
                  child: Text(
                    'login'.tr(context),
                    style: GoogleFonts.montserrat(),
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppConstants.primaryColor.withOpacity(0.15),
                  child: const Icon(
                    Icons.person,
                    size: 36,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _user?.displayName ?? 'user'.tr(context),
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryTextColor,
                              ),
                            ),
                          ),
                          if (_isAdmin)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'admin'.tr(context),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _user?.email ?? '',
                              style: GoogleFonts.montserrat(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RepairRecordDetailScreen(record: record),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppConstants.primaryColor
                                .withOpacity(0.15),
                            child: const FaIcon(
                              FontAwesomeIcons.screwdriverWrench,
                              color: AppConstants.primaryColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            record.shopName,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'item_fixed'.tr(context) + ': ${record.itemFixed}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            color: Colors.white.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppConstants.primaryColor.withOpacity(
                      0.15,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.screwdriverWrench,
                      color: AppConstants.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    context,
                    Icons.store,
                    'shop_name'.tr(context),
                    record.shopName,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.build,
                    'item_fixed'.tr(context),
                    record.itemFixed,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.attach_money,
                    'price'.tr(context),
                    record.price != null ? record.price.toString() : '-',
                    isBold: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.calendar_today,
                    'date'.tr(context),
                    record.date.toLocal().toString().split(' ')[0],
                    isBold: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.timer,
                    'duration'.tr(context),
                    record.duration != null
                        ? '${record.duration!.inDays} ' + 'days'.tr(context)
                        : '-',
                    isBold: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    Icons.notes,
                    'notes'.tr(context),
                    record.notes ?? '-',
                    isBold: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppConstants.primaryTextColor,
              ),
              children: [
                TextSpan(
                  text: label + ': ',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.montserrat(
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
