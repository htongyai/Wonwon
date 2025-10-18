import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Removed go_router import - using basic navigation
import 'package:provider/provider.dart';

// Core imports
import 'firebase_options.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/utils/performance_utils.dart';
import 'package:wonwonw2/config/web_config.dart';

// State management
import 'package:wonwonw2/state/app_state_manager.dart';
import 'package:wonwonw2/services/service_manager.dart';
import 'package:wonwonw2/services/cache_service.dart';
import 'package:wonwonw2/services/version_service.dart';
import 'package:wonwonw2/services/auth_manager.dart';

// Screens
import 'package:wonwonw2/widgets/auth_gate.dart';
import 'package:wonwonw2/services/service_providers.dart';

/// Optimized entry point for the WonWon Repair Finder application
void main() async {
  // Start performance measurement
  PerformanceUtils.startMeasurement('app_startup');

  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Configure URL strategy for web
    if (kIsWeb) {
      usePathUrlStrategy();
      WebPerformance.startMeasurement('web_init');
    }

    // Initialize Firebase
    await PerformanceUtils.measureAsync(
      'firebase_init',
      () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    );

    // Check for version updates and clear cache if needed
    await PerformanceUtils.measureAsync(
      'version_check',
      () => VersionService().checkAndHandleVersionUpdate(),
    );

    // Initialize core services
    await PerformanceUtils.measureAsync(
      'services_init',
      () => _initializeServices(),
    );

    // Get initial locale with fallback
    Locale initialLocale;
    try {
      // Force English for admin deployments
      if (WebConfig.isAdminOnlyDeployment) {
        initialLocale = const Locale('en');
      } else {
        initialLocale = await AppLocalizationsService.getLocale();
      }
    } catch (e) {
      debugPrint('Failed to load locale, using default: $e');
      initialLocale = const Locale('en'); // Fallback to English
    }

    // End startup measurement
    PerformanceUtils.endMeasurement('app_startup');

    // Launch app
    runApp(OptimizedWonWonApp(initialLocale: initialLocale));
  } catch (e) {
    // Handle initialization errors gracefully
    if (kIsWeb) {
      WebConfig.handleWebError(e, StackTrace.current);
    }
    debugPrint('App initialization error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'App initialization failed',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text('Please refresh the page', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initialize all core services
Future<void> _initializeServices() async {
  final serviceManager = ServiceManager();
  final cacheService = CacheService();
  final appStateManager = AppStateManager();
  final authManager = AuthManager();

  // Initialize services in parallel where possible
  await Future.wait([
    serviceManager.initialize(),
    cacheService.initialize(),
    authManager.initialize(),
  ]);

  // Initialize app state (depends on services)
  await appStateManager.initialize();
}

/// Optimized main application widget
class OptimizedWonWonApp extends StatelessWidget {
  final Locale initialLocale;

  const OptimizedWonWonApp({Key? key, required this.initialLocale})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ServiceProvider(
      locationService: locationService,
      authStateService: authStateService,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateManager()),
          Provider(create: (_) => ServiceManager()),
          Provider(create: (_) => CacheService()),
          Provider(create: (_) => AuthManager()),
        ],
        child: Consumer<AppStateManager>(
          builder: (context, appState, child) {
            return PerformanceMonitorWidget(
              showOverlay: kDebugMode && !kIsWeb, // Hide overlay on web
              child: MaterialApp(
                title: WebConfig.getAppTitle(),
                debugShowCheckedModeBanner: false,

                // Theme configuration
                theme: _buildTheme(false),
                darkTheme: _buildTheme(true),
                themeMode:
                    appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

                // Localization
                locale: initialLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en', ''), Locale('th', '')],

                // Basic routing with authentication check
                home: const AuthGate(),

                // Performance optimizations
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(
                        kIsWeb ? 1.0 : 1.0, // Consistent scaling for web
                      ),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build optimized theme with white background and green accents only
  ThemeData _buildTheme(bool isDark) {
    // Create a custom color scheme with white background and green accents
    final colorScheme =
        isDark
            ? ColorScheme.dark(
              primary: AppConstants.primaryColor, // Green accent
              secondary: AppConstants.primaryColor, // Green accent
              surface: const Color(0xFF1E1E1E), // Dark surface for dark mode
              background: const Color(
                0xFF121212,
              ), // Dark background for dark mode
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.white,
              onBackground: Colors.white,
            )
            : ColorScheme.light(
              primary: AppConstants.primaryColor, // Green accent only
              secondary: AppConstants.primaryColor, // Green accent only
              surface: Colors.white, // Pure white surface
              background: Colors.white, // Pure white background
              onPrimary: Colors.white, // White text on green
              onSecondary: Colors.white, // White text on green
              onSurface: Colors.black87, // Dark text on white
              onBackground: Colors.black87, // Dark text on white
              outline: Colors.grey.shade300, // Light grey borders
              surfaceVariant: Colors.grey.shade50, // Very light grey for cards
            );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,

      // Performance optimizations
      visualDensity:
          kIsWeb
              ? VisualDensity.standard
              : VisualDensity.adaptivePlatformDensity,

      // Typography optimized for web
      textTheme: const TextTheme().apply(
        fontFamily: kIsWeb ? WebConstants.primaryFontWeb : 'Roboto',
        bodyColor: isDark ? Colors.white : Colors.black87,
        displayColor: isDark ? Colors.white : Colors.black87,
      ),

      // Component themes
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor, // Green accent
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Bottom navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppConstants.primaryColor, // Green accent
        unselectedItemColor: Colors.grey.shade600,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor, // Green accent
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppConstants.primaryColor.withOpacity(0.1),
        labelStyle: const TextStyle(color: Colors.black87),
        side: BorderSide(color: Colors.grey.shade300),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppConstants.primaryColor; // Green accent
          }
          return Colors.grey.shade400;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppConstants.primaryColor.withOpacity(0.3);
          }
          return Colors.grey.shade300;
        }),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppConstants.primaryColor, // Green accent
      ),
    );
  }

  // Removed GoRouter configuration - using basic navigation
}

/// Error app for initialization failures
class ErrorApp extends StatelessWidget {
  const ErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WonWon - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please refresh the page'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (kIsWeb) {
                    // For web, reload the page
                    // In a real implementation, you'd use dart:html
                    // html.window.location.reload();
                  } else {
                    SystemNavigator.pop();
                  }
                },
                child: Text(kIsWeb ? 'Refresh' : 'Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
