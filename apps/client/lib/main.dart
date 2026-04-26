import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
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

// Client-specific imports
import 'package:wonwon_client/localization/app_localizations.dart';
import 'package:wonwon_client/widgets/auth_gate.dart';
import 'package:shared/utils/remove_loading_stub.dart'
    if (dart.library.html) 'package:shared/utils/remove_loading_web.dart';

void main() async {
  PerformanceUtils.startMeasurement('app_startup');
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  try {
    if (kIsWeb) {
      usePathUrlStrategy();
      WebPerformance.startMeasurement('web_init');
    }

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
          initialLocale = await AppLocalizationsService.getLocale();
        } catch (e) {
          appLog('Failed to load locale, using default: $e');
          initialLocale = const Locale('th');
        }
      })(),
    ]);

    PerformanceUtils.endMeasurement('app_startup');

    runApp(WonWonClientApp(initialLocale: initialLocale));

    // Remove loading overlay as soon as first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removeHtmlLoadingElement();
    });

    // All non-critical init runs AFTER first frame
    _deferredInitialization();
  } catch (e) {
    if (kIsWeb) {
      WebConfig.handleWebError(e, StackTrace.current);
    }
    appLog('App initialization error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                const Text('App initialization failed', style: TextStyle(fontSize: 18)),
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
      AuthManager().initialize(),
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

class WonWonClientApp extends StatelessWidget {
  final Locale initialLocale;

  const WonWonClientApp({super.key, required this.initialLocale});

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
            return StreamBuilder<Locale>(
              stream: AppLocalizationsService().localeStream,
              initialData: initialLocale,
              builder: (context, snapshot) {
                final currentLocale = snapshot.data ?? initialLocale;
                return MaterialApp(
                  title: 'WonWon Repair Finder',
                  debugShowCheckedModeBanner: false,
                  navigatorObservers: [AnalyticsService().observer],
                  theme: _buildTheme(false),
                  darkTheme: _buildTheme(true),
                  themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  locale: currentLocale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [Locale('th', ''), Locale('en', '')],
                  localeResolutionCallback: (locale, supportedLocales) {
                    return currentLocale;
                  },
                  home: const ForceUpdateChecker(child: AuthGate()),
                );
              },
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

    // Palette derived from isDark — every sub-theme below should use these
    // rather than hardcoded Colors.white / Colors.black87. That's why the
    // dark-mode toggle previously only flipped scaffold + body text but left
    // the app bar, cards, chips, and bottom nav frozen light.
    final Color surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color onSurface = isDark ? Colors.white : Colors.black87;
    final Color borderColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade200;
    final Color inputBorder =
        isDark ? Colors.white.withValues(alpha: 0.18) : Colors.grey.shade300;
    final Color chipBg =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100;
    final Color unselected =
        isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      visualDensity: kIsWeb ? VisualDensity.standard : VisualDensity.adaptivePlatformDensity,
      textTheme: const TextTheme().apply(
        fontFamily: kIsWeb ? WebConstants.primaryFontWeb : 'Roboto',
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
            color: onSurface, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1),
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
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: inputBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: unselected,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: AppConstants.primaryColor.withAlpha(25),
        labelStyle: TextStyle(color: onSurface),
        side: BorderSide(color: inputBorder),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppConstants.primaryColor;
          return isDark ? Colors.grey.shade500 : Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppConstants.primaryColor.withAlpha(76);
          return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
            color: onSurface, fontSize: 18, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: onSurface, fontSize: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppConstants.primaryColor),
      // Force the same border color we use everywhere so default
      // `Divider()` widgets don't pop bright in dark mode (M3's
      // outlineVariant default is too light against #1E1E1E cards).
      dividerColor: borderColor,
      dividerTheme: DividerThemeData(
        color: borderColor,
        space: 0,
        thickness: 0.5,
      ),
    );
  }
}
