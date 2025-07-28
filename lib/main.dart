import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/screens/signup_screen.dart';
import 'package:wonwonw2/screens/splash_screen.dart';
import 'package:wonwonw2/screens/desktop_splash_screen.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator_web/geolocator_web.dart'
    if (dart.library.io) 'dart:io';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:wonwonw2/services/auth_state_service.dart';
import 'package:go_router/go_router.dart';
import 'screens/shop_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/saved_locations_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_manage_shops_screen.dart';
import 'screens/admin_manage_users_screen.dart';
import 'screens/admin_unapprove_pages_screen.dart';
import 'screens/admin_reports_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/forum_screen.dart';
import 'screens/forum_create_topic_screen.dart';
import 'screens/forum_topic_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/terms_of_use_screen.dart';
import 'screens/privacy_policy_screen.dart';

/// Entry point for the WonWon Repair Finder application
/// Initializes app services and configurations before launching the UI
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Web specific configuration
  if (kIsWeb) {
    // Use URL path strategy instead of hash strategy for cleaner URLs
    setUrlStrategy(PathUrlStrategy());

    // Initialize web renderer settings
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure web renderer
    await Future.delayed(Duration.zero); // Ensure web renderer is ready
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Initialize AuthStateService
  await authStateService.initialize();

  // Lock the app to portrait orientation only for mobile devices
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Retrieve the user's preferred language setting from local storage
  final locale = await AppLocalizationsService.getLocale();

  // Launch the app with the retrieved locale
  runApp(MyApp(locale: locale));
}

/// Root widget of the application
/// Manages global state, theming, and internationalization
class MyApp extends StatefulWidget {
  // The user's preferred locale/language setting
  final Locale locale;

