import 'package:flutter/material.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/localization/app_localizations.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'unapproved_shop_detail_screen.dart';

class UnapprovedShopsScreen extends StatefulWidget {
  const UnapprovedShopsScreen({Key? key}) : super(key: key);

  @override
  State<UnapprovedShopsScreen> createState() => _UnapprovedShopsScreenState();
}

class _UnapprovedShopsScreenState extends State<UnapprovedShopsScreen> {
  final ShopService _shopService = ShopService();
  List<RepairShop> _unapprovedShops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnapprovedShops();
  }

  Future<void> _loadUnapprovedShops() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final shops = await _shopService.getUnapprovedShops();
      setState(() {
        _unapprovedShops = shops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading unapproved shops: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveShop(RepairShop shop) async {
    try {
      final success = await _shopService.approveShop(shop.id);
      if (success) {
        setState(() {
          _unapprovedShops.removeWhere((s) => s.id == shop.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${shop.name} has been approved'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve ${shop.name}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving shop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('unapproved_shops'.tr(context)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _unapprovedShops.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No unapproved shops',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
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
                        onTap: () async {
                          final approved = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      UnapprovedShopDetailScreen(shop: shop),
                            ),
                          );
                          if (approved == true) {
                            _approveShop(shop);
                          }
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
                                                    Container(
                                                      color: Colors.grey[200],
                                                    ),
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
                                          style: TextStyle(
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppConstants.darkColor,
                                            ),
                                          ),
                                          if (shop.reviewCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              '(${shop.reviewCount})',
                                              style: TextStyle(
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Text(
                                              category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    AppConstants.primaryColor,
                                                letterSpacing: 0.1,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  // Subservices available
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                              .expand(
                                                                (subs) => subs,
                                                              )
                                                              .length >
                                                          3
                                                      ? '...'
                                                      : '')
                                              : 'No subservices',
                                          style: TextStyle(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          style: TextStyle(
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
                                      onPressed: () async {
                                        final approved = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    UnapprovedShopDetailScreen(
                                                      shop: shop,
                                                    ),
                                          ),
                                        );
                                        if (approved == true) {
                                          _approveShop(shop);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppConstants.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'View Details',
                                        style: TextStyle(
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
              ),
    );
  }
}
