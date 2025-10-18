import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';

class ShopApprovalScreen extends StatefulWidget {
  const ShopApprovalScreen({Key? key}) : super(key: key);

  @override
  State<ShopApprovalScreen> createState() => _ShopApprovalScreenState();
}

class _ShopApprovalScreenState extends State<ShopApprovalScreen> {
  final ShopService _shopService = ShopService();
  List<RepairShop> _unapprovedShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnapprovedShops();
  }

  Future<void> _loadUnapprovedShops() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final shops = await _shopService.getUnapprovedShops();

      if (mounted) {
        setState(() {
          _unapprovedShops = shops;
          _isLoading = false;
        });
      }
    } catch (e) {
      appLog('Error loading unapproved shops: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_unapprovedShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No shops pending approval',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All shops have been reviewed',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUnapprovedShops,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unapprovedShops.length,
        itemBuilder: (context, index) {
          final shop = _unapprovedShops[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ShopDetailScreen(shopId: shop.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop image
                  Hero(
                    tag: 'shop-image-${shop.id}',
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child:
                            shop.photos.isNotEmpty
                                ? Image.network(
                                  shop.photos.first,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Container(color: Colors.grey[200]),
                                )
                                : Container(color: Colors.grey[200]),
                      ),
                    ),
                  ),
                  // Shop details
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and rating row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop.name,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.darkColor,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppConstants.darkColor,
                                  ),
                                ),
                                if (shop.reviewCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${shop.reviewCount})',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Categories under name
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              shop.categories.map((category) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor
                                        .withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppConstants.primaryColor,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 10),
                        // Subservices available
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.build,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
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
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                shop.address,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // View Details button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          ShopDetailScreen(shopId: shop.id),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'View Details',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