  const MyApp({super.key, required this.locale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Default to English locale if none is provided
  Locale _locale = const Locale('en');

  late final GoRouter _router = GoRouter(
    redirect: (context, state) {
      // Show splash screen for initial load
      if (state.uri.path == '/') {
        return '/splash';
      }
      return null;
    },
    routes: [
      // Splash screen route
      GoRoute(
        path: '/splash',
        builder: (context, state) {
          // Use desktop splash screen for desktop layout
          if (ResponsiveSize.shouldShowDesktopLayout()) {
            return const DesktopSplashScreen();
          }
          return const SplashScreen();
        },
      ),
      // Standalone routes (outside of ShellRoute)
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/terms-of-use',
        builder: (context, state) => const TermsOfUseScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/shops/:shopId',
        builder: (context, state) {
          final shopId = state.pathParameters['shopId']!;
          return ShopDetailScreen(shopId: shopId);
        },
      ),
      // Forum routes (outside ShellRoute for standalone screens)
      GoRoute(
        path: '/forum/create',
        builder: (context, state) => const ForumCreateTopicScreen(),
      ),
      GoRoute(
        path: '/forum/topic/:topicId',
        builder: (context, state) {
          final topicId = state.pathParameters['topicId']!;
          return ForumTopicDetailScreen(topicId: topicId);
        },
      ),
      // ShellRoute for main navigation
      ShellRoute(
        builder: (context, state, child) {
          // Get the current path to determine the active tab
          final path = state.uri.path;
          int initialIndex = 0;

          if (path.startsWith('/map')) {
            initialIndex = 1;
          } else if (path.startsWith('/saved')) {
            initialIndex = 2;
          } else if (path.startsWith('/profile')) {
            initialIndex = 3;
          } else if (path.startsWith('/forum')) {
            initialIndex = 4;
          } else if (path.startsWith('/admin/dashboard')) {
            initialIndex = 5;
          } else if (path.startsWith('/admin/manage-shops')) {
            initialIndex = 6;
          } else if (path.startsWith('/admin/manage-users')) {
            initialIndex = 7;
          } else if (path.startsWith('/admin/unapprove-pages')) {
            initialIndex = 8;
          } else if (path.startsWith('/admin/reports')) {
            initialIndex = 9;
          }

          return MainNavigation(initialIndex: initialIndex, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const SavedLocationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/forum',
            builder: (context, state) => const ForumScreen(),
          ),
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/manage-shops',
            builder: (context, state) => const AdminManageShopsScreen(),
          ),
          GoRoute(
            path: '/admin/manage-users',
            builder: (context, state) => const AdminManageUsersScreen(),
          ),
          GoRoute(
            path: '/admin/unapprove-pages',
            builder: (context, state) => const AdminUnapprovePagesScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );

  @override
  void initState() {
    super.initState();
    // Set the locale from the widget parameter
    _locale = widget.locale;

    // Subscribe to locale changes to update the UI when language changes
    AppLocalizationsService().localeStream.listen((locale) {
      setState(() {
        _locale = locale;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ServiceProvider(
      // Provide services to the entire app
      locationService: locationService,
      authStateService: authStateService,
      child: MaterialApp.router(
        title: AppConstants.appName,
        locale: _locale,
        // Define supported languages (English and Thai)
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('th', ''), // Thai
        ],
        // Register localization delegates for app-wide translation support
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // App-wide theme configuration
        theme: ThemeData(
          // Create a consistent color scheme based on the app's primary color
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC3C130),
            primary: AppConstants.primaryColor,
            secondary: AppConstants.accentColor,
            tertiary: AppConstants.tertiaryColor,
            surface: Colors.white,
            background: Colors.white,
            onPrimary: Colors.white,
            onSecondary: AppConstants.darkColor,
            onTertiary: AppConstants.darkColor,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          cardColor: Colors.white,
          // AppBar styling
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: AppConstants.primaryTextColor,
            titleTextStyle: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.darkColor,
            ),
          ),
          // Button styling
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: AppConstants.darkColor,
            ),
          ),
          useMaterial3: true,
        ),
        // Custom builder to handle responsive layout and text scaling
        builder: (context, child) {
          // Initialize responsive sizing utility
          ResponsiveSize.init(context);

          // Get current media query and text scaling
          final mediaQuery = MediaQuery.of(context);
          final textScaler = MediaQuery.textScalerOf(context);

          // Constrain text scaling to prevent layout issues with very large font settings
          final constrainedTextScaler = textScaler.clamp(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.2,
          );

          // Apply constrained text scaling to the app
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: constrainedTextScaler),
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Determine if we're on a desktop-sized screen
                final bool isDesktop = screenWidth > 900;

                // Create a container with appropriate styling based on device size
                return Container(
                  decoration: BoxDecoration(
                    // Apply gradient background for desktop, solid color for mobile/tablet
                    gradient:
                        isDesktop
                            ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFF8F8F8), Color(0xFFEEEEEE)],
                            )
                            : null,
                    color: isDesktop ? null : const Color(0xFFF5F5F5),
                  ),
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        // Get the current screen width
                        final screenWidth = MediaQuery.of(context).size.width;

                        // For desktop, use full width; for mobile/tablet, use constrained width
                        final double maxWidth =
                            ResponsiveSize.shouldShowDesktopLayout()
                                ? screenWidth // Full width for desktop
                                : screenWidth < 600
                                ? screenWidth // Full width on phones
                                : screenWidth < 900
                                ? 540 // Slightly wider for tablets
                                : 560; // Slightly wider for smaller desktop

                        // For desktop, use full width without container constraints
                        if (ResponsiveSize.shouldShowDesktopLayout()) {
                          return child!;
                        }

                        // For mobile/tablet, use constrained container
                        return Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            // Apply rounded corners only on desktop
                            borderRadius:
                                isDesktop ? BorderRadius.circular(8) : null,
                            // Apply border only on desktop
                            border:
                                isDesktop
                                    ? Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 1,
                                    )
                                    : null,
                            // Apply shadow with different intensity based on device type
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDesktop ? 0.1 : 0.05,
                                ),
                                blurRadius: isDesktop ? 20 : 10,
                                spreadRadius: isDesktop ? 1 : 0,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: child!,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Page not found', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
