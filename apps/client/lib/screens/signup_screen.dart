import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:wonwon_client/screens/main_navigation.dart';
import 'package:shared/services/auth_service.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:shared/utils/app_logger.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _signupSuccessful = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String _selectedAccountType = 'user';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_signupSuccessful) return false;
    return _nameController.text.isNotEmpty ||
        _emailController.text.isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  Future<bool> _showDiscardDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'discard_changes'.tr(context),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        content: Text(
          'discard_changes_message'.tr(context),
          style: GoogleFonts.montserrat(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'keep_editing'.tr(context),
              style: const TextStyle(color: AppConstants.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'discard'.tr(context),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBackButton() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardDialog();
      if (shouldDiscard && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final formWidth = screenWidth >= 1024 ? 440.0 : 400.0;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _showDiscardDialog();
        if (shouldDiscard && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                    child: _buildSignupForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: _handleBackButton,
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
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
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
            'create_account'.tr(context),
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
            'sign_up_description'.tr(context),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Name field
          AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  autofocus: false,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  maxLength: 100,
                  onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                  decoration: InputDecoration(
                    labelText: 'full_name'.tr(context),
                    prefixIcon: const Icon(Icons.person_outline),
                    counterText: '',
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
                    if (value == null || value.trim().isEmpty) {
                      return 'full_name_required'.tr(context);
                    }
                    if (value.trim().length < 2) {
                      return 'name_too_short'.tr(context);
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email field
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
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
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
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
                    final validation = AuthService.validatePassword(value);
                    if (!validation.isValid) {
                      return validation.message.tr(context);
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Password requirements helper text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'password_requirements_title'.tr(context),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'password_requirements_text'.tr(context),
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Confirm Password field
          TextFormField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_isLoading) _handleSignup();
            },
            decoration: InputDecoration(
              labelText: 'confirm_password'.tr(context),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                tooltip: 'toggle_password_visibility'.tr(context),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
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
                return 'confirm_password_required'.tr(context);
              }
              if (value != _passwordController.text) {
                return 'passwords_dont_match'.tr(context);
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Account type selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'account_type'.tr(context),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedAccountType = 'user'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedAccountType == 'user'
                              ? AppConstants.primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedAccountType == 'user'
                                ? AppConstants.primaryColor
                                : Colors.grey.shade300,
                            width: _selectedAccountType == 'user' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 32,
                              color: _selectedAccountType == 'user'
                                  ? AppConstants.primaryColor
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'regular_user'.tr(context),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedAccountType == 'user'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedAccountType == 'user'
                                    ? AppConstants.darkColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedAccountType = 'shop_owner'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedAccountType == 'shop_owner'
                              ? AppConstants.primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedAccountType == 'shop_owner'
                                ? AppConstants.primaryColor
                                : Colors.grey.shade300,
                            width: _selectedAccountType == 'shop_owner' ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 32,
                              color: _selectedAccountType == 'shop_owner'
                                  ? AppConstants.primaryColor
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'shop_owner'.tr(context),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedAccountType == 'shop_owner'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: _selectedAccountType == 'shop_owner'
                                    ? AppConstants.darkColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Terms and conditions checkbox
          FormField<bool>(
            initialValue: _acceptedTerms,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value != true) {
                return 'accept_terms_required'.tr(context);
              }
              return null;
            },
            builder: (state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _acceptedTerms = !_acceptedTerms;
                      });
                      state.didChange(_acceptedTerms);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value ?? false;
                                });
                                state.didChange(_acceptedTerms);
                              },
                              activeColor: AppConstants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'signup_agreement_text'.tr(context),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 4),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Sign up button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
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
                      'create_account'.tr(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),

          const SizedBox(height: 24),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'already_have_account'.tr(context),
                  style: TextStyle(color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'login'.tr(context),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedAccountType,
        acceptedTerms: _acceptedTerms,
      );

      if (!mounted) return;

      if (result.success) {
        _signupSuccessful = true;
        AnalyticsService.safeLog(() => AnalyticsService().logSignUp());
        _showMessage(messenger, 'account_created'.tr(context), Colors.green);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(child: SizedBox()),
          ),
        );
        return;
      } else {
        _showMessage(
          messenger,
          (result.errorKey ?? 'registration_error_occurred').tr(context),
          Colors.red,
        );
      }
    } catch (e) {
      appLog('Registration error: $e');
      if (mounted) {
        _showMessage(messenger, 'registration_error_occurred'.tr(context), Colors.red);
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
