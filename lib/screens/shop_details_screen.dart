import 'package:flutter/material.dart';
import 'package:wonwonw2/data/mock_shops.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class ShopDetailsScreen extends StatelessWidget {
  final RepairShop shop;
  final LatLng? userLocation;
  final Color mapAccentColor;

  const ShopDetailsScreen({
    Key? key,
    required this.shop,
    this.userLocation,
    required this.mapAccentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              // Header image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: mapAccentColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    shop.name,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  background: Image.network(shop.imageUrl, fit: BoxFit.cover),
                ),
                automaticallyImplyLeading: false,
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating and reviews
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            shop.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${shop.reviewCount} reviews)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Distance
                      if (userLocation != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions,
                                color: mapAccentColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _calculateDistance(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Categories
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children:
                              shop.categories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Chip(
                                    label: Text(category),
                                    backgroundColor: Colors.grey[200],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone
                      ListTile(
                        leading: Icon(Icons.phone, color: mapAccentColor),
                        title: Text(shop.phone),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _launchUrl('tel:${shop.phone}'),
                      ),

                      // Address
                      ListTile(
                        leading: Icon(Icons.location_on, color: mapAccentColor),
                        title: Text(shop.address),
                        contentPadding: EdgeInsets.zero,
                        onTap:
                            () => _launchUrl(
                              'https://www.google.com/maps/search/?api=1&query=${shop.location.latitude},${shop.location.longitude}',
                            ),
                      ),

                      // Opening hours
                      ListTile(
                        leading: Icon(Icons.access_time, color: mapAccentColor),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              shop.openingHours.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text('${entry.key}: ${entry.value}'),
                                );
                              }).toList(),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            context,
                            Icons.directions,
                            'directions'.tr(context),
                            () => _launchUrl(
                              'https://www.google.com/maps/dir/?api=1&destination=${shop.location.latitude},${shop.location.longitude}',
                            ),
                          ),
                          _buildActionButton(
                            context,
                            Icons.bookmark_border,
                            'save'.tr(context),
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('shop_saved'.tr(context)),
                                  backgroundColor: mapAccentColor,
                                ),
                              );
                            },
                          ),
                          _buildActionButton(
                            context,
                            Icons.share,
                            'share'.tr(context),
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'share_not_implemented'.tr(context),
                                  ),
                                  backgroundColor: mapAccentColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: mapAccentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: mapAccentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mapAccentColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  String _calculateDistance() {
    if (userLocation == null) return 'Unknown distance';

    // Calculate distance between user and shop
    const double earthRadius = 6371000; // in meters

    final lat1 = userLocation!.latitude * (pi / 180);
    final lon1 = userLocation!.longitude * (pi / 180);
    final lat2 = shop.location.latitude * (pi / 180);
    final lon2 = shop.location.longitude * (pi / 180);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    if (distance < 1000) {
      return '${distance.toInt()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
}
