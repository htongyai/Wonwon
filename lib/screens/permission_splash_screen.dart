import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/services/location_service.dart';

class PermissionSplashScreen extends StatefulWidget {
  final Widget destination;

  const PermissionSplashScreen({Key? key, required this.destination})
      : super(key: key);

  @override
  State<PermissionSplashScreen> createState() => _PermissionSplashScreenState();
}

class _PermissionSplashScreenState extends State<PermissionSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _initLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final splashStart = DateTime.now();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final locationService = LocationService();
          await locationService.getCurrentPosition().timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
        }
      }
    } catch (_) {
      // Location is optional — proceed regardless
    }

    // Brief branding moment (2s) - enough for animation without feeling slow
    final elapsed = DateTime.now().difference(splashStart);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    _goToApp();
  }

  void _goToApp() {
    if (_isTransitioning || !mounted) return;
    _isTransitioning = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 140,
                  height: 120,
                  child: Image.asset(
                    'assets/images/www.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const FaIcon(
                      FontAwesomeIcons.screwdriverWrench,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'app_name'.tr(context),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.5,
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
