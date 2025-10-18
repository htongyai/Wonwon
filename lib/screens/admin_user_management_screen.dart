import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/widgets/optimized_screen.dart';
import 'package:wonwonw2/models/user.dart';
import 'package:wonwonw2/services/user_service.dart';
import 'package:wonwonw2/services/version_service.dart';
import 'package:intl/intl.dart';

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
          child: Row(
            children: [
              Text(
                'User Management',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showBulkActionsDialog,
                    icon: const FaIcon(FontAwesomeIcons.tasks, size: 16),
                    label: const Text('Bulk Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      final count =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count Total Users',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.primaryColor,
                          ),
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
          child: Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) {
                    safeSetState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Role Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _roleFilter,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Roles')),
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(
                      value: 'shop_owner',
                      child: Text('Shop Owner'),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'moderator',
                      child: Text('Moderator'),
                    ),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _roleFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'suspended',
                      child: Text('Suspended'),
                    ),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _statusFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Sort By
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'role', child: Text('Role')),
                    DropdownMenuItem(
                      value: 'createdAt',
                      child: Text('Join Date'),
                    ),
                    DropdownMenuItem(
                      value: 'lastActive',
                      child: Text('Last Active'),
                    ),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Sort Direction
              IconButton(
                onPressed: () {
                  safeSetState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: const Color(0xFF64748B),
                ),
                tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ],
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
                return Center(child: Text('Error: ${snapshot.error}'));
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
            'No users found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No users match your current filters',
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

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              backgroundColor: _getRoleColor(user.accountType).withOpacity(0.1),
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
                          ).withOpacity(0.1),
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
                          color: _getStatusColor(user.status).withOpacity(0.1),
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
                          'Last active ${_formatLastActiveTime(_userLastActiveMap[user.id]!)}',
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
                          'App v${_userAppVersionMap[user.id]!}',
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
                        'Joined ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
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
                            ).withOpacity(0.1),
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
                                'Last active ${_formatLastActiveTime(_userLastActiveMap[user.id]!)}',
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
                  tooltip: 'View Details',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                    foregroundColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _editUser(user),
                  icon: const FaIcon(FontAwesomeIcons.userEdit, size: 16),
                  tooltip: 'Edit User',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1),
                    foregroundColor: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                if (user.status == 'active')
                  IconButton(
                    onPressed: () => _suspendUser(user),
                    icon: const FaIcon(FontAwesomeIcons.userSlash, size: 16),
                    tooltip: 'Suspend User',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => _activateUser(user),
                    icon: const FaIcon(FontAwesomeIcons.userCheck, size: 16),
                    tooltip: 'Activate User',
                    style: IconButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor.withOpacity(
                        0.1,
                      ),
                      foregroundColor: AppConstants.primaryColor,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteUser(user),
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                  tooltip: 'Delete User',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
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
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'User Details',
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
                  _buildDetailRow('Name', user.name),
                  _buildDetailRow('Email', user.email),
                  _buildDetailRow('Role', user.accountType.toUpperCase()),
                  _buildDetailRow('Status', user.status.toUpperCase()),
                  _buildDetailRow(
                    'Joined',
                    DateFormat('MMM dd, yyyy HH:mm').format(user.createdAt),
                  ),
                  _buildDetailRow(
                    'Terms Accepted',
                    user.acceptedTerms ? 'Yes' : 'No',
                  ),
                  _buildDetailRow(
                    'Privacy Accepted',
                    user.acceptedPrivacy ? 'Yes' : 'No',
                  ),
                  if (user.lastLoginAt != null)
                    _buildDetailRow(
                      'Last Login',
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
                        child: const Text('Close'),
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
                  title: Text('Edit User: ${user.name}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(
                            value: 'shop_owner',
                            child: Text('Shop Owner'),
                          ),
                          DropdownMenuItem(
                            value: 'moderator',
                            child: Text('Moderator'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
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
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'suspended',
                            child: Text('Suspended'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
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
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _updateUser(user, selectedRole, selectedStatus);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _updateUser(User user, String role, String status) async {
    setLoading(true, message: 'Updating user...');

    try {
      // Update role if changed
      if (role != user.accountType) {
        await UserService.updateUserAccountType(user.id, role);
      }

      // Update status if changed
      if (status != user.status) {
        await UserService.updateUserStatus(user.id, status);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} has been updated'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
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
            title: const Text('Suspend User'),
            content: Text('Are you sure you want to suspend "${user.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Suspend'),
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
            title: const Text('Delete User'),
            content: Text(
              'Are you sure you want to delete "${user.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Deleting user...');

      try {
        final success = await UserService.deleteUser(user.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} has been deleted'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          throw Exception('Failed to delete user');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
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
        const SnackBar(
          content: Text('Please select users to perform bulk actions'),
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
              'Bulk Actions (${_selectedUserIds.length} users selected)',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Activate All Selected'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkActivateUsers();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.orange),
                  title: const Text('Suspend All Selected'),
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
                  title: const Text('Change Role'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showBulkRoleChangeDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete All Selected'),
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
                child: const Text('Cancel'),
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
                    'Change Role for ${_selectedUserIds.length} users',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Select new role:'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'New Role',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(
                            value: 'shop_owner',
                            child: Text('Shop Owner'),
                          ),
                          DropdownMenuItem(
                            value: 'moderator',
                            child: Text('Moderator'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
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
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _bulkChangeRole(selectedRole);
                      },
                      child: const Text('Change Role'),
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
            title: const Text('Bulk Activate Users'),
            content: Text(
              'Are you sure you want to activate ${_selectedUserIds.length} users?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Activate All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Activating users...');
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            await UserService.updateUserStatus(userId, 'active');
            successCount++;
          } catch (e) {
            // Continue with other users if one fails
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount users activated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk activation: $e'),
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
            title: const Text('Bulk Suspend Users'),
            content: Text(
              'Are you sure you want to suspend ${_selectedUserIds.length} users?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Suspend All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Suspending users...');
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            await UserService.updateUserStatus(userId, 'suspended');
            successCount++;
          } catch (e) {
            // Continue with other users if one fails
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount users suspended successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk suspension: $e'),
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
            title: const Text('Bulk Change Role'),
            content: Text(
              'Are you sure you want to change ${_selectedUserIds.length} users to $newRole role?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Change Role'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Changing user roles...');
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            await UserService.updateUserAccountType(userId, newRole);
            successCount++;
          } catch (e) {
            // Continue with other users if one fails
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount users updated to $newRole role'),
            backgroundColor: Colors.blue,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk role change: $e'),
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
            title: const Text('Bulk Delete Users'),
            content: Text(
              'Are you sure you want to delete ${_selectedUserIds.length} users? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Deleting users...');
      try {
        int successCount = 0;
        for (final userId in _selectedUserIds) {
          try {
            final success = await UserService.deleteUser(userId);
            if (success) successCount++;
          } catch (e) {
            // Continue with other users if one fails
          }
        }

        safeSetState(() {
          _selectedUserIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount users deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk deletion: $e'),
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
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
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
