import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/responsive_breakpoints.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/services/auth_service.dart';

/// Safe version of forgot password screen that works without localization
class ForgotPasswordScreenSafe extends StatefulWidget {
  const ForgotPasswordScreenSafe({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreenSafe> createState() =>
      _ForgotPasswordScreenSafeState();
}

class _ForgotPasswordScreenSafeState extends State<ForgotPasswordScreenSafe> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.resetPassword(
          _emailController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailSent = result.success;
          });

          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('reset_email_sent'.tr(context)),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  (result.errorKey ?? 'reset_failed').tr(context),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Password reset error: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('unexpected_error'.tr(context)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= ResponsiveBreakpoints.tablet;
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('forgot_password'.tr(context)),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            width: isDesktop ? 400 : null,
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 400 : screenWidth * 0.9,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),

                      // Logo
                      Center(
                        child: Container(
                          width: isMobile ? 70 : 90,
                          height: isMobile ? 70 : 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.primaryColor,
                          ),
                          child: Icon(
                            Icons.lock_reset,
                            size: isMobile ? 35 : 50,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'reset_password'.tr(context),
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: isMobile ? 12 : 16),

                      Text(
                        'reset_password_description'.tr(context),
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'email'.tr(context),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppConstants.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                            horizontal: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
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

                      const SizedBox(height: 24),

                      // Success message if email sent
                      if (_emailSent) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade600,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'reset_link_sent'.tr(context),
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'check_email_instructions'.tr(context),
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: Colors.green.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // Responsive button layout
                              isMobile
                                  ? Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade600,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text('back_to_login'.tr(context)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _emailSent = false;
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.green.shade700,
                                          ),
                                          child: Text(
                                            'send_another_email'.tr(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _emailSent = false;
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Colors.green.shade700,
                                        ),
                                        child: Text('send_another_email'.tr(context)),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text('back_to_login'.tr(context)),
                                      ),
                                    ],
                                  ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Reset Password button (hide if email sent)
                      if (!_emailSent)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            minimumSize: Size(
                              double.infinity,
                              isMobile ? 45 : 50,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'reset_password'.tr(context),
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),

                      const SizedBox(height: 24),

                      // Back to login link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                          ),
                          child: Text(
                            'back_to_login'.tr(context),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isMobile ? 24 : 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
