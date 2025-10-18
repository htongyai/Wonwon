import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/screens/admin_dashboard_main_screen.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/services/auth_service.dart';
import 'package:wonwonw2/config/web_config.dart';

/// Widget that determines the initial screen based on authentication state
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check deployment mode first - handle each mode completely
        if (WebConfig.isAdminOnlyDeployment) {
          // Admin-only deployment: require login and admin privileges
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen(isAdminFlow: true);
          }

          return FutureBuilder<bool>(
            future: AuthService().isAdmin(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Only allow admin users in admin-only deployment
              if (adminSnapshot.data == true) {
                return const AdminDashboardMainScreen();
              } else {
                // Non-admin users get access denied
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Admin Portal Access Only',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('This deployment is for administrators only.'),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        }

        if (WebConfig.isUserOnlyDeployment) {
          // User-only deployment: always go directly to user interface
          // No login required - MainNavigation handles auth internally
          return const MainNavigation(child: SizedBox());
        }

        // Auto mode (mixed deployment): default to user interface for guest users
        if (!snapshot.hasData || snapshot.data == null) {
          return const MainNavigation(child: SizedBox());
        }

        // User is logged in in auto mode, route based on their role
        return FutureBuilder<bool>(
          future: AuthService().isAdmin(),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If user is admin, go to admin dashboard
            if (adminSnapshot.data == true) {
              return const AdminDashboardMainScreen();
            }

            // Regular user, go to main app
            return const MainNavigation(child: SizedBox());
          },
        );
      },
    );
  }
}
