import 'package:flutter/material.dart';
import 'package:wonwon_client/screens/main_navigation.dart';
import 'package:wonwon_client/screens/permission_splash_screen.dart';

/// Entry widget — goes straight into the permission splash, which handles
/// location bootstrapping and then navigates to the main tab container.
///
/// Previously this widget added two extra layers (a blank scaffold while
/// checking onboarding prefs + a conditional onboarding carousel). Those
/// extra frames interfered with the location warm-up the original splash
/// screen was doing, so the flow is now a direct pass-through.
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const PermissionSplashScreen(
      destination: MainNavigation(child: SizedBox()),
    );
  }
}
