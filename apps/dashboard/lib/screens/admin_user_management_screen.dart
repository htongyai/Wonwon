import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_dashboard/widgets/optimized_screen.dart';
import 'package:shared/models/user.dart';
import 'package:shared/services/user_service.dart';
import 'package:shared/services/version_service.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:intl/intl.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class AdminUserManagementScreen extends OptimizedScreen {
  const AdminUserManagementScreen({Key? key}) : super(key: key);

  @override
  OptimizedLoadingScreen<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState
    extends OptimizedLoadingScreen<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  String _sortBy = 'name';
  bool _sortAscending = true;

  Set<String> _selectedUserIds = <String>{};
  Map<String, DateTime> _userLastActiveMap = <String, DateTime>{};
  Map<String, String> _userAppVersionMap = <String, String>{};

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'user_management_label'.tr(context),
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showBulkActionsDialog,
                    icon: const FaIcon(FontAwesomeIcons.tasks, size: 14),
                    label: Text('bulk_actions'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'total_users_count'.tr(context).replaceAll('{count}', count.toString()),
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppConstants.primaryColor),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filters and Search
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    onChanged: (value) { safeSetState(() { _searchQuery = value; }); },
                    decoration: InputDecoration(
                      hintText: 'search_users_hint'.tr(context),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isWide)
                    Row(children: [
                      Expanded(child: _buildRoleDropdown(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUserStatusDropdown(context)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildUserSortDropdown(context)),
                      const SizedBox(width: 8),
                      _buildUserSortDirection(context),
                    ])
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      SizedBox(width: constraints.maxWidth * 0.48, child: _buildRoleDropdown(context)),
                      SizedBox(width: constraints.maxWidth * 0.48, child: _buildUserStatusDropdown(context)),
                      SizedBox(width: constraints.maxWidth * 0.48, child: _buildUserSortDropdown(context)),
                      _buildUserSortDirection(context),
                    ]),
                ],
              );
            },
          ),
        ),

        // User List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('error_prefix'.tr(context).replaceAll('{error}', snapshot.error.toString())));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Process and filter users
              final Map<String, User> uniqueUsers = {};
              for (final doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;

                // Handle legacy admin field
                if (data['admin'] == true) {
                  data['accountType'] = 'admin';
                } else if (data['accountType'] == null) {
                  data['accountType'] = 'user';
                }

                // Ensure status field exists
                if (data['status'] == null) {
                  data['status'] = 'active';
                }

                // Handle createdAt field
                if (data['createdAt'] == null) {
                  data['createdAt'] = DateTime.now().toIso8601String();
                } else if (data['createdAt'] is Timestamp) {
                  data['createdAt'] =
                      (data['createdAt'] as Timestamp)
                          .toDate()
                          .toIso8601String();
                }

                // Handle lastActiveAt field for display
                DateTime? lastActiveAt;
                if (data['lastActiveAt'] is Timestamp) {
                  lastActiveAt = (data['lastActiveAt'] as Timestamp).toDate();
                } else if (data['lastLoginAt'] is Timestamp) {
                  lastActiveAt = (data['lastLoginAt'] as Timestamp).toDate();
                }

                // Ensure required fields exist
                if (data['acceptedTerms'] == null)
                  data['acceptedTerms'] = false;
                if (data['acceptedPrivacy'] == null)
                  data['acceptedPrivacy'] = false;

                final user = User.fromMap(data, doc.id);

                // Store lastActiveAt in a separate map for display
                if (lastActiveAt != null) {
                  _userLastActiveMap[user.id] = lastActiveAt;
                }

                // Store app version information
                final appVersion = data['appVersion'] ?? data['fullAppVersion'];
                if (appVersion != null) {
                  _userAppVersionMap[user.id] = appVersion.toString();
                }

                // Deduplicate by ID
                if (!uniqueUsers.containsKey(user.id)) {
                  uniqueUsers[user.id] = user;
                }
              }

              final allUsers = uniqueUsers.values.toList();
              final filteredUsers = _filterUsers(allUsers);
              _sortUsers(filteredUsers);

              return _buildUsersList(filteredUsers);
            },
          ),
        ),
      ],
    );
  }

  List<User> _filterUsers(List<User> users) {
    return users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!user.name.toLowerCase().contains(query) &&
            !user.email.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Role filter
      if (_roleFilter != 'all') {
        if (user.accountType != _roleFilter) return false;
      }

      // Status filter
      if (_statusFilter != 'all') {
        if (user.status != _statusFilter) return false;
      }

      return true;
    }).toList();
  }

  void _sortUsers(List<User> users) {
    users.sort((a, b) {
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
        case 'lastActive':
          final aLastActive = _userLastActiveMap[a.id];
          final bLastActive = _userLastActiveMap[b.id];
          if (aLastActive != null && bLastActive != null) {
            comparison = aLastActive.compareTo(bLastActive);
          } else if (aLastActive != null) {
            comparison = -1; // a has last active, b doesn't
          } else if (bLastActive != null) {
            comparison = 1; // b has last active, a doesn't
          } else {
            comparison = 0; // neither has last active
          }
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.users, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_users_found_title'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'no_users_match_filters_msg'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index]),
    );
  }

  Widget _buildRoleDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _roleFilter,
      decoration: InputDecoration(labelText: 'role_label'.tr(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white),
      items: [
        DropdownMenuItem(value: 'all', child: Text('all_roles'.tr(context))),
        DropdownMenuItem(value: 'user', child: Text('user_role'.tr(context))),
        DropdownMenuItem(value: 'shop_owner', child: Text('shop_owner_role'.tr(context))),
        DropdownMenuItem(value: 'admin', child: Text('admin_role_label'.tr(context))),
        DropdownMenuItem(value: 'moderator', child: Text('moderator_role'.tr(context))),
      ],
      onChanged: (value) { safeSetState(() { _roleFilter = value!; }); },
    );
  }

  Widget _buildUserStatusDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _statusFilter,
      decoration: InputDecoration(labelText: 'admin_status'.tr(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white),
      items: [
        DropdownMenuItem(value: 'all', child: Text('all_status'.tr(context))),
        DropdownMenuItem(value: 'active', child: Text('active_status'.tr(context))),
        DropdownMenuItem(value: 'suspended', child: Text('suspended_status'.tr(context))),
        DropdownMenuItem(value: 'pending', child: Text('pending_status_label'.tr(context))),
      ],
      onChanged: (value) { safeSetState(() { _statusFilter = value!; }); },
    );
  }

  Widget _buildUserSortDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      decoration: InputDecoration(labelText: 'sort_by_label'.tr(context), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), filled: true, fillColor: Colors.white),
      items: [
        DropdownMenuItem(value: 'name', child: Text('name_sort'.tr(context))),
        DropdownMenuItem(value: 'email', child: Text('email_sort'.tr(context))),
        DropdownMenuItem(value: 'role', child: Text('role_sort'.tr(context))),
        DropdownMenuItem(value: 'createdAt', child: Text('join_date_sort'.tr(context))),
        DropdownMenuItem(value: 'lastActive', child: Text('last_active_sort'.tr(context))),
      ],
      onChanged: (value) { safeSetState(() { _sortBy = value!; }); },
    );
  }

  Widget _buildUserSortDirection(BuildContext context) {
    return IconButton(
      onPressed: () { safeSetState(() { _sortAscending = !_sortAscending; }); },
      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF64748B)),
      tooltip: _sortAscending ? 'sort_ascending_label'.tr(context) : 'sort_descending_label'.tr(context),
      style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE2E8F0))),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Selection Checkbox
            Checkbox(
              value: _selectedUserIds.contains(user.id),
              onChanged: (selected) {
                safeSetState(() {
                  if (selected == true) {
                    _selectedUserIds.add(user.id);
                  } else {
                    _selectedUserIds.remove(user.id);
                  }
                });
              },
            ),
            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(user.accountType).withValues(alpha: 0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(user.accountType),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(
                            user.accountType,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.accountType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(user.accountType),
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
                          color: _getStatusColor(user.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(user.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (_userLastActiveMap.containsKey(user.id)) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: _getActiveStatusColor(
                            _userLastActiveMap[user.id]!,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'last_active_prefix'.tr(context).replaceAll('{time}', _formatLastActiveTime(_userLastActiveMap[user.id]!)),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getActiveStatusColor(
                              _userLastActiveMap[user.id]!,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_userAppVersionMap.containsKey(user.id)) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 12,
                          color: _getVersionStatusColor(
                            _userAppVersionMap[user.id]!,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'app_version_prefix'.tr(context).replaceAll('{version}', _userAppVersionMap[user.id]!),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _getVersionStatusColor(
                              _userAppVersionMap[user.id]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        FutureBuilder<String>(
                          future: VersionService().getVersionStatus(
                            _userAppVersionMap[user.id]!,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final status = snapshot.data!;
                              if (status == 'outdated') {
                                return Icon(
                                  Icons.warning,
                                  size: 12,
                                  color: Colors.orange,
                                );
                              } else if (status == 'latest') {
                                return Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.green,
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'joined_date_prefix'.tr(context).replaceAll('{date}', DateFormat('MMM dd, yyyy').format(user.createdAt)),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      if (_userLastActiveMap.containsKey(user.id)) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getActiveStatusColor(
                              _userLastActiveMap[user.id]!,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 10,
                                color: _getActiveStatusColor(
                                  _userLastActiveMap[user.id]!,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'last_active_prefix'.tr(context).replaceAll('{time}', _formatLastActiveTime(_userLastActiveMap[user.id]!)),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _getActiveStatusColor(
                                    _userLastActiveMap[user.id]!,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewUserDetails(user),
                  icon: const FaIcon(FontAwesomeIcons.eye, size: 16),
                  tooltip: 'view_details_tooltip'.tr(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _editUser(user),
                  icon: const FaIcon(FontAwesomeIcons.userEdit, size: 16),
                  tooltip: 'edit_user_action'.tr(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                if (user.status == 'active')
                  IconButton(
                    onPressed: () => _suspendUser(user),
                    icon: const FaIcon(FontAwesomeIcons.userSlash, size: 16),
                    tooltip: 'suspend_user_action'.tr(context),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => _activateUser(user),
                    icon: const FaIcon(FontAwesomeIcons.userCheck, size: 16),
                    tooltip: 'activate_user_action'.tr(context),
                    style: IconButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor.withValues(alpha: 
                        0.1,
                      ),
                      foregroundColor: AppConstants.primaryColor,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteUser(user),
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                  tooltip: 'delete_user_action'.tr(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'moderator':
        return const Color(0xFFF59E0B);
      case 'shop_owner':
        return const Color(0xFF8B5CF6);
      case 'user':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'suspended':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _viewUserDetails(User user) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: min(500, MediaQuery.of(context).size.width * 0.95),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'user_details_title'.tr(context),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('admin_label_name'.tr(context), user.name),
                  _buildDetailRow('email'.tr(context), user.email),
                  _buildDetailRow('role_label'.tr(context), user.accountType.toUpperCase()),
                  _buildDetailRow('admin_status'.tr(context), user.status.toUpperCase()),
                  _buildDetailRow(
                    'joined_detail'.tr(context),
                    DateFormat('MMM dd, yyyy HH:mm').format(user.createdAt),
                  ),
                  _buildDetailRow(
                    'terms_accepted_detail'.tr(context),
                    user.acceptedTerms ? 'yes'.tr(context) : 'no'.tr(context),
                  ),
                  _buildDetailRow(
                    'privacy_accepted_detail'.tr(context),
                    user.acceptedPrivacy ? 'yes'.tr(context) : 'no'.tr(context),
                  ),
                  if (user.lastLoginAt != null)
                    _buildDetailRow(
                      'last_login_detail'.tr(context),
                      DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format(user.lastLoginAt!),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('close_button'.tr(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(User user) {
    String selectedRole = user.accountType;
    String selectedStatus = user.status;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('edit_user_dialog'.tr(context).replaceAll('{name}', user.name)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(labelText: 'role_label'.tr(context)),
                        items: [
                          DropdownMenuItem(value: 'user', child: Text('user_role'.tr(context))),
                          DropdownMenuItem(
                            value: 'shop_owner',
                            child: Text('shop_owner_role'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'moderator',
                            child: Text('moderator_role'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('admin_role_label'.tr(context)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(labelText: 'admin_status'.tr(context)),
                        items: [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('active_status'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text('suspended_status'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('pending_status_label'.tr(context)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr(context)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _updateUser(user, selectedRole, selectedStatus);
                      },
                      child: Text('save_button'.tr(context)),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _updateUser(User user, String role, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    setLoading(true, message: 'updating_user'.tr(context));

    try {
      if (role != user.accountType) {
        await UserService.updateUserAccountType(user.id, role);
      }

      if (status != user.status) {
        await UserService.updateUserStatus(user.id, status);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('user_updated_msg'.tr(context).replaceAll('{name}', user.name)),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('error_updating_user'.tr(context).replaceAll('{error}', e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoading(false);
    }
  }

  void _suspendUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('suspend_user_dialog'.tr(context)),
            content: Text('confirm_suspend_user'.tr(context).replaceAll('{name}', user.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('suspend_button'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _updateUser(user, user.accountType, 'suspended');
    }
  }

  void _activateUser(User user) async {
    await _updateUser(user, user.accountType, 'active');
  }

  void _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('delete_user_dialog'.tr(context)),
            content: Text(
              'confirm_delete_user_action'.tr(context).replaceAll('{name}', user.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('delete'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      setLoading(true, message: 'deleting_user'.tr(context));

      try {
        final success = await UserService.deleteUser(user.id);

        if (!mounted) return;
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('user_deleted_success'.tr(context).replaceAll('{name}', user.name)),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to delete user');
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('error_deleting_user'.tr(context).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  void _showBulkActionsDialog() {
    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('select_users_for_bulk'.tr(context)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'bulk_actions_selected'.tr(context).replaceAll('{count}', _selectedUserIds.length.toString()),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('activate_all_selected'.tr(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkActivateUsers();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.orange),
                  title: Text('suspend_all_selected'.tr(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkSuspendUsers();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.blue,
                  ),
                  title: Text('change_role'.tr(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showBulkRoleChangeDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('delete_all_selected'.tr(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkDeleteUsers();
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

  void _showBulkRoleChangeDialog() {
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    'change_role_for'.tr(context).replaceAll('{count}', _selectedUserIds.length.toString()),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('select_new_role'.tr(context)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'new_role'.tr(context),
                        ),
                        items: [
                          DropdownMenuItem(value: 'user', child: Text('user_role'.tr(context))),
                          DropdownMenuItem(
                            value: 'shop_owner',
                            child: Text('shop_owner_role'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'moderator',
                            child: Text('moderator_role'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('admin_role_label'.tr(context)),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr(context)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _bulkChangeRole(selectedRole);
                      },
                      child: Text('change_role_button'.tr(context)),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _bulkActivateUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('bulk_activate_users'.tr(context)),
            content: Text(
              'confirm_bulk_activate'.tr(context).replaceAll('{count}', _selectedUserIds.length.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('activate_all'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      setLoading(true, message: 'activating_users'.tr(context));
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            await UserService.updateUserStatus(userId, 'active');
            successCount++;
          } catch (e) {
            appLog('Error activating user $userId: $e');
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('users_activated_success'.tr(context).replaceAll('{count}', successCount.toString())),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('error_bulk_activation'.tr(context).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  Future<void> _bulkSuspendUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('bulk_suspend_users'.tr(context)),
            content: Text(
              'confirm_bulk_suspend'.tr(context).replaceAll('{count}', _selectedUserIds.length.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('suspend_all'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      setLoading(true, message: 'suspending_users'.tr(context));
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            await UserService.updateUserStatus(userId, 'suspended');
            successCount++;
          } catch (e) {
            appLog('Error suspending user $userId: $e');
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('users_suspended_success'.tr(context).replaceAll('{count}', successCount.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('error_bulk_suspension'.tr(context).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  Future<void> _bulkChangeRole(String newRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('bulk_change_role'.tr(context)),
            content: Text(
              'confirm_bulk_role_change'.tr(context).replaceAll('{count}', _selectedUserIds.length.toString()).replaceAll('{role}', newRole),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('change_role_button'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      setLoading(true, message: 'changing_roles'.tr(context));
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            await UserService.updateUserAccountType(userId, newRole);
            successCount++;
          } catch (e) {
            appLog('Error changing role for user $userId: $e');
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('users_role_changed'.tr(context).replaceAll('{count}', successCount.toString()).replaceAll('{role}', newRole)),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('error_bulk_role_change'.tr(context).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  Future<void> _bulkDeleteUsers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('bulk_delete_users'.tr(context)),
            content: Text(
              'confirm_bulk_delete_users'.tr(context).replaceAll('{count}', _selectedUserIds.length.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('delete_all'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      setLoading(true, message: 'deleting_users'.tr(context));
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            final success = await UserService.deleteUser(userId);
            if (success) successCount++;
          } catch (e) {
            appLog('Error deleting user $userId: $e');
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('users_deleted_success'.tr(context).replaceAll('{count}', successCount.toString())),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('error_bulk_deletion'.tr(context).replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  String _formatLastActiveTime(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'just_now'.tr(context);
    } else if (difference.inMinutes < 60) {
      return 'admin_minutes_ago'.tr(context).replaceAll('{m}', difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return 'admin_hours_ago'.tr(context).replaceAll('{h}', difference.inHours.toString());
    } else if (difference.inDays < 7) {
      return 'admin_days_ago'.tr(context).replaceAll('{d}', difference.inDays.toString());
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'admin_weeks_ago'.tr(context).replaceAll('{w}', weeks.toString());
    } else {
      return DateFormat('MMM dd').format(lastActive);
    }
  }

  Color _getActiveStatusColor(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 5) {
      return const Color(0xFF10B981); // Green - Very active
    } else if (difference.inHours < 1) {
      return const Color(0xFF3B82F6); // Blue - Recently active
    } else if (difference.inHours < 24) {
      return const Color(0xFFF59E0B); // Orange - Active today
    } else if (difference.inDays < 7) {
      return const Color(0xFF8B5CF6); // Purple - Active this week
    } else {
      return const Color(0xFF64748B); // Gray - Inactive
    }
  }

  Color _getVersionStatusColor(String userVersion) {
    // For now, return a neutral color - the actual status will be determined by the FutureBuilder
    return const Color(0xFF64748B); // Gray - neutral
  }
}
