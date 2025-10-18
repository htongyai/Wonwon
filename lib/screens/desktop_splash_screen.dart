import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:google_fonts/google_fonts.dart';

class DesktopSplashScreen extends StatefulWidget {
  const DesktopSplashScreen({Key? key}) : super(key: key);

  @override
  State<DesktopSplashScreen> createState() => _DesktopSplashScreenState();
}

class _DesktopSplashScreenState extends State<DesktopSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _loadingAnimationController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loadingFadeAnimation;

  String _selectedLanguage = 'en';
  bool _languageSelected = false;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Logo animations
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    // Text animations
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textAnimationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Loading animation
    _loadingFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingAnimationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animations in sequence
    _startAnimations();

    // Check if language is already set
    _checkExistingLanguage();
  }

  void _startAnimations() async {
    await _logoAnimationController.forward();
    await _textAnimationController.forward();
    await _loadingAnimationController.forward();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    _loadingAnimationController.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryColor.withOpacity(0.8),
              AppConstants.accentColor.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo section
                  AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 300,
                      height: 250,
                      child: Center(
                        child: Image.asset(
                          'assets/images/www.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return FaIcon(
                              FontAwesomeIcons.screwdriverWrench,
                              size: 150,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App name
                  AnimatedBuilder(
                    animation: _textAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'app_name'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tagline
                  AnimatedBuilder(
                    animation: _textAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      'tagline'.tr(context),
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Language selector
                  AnimatedBuilder(
                    animation: _textAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'select_language'.tr(context),
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 20),
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
                                      : Colors.white.withOpacity(0.3),
                              foregroundColor:
                                  _selectedLanguage == 'en'
                                      ? AppConstants.primaryColor
                                      : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              elevation: _selectedLanguage == 'en' ? 4 : 0,
                            ),
                            child: Text(
                              'english'.tr(context),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                                      : Colors.white.withOpacity(0.3),
                              foregroundColor:
                                  _selectedLanguage == 'th'
                                      ? AppConstants.primaryColor
                                      : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                              elevation: _selectedLanguage == 'th' ? 4 : 0,
                            ),
                            child: Text(
                              'thai'.tr(context),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Loading section
                  AnimatedBuilder(
                    animation: _loadingAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _loadingFadeAnimation,
                        child: child,
                      );
                    },
                    child:
                        _languageSelected
                            ? Column(
                              children: [
                                const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'preparing_your_experience'.tr(context),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                            : Column(
                              children: [
                                const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'loading'.tr(context),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                  ),

                  const Spacer(flex: 2),

                  // Footer
                  AnimatedBuilder(
                    animation: _loadingAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _loadingFadeAnimation,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'supported_by_community'.tr(context),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2024 WonWon - Repair Shop Platform',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
