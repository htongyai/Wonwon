import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

// Shared package imports
import 'package:shared/firebase_options.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:shared/config/web_config.dart';
import 'package:shared/utils/performance_utils.dart';
import 'package:shared/state/app_state_manager.dart';
import 'package:shared/services/service_manager.dart';
import 'package:shared/services/cache_service.dart';
import 'package:shared/services/version_service.dart';
import 'package:shared/services/auth_manager.dart';
import 'package:shared/services/analytics_service.dart';
import 'package:shared/services/service_providers.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:shared/widgets/force_update_checker.dart';

// Dashboard-specific imports
import 'package:wonwon_dashboard/localization/app_localizations.dart';
import 'package:wonwon_dashboard/widgets/auth_gate.dart';
import 'package:shared/utils/remove_loading_stub.dart'
    if (dart.library.html) 'package:shared/utils/remove_loading_web.dart';

void main() async {
  PerformanceUtils.startMeasurement('app_startup');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      usePathUrlStrategy();
      WebPerformance.startMeasurement('web_init');
    }

    await Future.wait([
      PerformanceUtils.measureAsync(
        'firebase_init',
        () => Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
      ),
    ]);

    await AuthManager().initialize();
    PerformanceUtils.endMeasurement('app_startup');

    runApp(const WonWonDashboardApp());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeHtmlLoadingElement();
    });

    _deferredInitialization();
  } catch (e) {
    if (kIsWeb) {
      WebConfig.handleWebError(e, StackTrace.current);
    }
    appLog('Dashboard initialization error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                const Text('Dashboard initialization failed', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Please refresh the page', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeHtmlLoadingElement();
    });
  }
}

Future<void> _deferredInitialization() async {
  try {
    await Future.wait([
      ServiceManager().initialize(),
      CacheService().initialize(),
      VersionService().checkAndHandleVersionUpdate(),
      authStateService.initialize(),
    ]);
    await AppStateManager().initialize();
  } catch (e) {
    appLog('Deferred initialization error: $e');
  }
}

class WonWonDashboardApp extends StatelessWidget {
  const WonWonDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
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
              title: 'WonWon Admin Dashboard',
              debugShowCheckedModeBanner: false,
              navigatorObservers: [AnalyticsService().observer],
              theme: _buildTheme(false),
              darkTheme: _buildTheme(true),
              themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              locale: Locale(appState.currentLanguage),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en', ''), Locale('th', '')],
              home: const ForceUpdateChecker(child: AdminAuthGate()),
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme(bool isDark) {
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: AppConstants.primaryColor,
            secondary: AppConstants.primaryColor,
            surface: const Color(0xFF1E1E1E),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.white,
          )
        : ColorScheme.light(
            primary: AppConstants.primaryColor,
            secondary: AppConstants.primaryColor,
            surface: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black87,
            outline: Colors.grey.shade300,
            surfaceContainerHighest: Colors.grey.shade50,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme().apply(
        fontFamily: 'Roboto',
        bodyColor: isDark ? Colors.white : Colors.black87,
        displayColor: isDark ? Colors.white : Colors.black87,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppConstants.primaryColor),
    );
  }
}
