import 'package:flutter/material.dart';
import 'package:wonwonw2/screens/login_screen.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/screens/home_screen.dart';
import 'package:wonwonw2/services/auth_state_service.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget that handles authentication state and determines which screen to show
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late AuthStateService _authStateService;
  AuthState? _currentState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authStateService = ServiceProvider.authStateOf(context);

    // Listen for auth state changes
    _authStateService.authStateStream.listen((state) {
      setState(() {
        _currentState = state;
      });
    });

    // Set initial state
    setState(() {
      _currentState = AuthState(
        isLoggedIn: _authStateService.isLoggedIn,
        isGuestMode: _authStateService.isGuestMode,
        hasSeenIntro: _authStateService.hasSeenIntro,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // If the auth state hasn't been determined yet, show a loading indicator
    if (_currentState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Always show the main app first regardless of login status
    // Users can access login-required features later if needed
    return const MainNavigation(child: HomeScreen());
  }
}

/// A widget that checks if a feature requires authentication and shows appropriate UI
class FeatureAuthGate extends StatelessWidget {
  final FeatureAccess featureAccess;
  final Widget child;
  final Widget? unauthorizedWidget;

  const FeatureAuthGate({
    Key? key,
    required this.featureAccess,
    required this.child,
    this.unauthorizedWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authStateService = ServiceProvider.authStateOf(context);

    if (authStateService.canAccessFeature(featureAccess)) {
      return child;
    }

    // If user cannot access the feature, show the unauthorized widget or a default one
    return unauthorizedWidget ??
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Login Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please login to access this feature',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final result = await context.push('/login');
                  if (result == true) {
                    (context as Element).markNeedsBuild();
                  }
                },
                child: const Text('Login'),
              ),
            ],
          ),
        );
  }
}
