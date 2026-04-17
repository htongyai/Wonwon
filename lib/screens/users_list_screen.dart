import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/constants/app_colors.dart';
import 'package:wonwonw2/constants/app_text_styles.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/user.dart';
import 'package:wonwonw2/services/user_service.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:intl/intl.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _searchQuery = '';
  String _filterAccountType = 'all';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await UserService.isCurrentUserAdmin();
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
      });
    } catch (e) {
      appLog('Error checking admin status: $e');
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await UserService.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      appLog('Error loading users: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesAccountType =
          _filterAccountType == 'all' || user.accountType == _filterAccountType;

      final matchesStatus =
          _filterStatus == 'all' || user.status == _filterStatus;

      return matchesSearch && matchesAccountType && matchesStatus;
    }).toList();
  }

  Future<void> _updateUserAccountType(User user, String newAccountType) async {
    try {
      final success = await UserService.updateUserAccountType(
        user.id,
        newAccountType,
      );
      if (!mounted) return;
      if (success) {
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = user.copyWith(accountType: newAccountType);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('account_type_updated'.tr(context)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('failed_update_account_type'.tr(context)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      appLog('Error updating user account type: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_updating_account_type'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserStatus(User user, String newStatus) async {
    try {
      final success = await UserService.updateUserStatus(user.id, newStatus);
      if (!mounted) return;
      if (success) {
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = user.copyWith(status: newStatus);
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('user_status_updated'.tr(context)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('failed_update_user_status'.tr(context)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      appLog('Error updating user status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_updating_user_status'.tr(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getAccountTypeColor(String accountType) {
    switch (accountType) {
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
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    // Show loading while checking admin access
    if (!_isAdmin && _isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'users_list'.tr(context),
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If not admin, show empty scaffold (will be popped by _checkAdminAccess)
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'users_list'.tr(context),
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
        body: Center(child: Text('access_denied_title'.tr(context))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'users_list'.tr(context),
          style: AppTextStyles.heading.copyWith(color: AppColors.text),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Container(
            padding: ResponsiveSize.getScaledPadding(const EdgeInsets.all(16)),
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'search_users_short'.tr(context),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterAccountType,
                        decoration: InputDecoration(
                          labelText: 'account_type_label'.tr(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('all_types'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('admin_role_label'.tr(context)),
                          ),
                          DropdownMenuItem(
                            value: 'moderator',
                            child: Text('moderator_role'.tr(context)),
                          ),
                          DropdownMenuItem(value: 'user', child: Text('user_role'.tr(context))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterAccountType = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        decoration: InputDecoration(
                          labelText: 'admin_status'.tr(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('all_status'.tr(context)),
                          ),
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
                            _filterStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'admin_no_users_found'.tr(context),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: ResponsiveSize.getScaledPadding(
                        const EdgeInsets.all(16),
                      ),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _buildUserCard(user);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.2),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppConstants.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name.isNotEmpty ? user.name : 'no_information'.tr(context),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getAccountTypeColor(
                      user.accountType,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getAccountTypeColor(user.accountType),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user.accountType.toUpperCase(),
                    style: TextStyle(
                      color: _getAccountTypeColor(user.accountType),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(user.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(user.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(user.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User details
                _buildInfoRow(
                  'admin_created'.tr(context),
                  DateFormat('MMM dd, yyyy').format(user.createdAt),
                ),
                if (user.lastLoginAt != null)
                  _buildInfoRow(
                    'last_active_sort'.tr(context),
                    DateFormat('MMM dd, yyyy HH:mm').format(user.lastLoginAt!),
                  ),

                const SizedBox(height: 16),

                // Account type selector
                Text(
                  'account_type_label'.tr(context),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: user.accountType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'user', child: Text('user_role'.tr(context))),
                    DropdownMenuItem(
                      value: 'moderator',
                      child: Text('moderator_role'.tr(context)),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('admin_role_label'.tr(context))),
                  ],
                  onChanged: (newType) {
                    if (newType != null && newType != user.accountType) {
                      _updateUserAccountType(user, newType);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Status selector
                Text(
                  'admin_status'.tr(context),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: user.status,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'active', child: Text('active_status'.tr(context))),
                    DropdownMenuItem(
                      value: 'suspended',
                      child: Text('suspended_status'.tr(context)),
                    ),
                    DropdownMenuItem(value: 'pending', child: Text('pending_status_label'.tr(context))),
                  ],
                  onChanged: (newStatus) {
                    if (newStatus != null && newStatus != user.status) {
                      _updateUserStatus(user, newStatus);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
