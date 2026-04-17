import 'package:flutter/material.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';
import 'package:wonwon_dashboard/screens/admin_dashboard_main_screen.dart';
import 'package:shared/utils/app_logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= ResponsiveBreakpoints.desktop;
    final formWidth = isDesktop ? 440.0 : 400.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 40,
            ),
            child: Container(
              width: screenWidth >= ResponsiveBreakpoints.mobile
                  ? formWidth
                  : double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth >= ResponsiveBreakpoints.mobile ? 0 : 24,
                vertical: 32,
              ),
              child: _buildLoginForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/wwg.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Admin badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 18,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'admin_dashboard_title'.tr(context),
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'welcome_back'.tr(context),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'sign_in_admin_panel'.tr(context),
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Email field
          AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  autofocus: false,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'email_label'.tr(context),
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please_enter_email'.tr(context);
                    }
                    if (!AuthService.isValidEmail(value)) {
                      return 'please_enter_valid_email'.tr(context);
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _handleLogin();
                  },
                  decoration: InputDecoration(
                    labelText: 'password_label'.tr(context),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppConstants.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please_enter_password'.tr(context);
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Login button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'sign_in'.tr(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 48),

          // Footer
          Center(
            child: Text(
              'wonwon_admin_portal'.tr(context),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        // Check if user is admin
        final isAdmin = await _authService.isAdmin();
        if (!mounted) return;

        if (isAdmin) {
          AnalyticsService.safeLog(() => AnalyticsService().logLogin());
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const AdminDashboardMainScreen(),
            ),
            (route) => false,
          );
        } else {
          // Not an admin - sign out and show error
          await _authService.logout();
          if (mounted) {
            _showMessage(
              messenger,
              'access_denied_admin'.tr(context),
              Colors.red,
            );
          }
        }
      } else {
        _showMessage(messenger, result.message, Colors.red);
      }
    } catch (e) {
      appLog('Login error: $e');
      if (mounted) {
        _showMessage(
            messenger, 'login_failed'.tr(context), Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(
      ScaffoldMessengerState messenger, String message, Color color) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
