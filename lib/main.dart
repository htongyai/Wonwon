import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/main_navigation.dart';
import 'package:wonwonw2/screens/splash_screen.dart';
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

/// Entry point for the WonWon Repair Finder application
/// Initializes app services and configurations before launching the UI
void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Web specific configuration
  if (kIsWeb) {
    // Use URL path strategy instead of hash strategy for cleaner URLs
    setUrlStrategy(PathUrlStrategy());
  }

  // Lock the app to portrait orientation only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
      // Provide location services to the entire app
      locationService: locationService,
      child: MaterialApp(
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
            seedColor: AppConstants.primaryColor,
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

                        // Calculate the maximum width for the app container based on screen size
                        // This ensures proper display across different device types
                        final double maxWidth =
                            screenWidth < 600
                                ? screenWidth // Full width on phones
                                : screenWidth < 900
                                ? 540 // Slightly wider for tablets
                                : 560; // Slightly wider for desktop

                        // Create a container with appropriate styling and constraints
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
        // Set the initial screen to the splash screen
        home: const SplashScreen(),
        // Remove the debug banner
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
