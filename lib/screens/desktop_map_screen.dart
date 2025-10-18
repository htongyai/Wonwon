import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/screens/map_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DesktopMapScreen extends StatefulWidget {
  const DesktopMapScreen({Key? key}) : super(key: key);

  @override
  _DesktopMapScreenState createState() => _DesktopMapScreenState();
}

class _DesktopMapScreenState extends State<DesktopMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.mapLocationDot,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  'Map View',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkColor,
                  ),
                ),
                const Spacer(),
                // Map controls
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Zoom in functionality
                      },
                      icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                      label: const Text('Zoom In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Zoom out functionality
                      },
                      icon: const FaIcon(FontAwesomeIcons.minus, size: 14),
                      label: const Text('Zoom Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: AppConstants.darkColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // My location functionality
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.locationDot,
                        size: 14,
                      ),
                      label: const Text('My Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: AppConstants.darkColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map content
          Expanded(
            child: Container(color: Colors.white, child: const MapScreen()),
          ),
        ],
      ),
    );
  }
}
