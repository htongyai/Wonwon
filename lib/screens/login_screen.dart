import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/services/auth_state_service.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/screens/signup_screen.dart';
import 'package:wonwonw2/screens/forgot_password_screen.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/theme/app_theme.dart';
import 'package:wonwonw2/widgets/custom_form_field.dart';
import 'package:wonwonw2/widgets/error_boundary.dart';
import 'package:wonwonw2/utils/error_logger.dart';
import 'package:wonwonw2/services/error_handling_service.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _authStateService = authStateService;
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  int _loginAttempts = 0;
  DateTime? _lastAttemptTime;
  static const int _maxAttempts = 3;
  static const Duration _cooldownDuration = Duration(minutes: 5);
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }

  void _validateEmail() {
    setState(() {
      _isEmailValid =
          _emailController.text.isNotEmpty &&
          RegExp(
            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
          ).hasMatch(_emailController.text);
    });
  }

  void _validatePassword() {
    setState(() {
      _isPasswordValid = _passwordController.text.isNotEmpty;
    });
  }

  void _handleKeyboardSubmit() {
    if (_emailFocusNode.hasFocus) {
      _emailFocusNode.unfocus();
      _passwordFocusNode.requestFocus();
    } else if (_passwordFocusNode.hasFocus) {
      _passwordFocusNode.unfocus();
      _handleLogin();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _isInCooldown() {
    if (_lastAttemptTime == null) return false;
    return DateTime.now().difference(_lastAttemptTime!) < _cooldownDuration;
  }

  String _getRemainingCooldownTime() {
    if (_lastAttemptTime == null) return '';
    final remaining =
        _cooldownDuration - DateTime.now().difference(_lastAttemptTime!);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLogin() async {
    if (_isInCooldown()) {
      await ErrorHandlingService.handleError(
        ValidationError(
          'too_many_attempts'.tr(context) + ' ${_getRemainingCooldownTime()}',
        ),
        null,
        context,
        errorContext: 'LoginScreen._handleLogin',
        additionalData: {
          'loginAttempts': _loginAttempts,
          'lastAttemptTime': _lastAttemptTime?.toIso8601String(),
        },
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _loginAttempts++;
        _lastAttemptTime = DateTime.now();
      });

      try {
        final success = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (success && mounted) {
          Navigator.pop(context, true);
        } else if (mounted) {
          if (_loginAttempts >= _maxAttempts) {
            await ErrorHandlingService.handleError(
              AuthError(AuthErrorType.accountLocked),
              null,
              context,
              errorContext: 'LoginScreen._handleLogin',
              additionalData: {
                'email': _emailController.text,
                'loginAttempts': _loginAttempts,
              },
            );
          } else {
            await ErrorHandlingService.handleError(
              AuthError(AuthErrorType.invalidCredentials),
              null,
              context,
              errorContext: 'LoginScreen._handleLogin',
              additionalData: {
                'email': _emailController.text,
                'loginAttempts': _loginAttempts,
              },
              onRetry: _handleLogin,
            );
          }
        }
      } catch (e, stackTrace) {
        await ErrorHandlingService.handleError(
          e,
          stackTrace,
          context,
          errorContext: 'LoginScreen._handleLogin',
          additionalData: {
            'email': _emailController.text,
            'loginAttempts': _loginAttempts,
          },
          onRetry: _handleLogin,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ErrorBoundary(
      fallbackBuilder: (context, error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Login Error',
                  style: AppTheme.getTitleStyle().copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'re having trouble with the login process. Please try again.',
                  style: AppTheme.getSubtitleStyle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: AppTheme.getPrimaryButtonStyle(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      context.go('/');
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.primaryColor,
                    ),
                    label: Text(
                      'Back',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Padding(
                          padding: ResponsiveSize.getScaledPadding(
                            const EdgeInsets.symmetric(horizontal: 24.0),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Logo
                                RepaintBoundary(
                                  child: Center(
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 20,
                                        bottom: 32,
                                      ),
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: AssetImage(
                                            'assets/images/wwg.png',
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Welcome text
                                Text(
                                  'login'.tr(context),
                                  style: AppTheme.getTitleStyle(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'sign_in_description'.tr(context),
                                  style: AppTheme.getSubtitleStyle(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),

                                // Email field
                                CustomFormField(
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  labelText: 'email'.tr(context),
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  onFieldSubmitted:
                                      (_) => _handleKeyboardSubmit(),
                                  isValid: _isEmailValid,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'email_required'.tr(context);
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'valid_email_required'.tr(context);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password field
                                CustomFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  labelText: 'password'.tr(context),
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted:
                                      (_) => _handleKeyboardSubmit(),
                                  isValid: _isPasswordValid,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'password_required'.tr(context);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      context.push('/forgot-password');
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                    ),
                                    child: Text('forgot_password'.tr(context)),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Login button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: AppTheme.getPrimaryButtonStyle(),
                                  child:
                                      _isLoading
                                          ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                          : Text(
                                            'login'.tr(context),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                                const SizedBox(height: 16),

                                // Sign up link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'no_account'.tr(context),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.push('/signup');
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                      ),
                                      child: Text('signup'.tr(context)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
