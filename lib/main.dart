import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

// Analytics
import 'package:wonwonw2/services/analytics_service.dart';

// Screens
import 'package:wonwonw2/widgets/auth_gate.dart';
import 'package:wonwonw2/services/service_providers.dart';
import 'package:wonwonw2/utils/remove_loading_stub.dart'
    if (dart.library.html) 'package:wonwonw2/utils/remove_loading_web.dart';

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

    // Initialize Firebase + locale in parallel (both required before first paint)
    late final Locale initialLocale;
    await Future.wait([
      PerformanceUtils.measureAsync(
        'firebase_init',
        () => Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
      ),
      (() async {
        try {
          if (WebConfig.isAdminOnlyDeployment) {
            initialLocale = const Locale('en');
          } else {
            initialLocale = await AppLocalizationsService.getLocale();
          }
        } catch (e) {
          debugPrint('Failed to load locale, using default: $e');
          initialLocale = const Locale('th');
        }
      })(),
    ]);

    // Only AuthManager is critical before first paint
    await AuthManager().initialize();

    // End startup measurement
    PerformanceUtils.endMeasurement('app_startup');

    // Launch app immediately - show UI as fast as possible
    runApp(OptimizedWonWonApp(initialLocale: initialLocale));

    // Remove HTML loading splash after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeHtmlLoadingElement();
    });

    // Defer non-critical initialization to after first paint
    _deferredInitialization();
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
                const Text(
                  'App initialization failed',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text('Please refresh the page', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
    // Must remove the HTML loading overlay even on failure, otherwise it
    // covers the error UI and the app appears permanently stuck.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeHtmlLoadingElement();
    });
  }
}

/// Deferred initialization for non-critical services.
/// Runs after first paint so the app appears instantly.
Future<void> _deferredInitialization() async {
  try {
    // These can all run in parallel after the UI is visible
    await Future.wait([
      ServiceManager().initialize(),
      CacheService().initialize(),
      VersionService().checkAndHandleVersionUpdate(),
      authStateService.initialize(),
    ]);

    // AppStateManager depends on ServiceManager being ready
    await AppStateManager().initialize();
  } catch (e) {
    debugPrint('Deferred initialization error: $e');
  }
}

/// Optimized main application widget
class OptimizedWonWonApp extends StatelessWidget {
  final Locale initialLocale;

  const OptimizedWonWonApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    // All singletons are already initialized in _initializeServices;
    // .value exposes the existing instances without creating new ones.
    return ServiceProvider(
      locationService: locationService,
      authStateService: authStateService,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: AppStateManager()),
          Provider.value(value: ServiceManager()),
          Provider.value(value: CacheService()),
          Provider.value(value: AuthManager()),
        ],
        child: Consumer<AppStateManager>(
          builder: (context, appState, child) {
            return MaterialApp(
              title: WebConfig.getAppTitle(),
              debugShowCheckedModeBanner: false,

              // Analytics - automatic screen tracking
              navigatorObservers: [AnalyticsService().observer],

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
              supportedLocales: const [Locale('th', ''), Locale('en', '')],
              localeResolutionCallback: (locale, supportedLocales) {
                return initialLocale;
              },

              home: const AuthGate(),
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
              onPrimary: Colors.white,
              onSecondary: Colors.white,
              onSurface: Colors.white,
            )
            : ColorScheme.light(
              primary: AppConstants.primaryColor, // Green accent only
              secondary: AppConstants.primaryColor, // Green accent only
              surface: Colors.white, // Pure white surface
              onPrimary: Colors.white, // White text on green
              onSecondary: Colors.white, // White text on green
              onSurface: Colors.black87, // Dark text on white
              outline: Colors.grey.shade300, // Light grey borders
              surfaceContainerHighest: Colors.grey.shade50, // Very light grey for cards
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

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppConstants.primaryColor.withAlpha(25),
        labelStyle: const TextStyle(color: Colors.black87),
        side: BorderSide(color: Colors.grey.shade300),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppConstants.primaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppConstants.primaryColor.withAlpha(76);
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

}
