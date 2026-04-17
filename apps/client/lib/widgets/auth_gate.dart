import 'package:flutter/material.dart';
import 'package:wonwon_client/screens/main_navigation.dart';
import 'package:wonwon_client/screens/permission_splash_screen.dart';

/// Widget that determines the initial screen based on authentication state.
/// Admin routing disabled — admin will be a separate app.
/// All users go directly to the regular user app.
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const PermissionSplashScreen(
      destination: MainNavigation(child: SizedBox()),
    );
  }
}
