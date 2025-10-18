import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Core imports
import 'firebase_options.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/services/app_localizations_service.dart'
    as locale_service;
import 'package:wonwonw2/utils/performance_utils.dart';

// State management
import 'package:wonwonw2/state/app_state_manager.dart';
import 'package:wonwonw2/services/service_manager.dart';
import 'package:wonwonw2/services/cache_service.dart';

// Screens
import 'package:wonwonw2/screens/main_navigation.dart';

/// Optimized entry point for the WonWon Repair Finder application
void main() async {
  // Start performance measurement
  PerformanceUtils.startMeasurement('app_startup');

  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Configure URL strategy for web
    if (kIsWeb) {
      usePathUrlStrategy();
    }

    // Initialize Firebase
    await PerformanceUtils.measureAsync(
      'firebase_init',
      () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
    );

    // Initialize core services
    await PerformanceUtils.measureAsync(
      'services_init',
      () => _initializeServices(),
    );

    // Get initial locale
    final localeCode = await locale_service.AppLocalizationsService.getLocale();
    final initialLocale = Locale(localeCode);

    // End startup measurement
    PerformanceUtils.endMeasurement('app_startup');

    // Launch app
    runApp(OptimizedWonWonApp(initialLocale: initialLocale));
  } catch (e) {
    // Handle initialization errors gracefully
    debugPrint('App initialization error: $e');
    runApp(const ErrorApp());
  }
}

/// Initialize all core services
Future<void> _initializeServices() async {
  final serviceManager = ServiceManager();
  final cacheService = CacheService();
  final appStateManager = AppStateManager();

  // Initialize services in parallel where possible
  await Future.wait([serviceManager.initialize(), cacheService.initialize()]);

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateManager()),
        Provider(create: (_) => ServiceManager()),
        Provider(create: (_) => CacheService()),
      ],
      child: Consumer<AppStateManager>(
        builder: (context, appState, child) {
          return PerformanceMonitorWidget(
            showOverlay: kDebugMode,
            child: MaterialApp(
              title: 'WonWon Repair Finder',
              debugShowCheckedModeBanner: false,

              // Theme configuration
              theme: _buildTheme(false),
              darkTheme: _buildTheme(true),
              themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,

              // Localization
              locale: Locale(appState.currentLanguage),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en', ''), Locale('th', '')],

              // Home screen
              home: const MainNavigation(child: SizedBox()),

              // Performance optimizations
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      1.0,
                    ), // Prevent text scaling issues
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Build optimized theme
  ThemeData _buildTheme(bool isDark) {
    final colorScheme =
        isDark
            ? ColorScheme.fromSeed(
              seedColor: AppConstants.primaryColor,
              brightness: Brightness.dark,
            )
            : ColorScheme.fromSeed(
              seedColor: AppConstants.primaryColor,
              brightness: Brightness.light,
            );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Performance optimizations
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Typography
      textTheme: const TextTheme().apply(
        fontFamily: 'Roboto', // Use system font for better performance
      ),

      // Component themes
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
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
              const Text('Please restart the application'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  SystemNavigator.pop();
                },
                child: const Text('Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
