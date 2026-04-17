import 'package:flutter/material.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/constants/responsive_breakpoints.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:wonwon_client/screens/signup_screen.dart';
import 'package:wonwon_client/screens/forgot_password_screen.dart';
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
    final isWide = screenWidth >= ResponsiveBreakpoints.mobile;
    final formWidth = screenWidth >= ResponsiveBreakpoints.desktop ? 440.0 : 400.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: 40,
                ),
                child: Center(
                  child: Container(
                    width: isWide ? formWidth : double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 0 : 24,
                      vertical: 32,
                    ),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: AppConstants.primaryColor),
            label: Text(
              'back'.tr(context),
              style: const TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: AppConstants.primaryColor),
          ),

          const Spacer(),
        ],
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
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/wwg.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            'welcome_back'.tr(context),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'login_description'.tr(context),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                    labelText: 'email'.tr(context),
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'email_required'.tr(context);
                    }
                    if (!AuthService.isValidEmail(value)) {
                      return 'valid_email_required'.tr(context);
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
                    labelText: 'password'.tr(context),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      tooltip: 'toggle_password_visibility'.tr(context),
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
                      borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'password_required'.tr(context);
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Forgot Password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                'forgot_password'.tr(context),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Login button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      'login'.tr(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),

          const SizedBox(height: 24),

          // Sign up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'dont_have_account'.tr(context),
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'sign_up'.tr(context),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Capture ScaffoldMessenger before async gap so it stays valid after navigation
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
        AnalyticsService.safeLog(() => AnalyticsService().logLogin());
        _showMessage(messenger, 'login_successful'.tr(context), Colors.green);

        Navigator.of(context).pop(true);
        return;
      } else {
        _showMessage(messenger, result.message.tr(context), Colors.red);
      }
    } catch (e) {
      appLog('Login error: $e');
      if (mounted) {
        _showMessage(messenger, 'login_failed'.tr(context), Colors.red);
      } else {
        _showMessage(messenger, 'login_failed'.tr(context), Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(ScaffoldMessengerState messenger, String message, Color color) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
