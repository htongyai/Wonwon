import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/screens/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _selectedLanguage = 'en';
  bool _languageSelected = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Create scale animation
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _animationController.forward();

    // Check if language is already set
    _checkExistingLanguage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingLanguage() async {
    try {
      final locale = await AppLocalizationsService.getLocale();
      if (locale.languageCode.isNotEmpty) {
        setState(() {
          _selectedLanguage = locale.languageCode;
          _languageSelected = true;
        });
        // If language is already set, transition after a short delay
        Timer(const Duration(seconds: 1), () {
          if (mounted && !_isTransitioning) {
            _transitionToHome();
          }
        });
      }
    } catch (e) {
      // If no language is set, wait for user selection
      print('No language set, waiting for user selection');
    }
  }

  void _transitionToHome() {
    if (_isTransitioning) return;
    setState(() {
      _isTransitioning = true;
    });
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const MainNavigation(child: SizedBox()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 1),

              // Logo animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  width: 180,
                  height: 160,
                  child: Image.asset(
                    'assets/images/www.png',
                    fit: BoxFit.contain,
                    colorBlendMode: BlendMode.srcIn,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo image is missing
                      return FaIcon(
                        FontAwesomeIcons.screwdriverWrench,
                        size: 120,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),

              // App name (localized)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'app_name'.tr(context),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tagline (localized)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'tagline'.tr(context),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

              const SizedBox(height: 24),

              // Language selector
              FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await AppLocalizationsService.setLocale('en');
                        setState(() {
                          _selectedLanguage = 'en';
                          _languageSelected = true;
                        });
                        // Transition to home after language selection
                        Timer(const Duration(milliseconds: 500), () {
                          if (mounted && !_isTransitioning) {
                            _transitionToHome();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedLanguage == 'en'
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                        foregroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 20,
                        ),
                      ),
                      child: Text('english'.tr(context)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await AppLocalizationsService.setLocale('th');
                        setState(() {
                          _selectedLanguage = 'th';
                          _languageSelected = true;
                        });
                        // Transition to home after language selection
                        Timer(const Duration(milliseconds: 500), () {
                          if (mounted && !_isTransitioning) {
                            _transitionToHome();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _selectedLanguage == 'th'
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                        foregroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 20,
                        ),
                      ),
                      child: Text('thai'.tr(context)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Loading indicator or transition message
              FadeTransition(
                opacity: _fadeAnimation,
                child:
                    _languageSelected
                        ? Column(
                          children: [
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'preparing_your_experience'.tr(context),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                        : const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
              ),

              Spacer(flex: 1),

              // Support text at the bottom
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'supported_by_community'.tr(context),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
