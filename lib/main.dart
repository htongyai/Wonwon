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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Get stored locale
  final locale = await AppLocalizationsService.getLocale();

  runApp(MyApp(locale: locale));
}

class MyApp extends StatefulWidget {
  final Locale locale;

  const MyApp({super.key, required this.locale});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;

    // Listen for language changes
    AppLocalizationsService().localeStream.listen((locale) {
      setState(() {
        _locale = locale;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ServiceProvider(
      locationService: locationService,
      child: MaterialApp(
        title: AppConstants.appName,
        locale: _locale,
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('th', ''), // Thai
        ],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
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
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentColor,
              foregroundColor: AppConstants.darkColor,
            ),
          ),
          useMaterial3: true,
        ),
        builder: (context, child) {
          // Initialize ResponsiveSize on app start
          ResponsiveSize.init(context);

          // Apply responsive text scaling
          final mediaQuery = MediaQuery.of(context);
          final textScaler = MediaQuery.textScalerOf(context);

          // Limit maximum text scaling to prevent layout issues on very large font settings
          final constrainedTextScaler = textScaler.clamp(
            minScaleFactor: 0.8,
            maxScaleFactor: 1.2,
          );

          // Constrain app width on large screens to maintain mobile perspective
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: constrainedTextScaler),
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final bool isDesktop = screenWidth > 900;

                return Container(
                  decoration: BoxDecoration(
                    // Gradient background for desktop, solid color for mobile/tablet
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

                        // Define different max widths based on screen size
                        // For tablet (600-900): slightly wider than mobile (540px)
                        // For desktop (>900): slightly wider (560px) for better desktop experience
                        final double maxWidth =
                            screenWidth < 600
                                ? screenWidth
                                : screenWidth < 900
                                ? 540 // Slightly wider for tablets
                                : 560; // Slightly wider for desktop

                        return Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                isDesktop ? BorderRadius.circular(8) : null,
                            border:
                                isDesktop
                                    ? Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 1,
                                    )
                                    : null,
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
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
