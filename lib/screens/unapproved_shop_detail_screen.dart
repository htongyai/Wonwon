import 'package:flutter/material.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/utils/hours_formatter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UnapprovedShopDetailScreen extends StatelessWidget {
  final RepairShop shop;
  const UnapprovedShopDetailScreen({Key? key, required this.shop})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: false,
            floating: false,
            expandedHeight: 220,
            flexibleSpace: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'shop-image-${shop.id}',
                  child:
                      shop.photos.isNotEmpty
                          ? Image.network(
                            shop.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    AssetHelpers.getShopPlaceholder(
                                    shop.name,
                                    containerWidth: MediaQuery.of(context).size.width,
                                    containerHeight: 250,
                                  ),
                          )
                          : AssetHelpers.getShopPlaceholder(
                                    shop.name,
                                    containerWidth: MediaQuery.of(context).size.width,
                                    containerHeight: 250,
                                  ),
                ),
                Positioned(
                  top: 32,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.7),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Approve/Reject buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.white,
                          ),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Shop name and rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          shop.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            shop.rating.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppConstants.darkColor,
                            ),
                          ),
                          if (shop.reviewCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${shop.reviewCount})',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Categories
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        shop.categories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withOpacity(
                                0.13,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              category,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 18),
                  // Subservices
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.build, color: Colors.grey, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shop.subServices.values
                                  .expand((subs) => subs)
                                  .isNotEmpty
                              ? shop.subServices.values
                                      .expand((subs) => subs)
                                      .take(3)
                                      .join(', ') +
                                  (shop.subServices.values
                                              .expand((subs) => subs)
                                              .length >
                                          3
                                      ? '...'
                                      : '')
                              : 'No subservices',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shop.address,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Map section
                  if (shop.latitude != 0 && shop.longitude != 0)
                    Container(
                      height: 180,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(shop.latitude, shop.longitude),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(shop.id),
                              position: LatLng(shop.latitude, shop.longitude),
                            ),
                          },
                          zoomControlsEnabled: false,
                          myLocationButtonEnabled: false,
                          liteModeEnabled: true,
                        ),
                      ),
                    ),
                  // Payment methods
                  if (shop.paymentMethods != null &&
                      shop.paymentMethods!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Methods',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppConstants.darkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              shop.paymentMethods!.map((method) {
                                IconData icon;
                                Color color;
                                switch (method.toLowerCase()) {
                                  case 'cash':
                                    icon = Icons.money;
                                    color = Colors.green;
                                    break;
                                  case 'credit_card':
                                    icon = Icons.credit_card;
                                    color = Colors.blue;
                                    break;
                                  case 'debit_card':
                                    icon = Icons.credit_card;
                                    color = Colors.blue;
                                    break;
                                  case 'promptpay':
                                    icon = Icons.qr_code;
                                    color = Colors.purple;
                                    break;
                                  case 'true_money':
                                    icon = Icons.account_balance_wallet;
                                    color = Colors.orange;
                                    break;
                                  case 'line_pay':
                                    icon = Icons.chat;
                                    color = Colors.green;
                                    break;
                                  default:
                                    icon = Icons.payment;
                                    color = Colors.grey;
                                }
                                return Chip(
                                  avatar: Icon(icon, color: color, size: 18),
                                  label: Text(method),
                                  backgroundColor: Colors.grey[100],
                                  labelStyle: GoogleFonts.montserrat(
                                    fontSize: 13,
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  // Opening hours
                  if (shop.hours.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Opening Hours',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppConstants.darkColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...shop.hours.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    entry.key,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  HoursFormatter.formatHours(
                                    entry.value,
                                    context,
                                  ),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 18),
                      ],
                    ),
                  // Additional info (optional fields)
                  if (shop.soi != null && shop.soi!.isNotEmpty)
                    _infoRow('Soi', shop.soi!),
                  if (shop.district != null && shop.district!.isNotEmpty)
                    _infoRow('District', shop.district!),
                  if (shop.province != null && shop.province!.isNotEmpty)
                    _infoRow('Province', shop.province!),
                  if (shop.lineId != null && shop.lineId!.isNotEmpty)
                    _infoRow('Line ID', shop.lineId!),
                  if (shop.facebookPage != null &&
                      shop.facebookPage!.isNotEmpty)
                    _infoRow('Facebook', shop.facebookPage!),
                  if (shop.instagramPage != null &&
                      shop.instagramPage!.isNotEmpty)
                    _infoRow('Instagram', shop.instagramPage!),
                  if (shop.otherContacts != null &&
                      shop.otherContacts!.isNotEmpty)
                    _infoRow('Other Contacts', shop.otherContacts!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
