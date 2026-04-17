import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/models/user.dart';
import 'package:wonwonw2/services/user_service.dart';
import 'package:intl/intl.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wonwonw2/widgets/performance_loading_widget.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({Key? key}) : super(key: key);

  @override
  _AdminManageUsersScreenState createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.users,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  'admin_manage_users'.tr(context),
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkColor,
                  ),
                ),
                const Spacer(),
                // Refresh button
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Force rebuild
                    });
                  },
                  icon: Icon(Icons.refresh, color: AppConstants.primaryColor),
                  tooltip: 'refresh'.tr(context),
                ),
              ],
            ),
          ),

          // Search and controls
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'admin_search_users'.tr(context),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Count is derived from the single stream below
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return PerformanceLoadingWidget(
                    message: 'admin_loading_users'.tr(context),
                    size: 50,
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(context);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Process users with deduplication
                final Map<String, User> uniqueUsers = {};
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  // Handle legacy admin field - if admin is true, set accountType to admin
                  if (data['admin'] == true) {
                    data['accountType'] = 'admin';
                  } else if (data['accountType'] == null) {
                    data['accountType'] = 'user';
                  }

                  // Ensure status field exists
                  if (data['status'] == null) {
                    data['status'] = 'active';
                  }

                  // Handle createdAt field - convert Timestamp to String if needed
                  if (data['createdAt'] == null) {
                    data['createdAt'] = DateTime.now().toIso8601String();
                  } else if (data['createdAt'] is Timestamp) {
                    // Convert Firestore Timestamp to ISO string
                    data['createdAt'] =
                        (data['createdAt'] as Timestamp)
                            .toDate()
                            .toIso8601String();
                  }

                  // Ensure acceptedTerms and acceptedPrivacy exist
                  if (data['acceptedTerms'] == null) {
                    data['acceptedTerms'] = false;
                  }
                  if (data['acceptedPrivacy'] == null) {
                    data['acceptedPrivacy'] = false;
                  }

                  final user = User.fromMap(data, doc.id);

                  // Deduplicate by ID
                  if (!uniqueUsers.containsKey(user.id)) {
                    uniqueUsers[user.id] = user;
                  }
                }

                final allUsers = uniqueUsers.values.toList();
                appLog('Total unique users: ${allUsers.length}');

                // Apply search filter
                final filteredUsers =
                    _searchQuery.isEmpty
                        ? allUsers
                        : allUsers.where((user) {
                          final query = _searchQuery.toLowerCase();
                          return user.name.toLowerCase().contains(query) ||
                              user.email.toLowerCase().contains(query) ||
                              user.accountType.toLowerCase().contains(query);
                        }).toList();

                // Apply sorting
                filteredUsers.sort((a, b) {
                  int comparison = 0;
                  switch (_sortBy) {
                    case 'name':
                      comparison = a.name.compareTo(b.name);
                      break;
                    case 'email':
                      comparison = a.email.compareTo(b.email);
                      break;
                    case 'role':
                      comparison = a.accountType.compareTo(b.accountType);
                      break;
                    case 'createdAt':
                      comparison = a.createdAt.compareTo(b.createdAt);
                      break;
                    default:
                      comparison = a.name.compareTo(b.name);
                  }
                  return _sortAscending ? comparison : -comparison;
                });

                appLog('Filtered and sorted users: ${filteredUsers.length}');

                return _buildUsersTable(context, filteredUsers);
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'admin_error_loading_users'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Force rebuild
              });
            },
            child: Text('try_again'.tr(context)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'admin_no_users_found'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'admin_no_users_registered'.tr(context),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(BuildContext context, List<User> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 800;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: isLargeScreen ? 32 : (isMediumScreen ? 24 : 16),
              horizontalMargin: isLargeScreen ? 24 : 16,
              columns: [
                _buildSortableColumn(context, 'admin_label_name', 'name'),
                _buildSortableColumn(context, 'email', 'email'),
                _buildSortableColumn(context, 'admin_role', 'role'),
                if (isMediumScreen) _buildSortableColumn(context, 'status_label', 'status'),
                if (isLargeScreen) _buildSortableColumn(context, 'admin_created', 'createdAt'),
                DataColumn(label: Text('admin_actions'.tr(context))),
              ],
              rows:
                  users
                      .map(
                        (user) =>
                            _buildUserRow(context, user, isLargeScreen, isMediumScreen),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }

  DataColumn _buildSortableColumn(BuildContext context, String labelKey, String sortKey) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(labelKey.tr(context)),
          if (_sortBy == sortKey)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: AppConstants.primaryColor,
            ),
        ],
      ),
      onSort: (columnIndex, ascending) {
        setState(() {
          if (_sortBy == sortKey) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = sortKey;
            _sortAscending = true;
          }
        });
      },
    );
  }

  DataRow _buildUserRow(BuildContext context, User user, bool isLargeScreen, bool isMediumScreen) {
    final cells = <DataCell>[];

    // Name column
    cells.add(
      DataCell(
        Text(
          user.name,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
      ),
    );

    // Email column
    cells.add(
      DataCell(
        SizedBox(
          width: isLargeScreen ? 200 : (isMediumScreen ? 150 : 120),
          child: Text(
            user.email,
            style: GoogleFonts.montserrat(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    // Role column
    cells.add(
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(user.accountType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.accountType.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(user.accountType),
            ),
          ),
        ),
      ),
    );

    // Status column (only on medium+ screens)
    if (isMediumScreen) {
      cells.add(
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(user.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusDisplayKey(user.status).tr(context),
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(user.status),
              ),
            ),
          ),
        ),
      );
    }

    // Created date column (only on large screens)
    if (isLargeScreen) {
      cells.add(
        DataCell(
          Text(
            DateFormat('MMM dd, yyyy').format(user.createdAt),
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
        ),
      );
    }

    // Actions column
    cells.add(
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _viewUserDetails(context, user),
              icon: const Icon(Icons.visibility, size: 16),
              tooltip: 'admin_view_details'.tr(context),
            ),
            IconButton(
              onPressed: () => _editUser(context, user),
              icon: const Icon(Icons.edit, size: 16),
              tooltip: 'admin_edit_user'.tr(context),
            ),
            IconButton(
              onPressed: () => _deleteUser(context, user),
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              tooltip: 'admin_delete_user'.tr(context),
            ),
          ],
        ),
      ),
    );

    return DataRow(key: ValueKey(user.id), cells: cells);
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayKey(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'admin_role_admin';
      case 'moderator':
        return 'admin_role_moderator';
      case 'user':
        return 'admin_role_user';
      default:
        return 'admin_role_user';
    }
  }

  String _getStatusDisplayKey(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'admin_status_active';
      case 'suspended':
        return 'admin_status_suspended';
      case 'pending':
        return 'admin_status_pending';
      default:
        return 'admin_status_active';
    }
  }

  void _viewUserDetails(BuildContext context, User user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('admin_user_details_title'.tr(context).replaceAll('{name}', user.name)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('admin_email_label'.tr(context).replaceAll('{value}', user.email)),
                Text('admin_role_label'.tr(context).replaceAll('{value}', _getRoleDisplayKey(user.accountType).tr(context))),
                Text('admin_status_label'.tr(context).replaceAll('{value}', _getStatusDisplayKey(user.status).tr(context))),
                Text(
                  'admin_created_label'.tr(context).replaceAll('{value}', DateFormat('MMM dd, yyyy HH:mm').format(user.createdAt)),
                ),
                Text('admin_terms_accepted'.tr(context).replaceAll('{value}', (user.acceptedTerms ? 'yes_label' : 'no_label').tr(context))),
                Text(
                  'admin_privacy_accepted'.tr(context).replaceAll('{value}', (user.acceptedPrivacy ? 'yes_label' : 'no_label').tr(context)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('admin_close'.tr(context)),
              ),
            ],
          ),
    );
  }

  void _editUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('admin_edit_user_title'.tr(context).replaceAll('{name}', user.name)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: user.accountType,
                  decoration: InputDecoration(labelText: 'admin_role'.tr(context)),
                  items:
                      ['user', 'moderator', 'admin']
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(_getRoleDisplayKey(role).tr(context)),
                            ),
                          )
                          .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      final success = await UserService.updateUserAccountType(
                        user.id,
                        value,
                      );
                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('admin_role_updated'.tr(context).replaceAll('{value}', _getRoleDisplayKey(value).tr(context)),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: user.status,
                  decoration: InputDecoration(labelText: 'admin_status'.tr(context)),
                  items:
                      ['active', 'suspended', 'pending']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(_getStatusDisplayKey(status).tr(context)),
                            ),
                          )
                          .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      final success = await UserService.updateUserStatus(
                        user.id,
                        value,
                      );
                      if (success) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('admin_status_updated'.tr(context).replaceAll('{value}', _getStatusDisplayKey(value).tr(context)),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr(context)),
              ),
            ],
          ),
    );
  }

  void _deleteUser(BuildContext context, User user) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('admin_delete_user'.tr(context)),
            content: Text('admin_confirm_delete_user'.tr(context).replaceAll('{name}', user.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await _firestore.collection('users').doc(user.id).delete();
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text('user_deleted_success'.tr(this.context).replaceAll('{name}', user.name))),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('error_deleting_user'.tr(this.context).replaceAll('{error}', e.toString())),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('delete'.tr(context)),
              ),
            ],
          ),
    );
  }
}
