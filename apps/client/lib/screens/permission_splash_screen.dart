import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';
import 'package:shared/services/location_service.dart';

/// Splash screen that BLOCKS app entry until location permission is
/// granted. There is no escape hatch — location is a hard requirement
/// for the app, so we don't let the user past this screen without it.
///
/// Why blocking: location is a primary input — distance to shops,
/// "near me" sorting, the on-map view, the location filter chip — all
/// depend on it. The previous implementation auto-proceeded after a
/// 5-second timeout, which silently dropped users into the main app
/// with no coordinates if they were slow to dismiss the browser prompt.
///
/// Behavior:
///   1. On mount: kick off the platform's location permission request.
///   2. Wait for an explicit response from the user (no timeout).
///   3. Granted → proceed to the destination widget.
///   4. Denied / failed → render a "Location needed" panel with an
///      "Allow location" button that re-fires the prompt. On web, also
///      show a hint about unblocking via the browser site-permission UI
///      (because once the user clicks Block, the browser suppresses
///      future programmatic prompts and the only way back is settings).
class PermissionSplashScreen extends StatefulWidget {
  final Widget destination;

  const PermissionSplashScreen({Key? key, required this.destination})
      : super(key: key);

  @override
  State<PermissionSplashScreen> createState() => _PermissionSplashScreenState();
}

enum _SplashState {
  /// Initial — branding visible while the browser/system permission
  /// dialog is up. We sit here until the user responds.
  prompting,

  /// User denied location (browser block, OS denial, or location
  /// services off). We surface a retry CTA instead of silently
  /// entering the app — there is no skip path; granting location is
  /// required to use the app.
  needsPermission,
}

class _PermissionSplashScreenState extends State<PermissionSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;

  bool _isTransitioning = false;
  _SplashState _state = _SplashState.prompting;

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

  /// Trigger the platform permission flow and either proceed to the
  /// app on success or flip the splash into the "needs permission"
  /// state on failure.
  ///
  /// CRITICAL: This must NEVER block on coord-fetch success. The gate
  /// is about **consent**, not about whether coords actually came back.
  /// A user on a flaky GPS / VPN / localhost-dev Chrome can grant
  /// permission but still have `getCurrentPosition()` fail with
  /// "Position update is unavailable" — or worse, hang forever (the
  /// web Geolocator implementation has been observed to ignore its
  /// own `timeLimit`). We must NOT trap that user on the splash; they
  /// consented, which is what we asked for. The actual location fetch
  /// happens in the background via LocationService's layered fallback
  /// (cache → GPS → IP geolocation) and HomeScreen reads the result.
  ///
  /// Strategy:
  ///   1. Trigger the platform permission dialog
  ///       - Web: fire a Geolocator.getCurrentPosition() unawaited;
  ///         this is the only reliable way to surface Safari's prompt
  ///   2. Resolve the permission decision via Geolocator.requestPermission()
  ///      (which on Chrome/Firefox returns once the user clicks
  ///      Allow/Block; on Safari returns the cached state immediately)
  ///   3. If granted, kick off the background location fetch and proceed
  ///   4. If denied, surface the retry CTA
  Future<void> _initLocation() async {
    final splashStart = DateTime.now();

    bool granted = false;
    try {
      if (kIsWeb) {
        // Trigger the prompt by firing a position request unawaited.
        // Safari's prompt only appears in response to an actual
        // position request, not requestPermission(). We use a 1s
        // timeout so this future resolves quickly even if the browser
        // can't actually produce a position.
        unawaited(
          Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 1),
          ).catchError((_) {
            // Swallow — we're not gating on coord success.
            return Position(
              latitude: 0,
              longitude: 0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }),
        );
        // Now ask for the permission decision. On Chrome/Firefox this
        // waits for the user's Allow/Block click. On Safari it returns
        // the cached state immediately (whileInUse if the prompt fired
        // and was approved, denied otherwise).
        final perm = await Geolocator.requestPermission();
        granted = perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always;
        if (granted) {
          // Kick off the real location fetch in the background — the
          // result lands in LocationService's cache and HomeScreen
          // reads it.
          unawaited(LocationService().getCurrentPosition());
        }
      } else {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();

          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          // Same logic as web: the gate is consent, not coord success.
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            unawaited(LocationService().getCurrentPosition());
            granted = true;
          }
        }
      }
    } catch (_) {
      // Defensive: a thrown error here doesn't tell us about consent.
      // Re-check the permission status directly so we don't lock out
      // a user who actually granted permission.
      try {
        final perm = await Geolocator.checkPermission();
        granted = perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always;
      } catch (_) {
        granted = false;
      }
    }

    if (!mounted) return;

    if (granted) {
      // Brief branding moment so the splash doesn't flash instantly
      // when permission was already granted on a previous visit.
      final elapsed = DateTime.now().difference(splashStart);
      final remaining = const Duration(milliseconds: 1200) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
      _goToApp();
    } else {
      // Permission denied — surface the retry CTA. We don't enter the
      // app silently because the user explicitly refused consent.
      setState(() => _state = _SplashState.needsPermission);
    }
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

  /// User tapped "Allow location" on the permission panel.
  /// Drop back to the prompting state and re-fire the request.
  void _retryPermission() {
    setState(() => _state = _SplashState.prompting);
    _initLocation();
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
            child: _state == _SplashState.prompting
                ? _buildPromptingView(context)
                : _buildPermissionNeededView(context),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptingView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _logo(),
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
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'location_prompt_hint'.tr(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionNeededView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _logo(),
          const SizedBox(height: 24),
          Text(
            'location_needed_title'.tr(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'location_needed_body'.tr(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Primary CTA — re-prompt for permission.
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _retryPermission,
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                'location_grant_button'.tr(context),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Browser-specific guidance — if the user blocked location
          // the only way to re-prompt is via the site permissions UI.
          // Always shown on web because there's no skip button now;
          // this hint is the user's only path forward after a hard
          // browser-level block.
          if (kIsWeb)
            Text(
              'location_browser_hint'.tr(context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _logo() {
    return SizedBox(
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
    );
  }
}
