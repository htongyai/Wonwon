import 'package:flutter/material.dart';
import 'package:shared/services/auth_manager.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_dashboard/screens/admin_dashboard_main_screen.dart';
import 'package:wonwon_dashboard/screens/login_screen.dart';

/// Admin-specific auth gate that requires admin role.
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({Key? key}) : super(key: key);

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  final AuthManager _authManager = AuthManager();
  bool _isChecking = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    if (!_authManager.isLoggedIn) {
      if (mounted) setState(() => _isChecking = false);
      return;
    }

    try {
      final isAdmin = await _authManager.isAdmin();
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _isChecking = false;
      });

      // If logged in but not admin, log them out
      if (!isAdmin) {
        await _authManager.logout();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppConstants.primaryColor,
          ),
        ),
      );
    }

    if (_authManager.isLoggedIn && _isAdmin) {
      return const AdminDashboardMainScreen();
    }

    return const LoginScreen();
  }
}
