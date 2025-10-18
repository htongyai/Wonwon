import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/screens/privacy_policy_screen.dart';
import 'package:wonwonw2/screens/signup_screen.dart';
import 'package:wonwonw2/screens/terms_of_use_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/widgets/optimized_form_widget.dart';
import 'package:wonwonw2/screens/forgot_password_screen.dart';

/// Optimized authentication form widget for login and signup screens
class AuthFormWidget extends StatefulWidget {
  final AuthFormType type;
  final VoidCallback? onSuccess;
  final Color? primaryColor;

  const AuthFormWidget({
    Key? key,
    required this.type,
    this.onSuccess,
    this.primaryColor,
  }) : super(key: key);

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedAccountType = 'user';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  List<FormFieldConfig> get _formFields {
    final isSignup = widget.type == AuthFormType.signup;

    final fields = <FormFieldConfig>[
      if (isSignup)
        FormFieldConfig(
          label: 'full_name',
          labelText: 'full_name',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'name_required'.tr(context);
            }
            return null;
          },
        ),

      FormFieldConfig(
        label: 'email',
        labelText: 'email',
        controller: _emailController,
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
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

      if (isSignup)
        FormFieldConfig(
          label: 'account_type',
          labelText: 'account_type',
          type: FormFieldType.radio,
          radioValue: _selectedAccountType,
          onRadioChanged: (value) {
            setState(() {
              _selectedAccountType = value!;
            });
          },
          radioOptions: [
            RadioOption(
              title: 'normal_user',
              subtitle: 'looking_for_repairs',
              value: 'user',
              icon: Icons.person,
            ),
            RadioOption(
              title: 'shop_owner',
              subtitle: 'manage_shop_business',
              value: 'shop_owner',
              icon: Icons.store,
            ),
          ],
        ),

      FormFieldConfig(
        label: 'password',
        labelText: 'password',
        controller: _passwordController,
        prefixIcon: Icons.lock_outline,
        suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
        onSuffixPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'password_required'.tr(context);
          }
          if (isSignup) {
            final validation = AuthService.validatePassword(value);
            if (!validation.isValid) {
              return validation.message;
            }
          }
          return null;
        },
      ),

      if (isSignup)
        FormFieldConfig(
          label: 'confirm_password',
          labelText: 'confirm_password',
          controller: _confirmPasswordController,
          prefixIcon: Icons.lock_outline,
          suffixIcon:
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
          onSuffixPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          obscureText: _obscureConfirmPassword,
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
    ];

    return fields;
  }

  Widget get _header {
    final isSignup = widget.type == AuthFormType.signup;

    return Column(
      children: [
        // Logo
        Container(
          margin: const EdgeInsets.only(top: 20, bottom: 32),
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('assets/images/wwg.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Title
        Text(
          isSignup ? 'create_account'.tr(context) : 'welcome_back'.tr(context),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: widget.primaryColor ?? Colors.brown,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          isSignup
              ? 'sign_up_description'.tr(context)
              : 'login_description'.tr(context),
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget get _footer {
    final isSignup = widget.type == AuthFormType.signup;

    return Column(
      children: [
        if (isSignup) ...[
          // Agreement text
          Text(
            'signup_agreement_text'.tr(context),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Terms and Privacy buttons
          Column(
            children: [
              TextButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TermsOfUseScreen(),
                      ),
                    ),
                child: Text('terms_of_use_button'.tr(context)),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    ),
                child: Text('privacy_policy_button'.tr(context)),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Forgot password link for login
        if (!isSignup) ...[
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
                foregroundColor: widget.primaryColor ?? Colors.brown,
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
        ],

        // Login/Signup link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isSignup
                  ? 'already_have_account'.tr(context)
                  : 'dont_have_account'.tr(context),
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: () {
                if (isSignup) {
                  Navigator.pop(context);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: widget.primaryColor ?? Colors.brown,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                isSignup ? 'login'.tr(context) : 'sign_up'.tr(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final isSignup = widget.type == AuthFormType.signup;

    if (isSignup &&
        _passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('passwords_dont_match'.tr(context));
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool success;

      if (isSignup) {
        success = await _authService.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          _selectedAccountType,
        );
      } else {
        final result = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        success = result.success;
      }

      if (success && mounted) {
        _showSuccessSnackBar(
          isSignup
              ? 'account_created'.tr(context)
              : 'login_successful'.tr(context),
        );

        widget.onSuccess?.call();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(child: SizedBox()),
            ),
          );
        }
      } else if (mounted) {
        _showErrorSnackBar(
          isSignup
              ? 'registration_failed'.tr(context)
              : 'login_failed'.tr(context),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignup = widget.type == AuthFormType.signup;

    return OptimizedFormWidget(
      formKey: _formKey,
      fields: _formFields,
      submitButtonText:
          isSignup ? 'create_account'.tr(context) : 'login'.tr(context),
      onSubmit: _handleSubmit,
      isLoading: _isLoading,
      primaryColor: widget.primaryColor ?? Colors.brown,
      header: _header,
      footer: _footer,
      padding: ResponsiveSize.getScaledPadding(
        const EdgeInsets.symmetric(horizontal: 24.0),
      ),
    );
  }
}

enum AuthFormType { login, signup }
