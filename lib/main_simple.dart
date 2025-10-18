import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/screens/main_navigation.dart';

/// Simple main entry point for testing forgot password functionality
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    runApp(const SimpleWonWonApp());
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    runApp(const SimpleWonWonApp());
  }
}

class SimpleWonWonApp extends StatelessWidget {
  const SimpleWonWonApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WonWon Repair Finder',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: ThemeData(primarySwatch: Colors.brown, fontFamily: 'Roboto'),

      // Localization with fallback
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('th', '')],

      // Start with main navigation
      home: const MainNavigation(child: SizedBox()),
    );
  }
}
