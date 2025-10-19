import 'package:flutter/material.dart';
// Removed go_router import - using basic navigation
import 'package:wonwonw2/constants/responsive_breakpoints.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/screens/admin_dashboard_main_screen.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/screens/signup_screen.dart';
import 'package:wonwonw2/screens/forgot_password_screen.dart';
import 'package:wonwonw2/screens/forgot_password_screen_safe.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdminFlow;

  const LoginScreen({Key? key, this.isAdminFlow = false}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isAdminFlow = false;

  @override
  void initState() {
    super.initState();
    // Set admin flow from constructor parameter
    _isAdminFlow = widget.isAdminFlow;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop =
        ResponsiveBreakpoints.isTablet(screenWidth) ||
        ResponsiveBreakpoints.isDesktop(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with admin button
            _buildHeader(),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: isDesktop ? 400 : double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 0 : 24,
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
            icon: const Icon(Icons.arrow_back, color: Colors.brown),
            label: Text(
              'back'.tr(context),
              style: const TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.brown),
          ),

          const Spacer(),

          // Show admin badge if this is admin flow
          if (_isAdminFlow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.brown.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 16,
                    color: Colors.brown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Admin Login',
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
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
            _isAdminFlow ? 'Admin Login' : 'welcome_back'.tr(context),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            _isAdminFlow
                ? 'Sign in with your admin credentials'
                : 'login_description'.tr(context),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'email'.tr(context),
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.brown, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!AuthService.isValidEmail(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'password'.tr(context),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.brown, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Forgot Password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                } catch (e) {
                  // Fallback to safe version if localization fails
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreenSafe(),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: Text(
                'forgot_password'.tr(context),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Login button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
              Text(
                'dont_have_account'.tr(context),
                style: TextStyle(color: Colors.grey[600]),
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
                  foregroundColor: Colors.brown,
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (result.success) {
          _showSnackBar('login_successful'.tr(context), Colors.green);

          // Check if this is admin flow and user is admin
          if (_isAdminFlow) {
            print('=== ADMIN FLOW DETECTED ===');
            final isAdmin = await _authService.isAdmin();
            print('Admin flow detected. Is user admin? $isAdmin');
            if (isAdmin) {
              print('User is admin, navigating to admin dashboard...');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardMainScreen(),
                ),
              );
              print('Navigated to admin dashboard successfully');
            } else {
              print('User is not admin, showing error and logging out');
              _showSnackBar('Admin privileges required', Colors.red);
              await _authService.logout(); // Log out non-admin user
            }
          } else {
            print('=== REGULAR USER FLOW ===');
            print('Regular user login, navigating to home...');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainNavigation(child: SizedBox()),
              ),
            );
            print('Navigated to home successfully');
          }
        } else {
          _showSnackBar(
            result.message.isNotEmpty
                ? result.message
                : 'login_failed'.tr(context),
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('login_failed'.tr(context), Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
