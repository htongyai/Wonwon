import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/home_screen.dart';
import 'package:wonwonw2/screens/map_screen.dart';
import 'package:wonwonw2/screens/saved_locations_screen.dart';
import 'package:wonwonw2/utils/responsive_size.dart';
import 'package:wonwonw2/widgets/custom_navigation_bar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const SavedLocationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Initialize ResponsiveSize if needed
    if (ResponsiveSize.screenWidth == 0) {
      ResponsiveSize.init(context);
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
