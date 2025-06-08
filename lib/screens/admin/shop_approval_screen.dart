import 'package:flutter/material.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/utils/asset_helpers.dart';

class ShopApprovalScreen extends StatefulWidget {
  const ShopApprovalScreen({Key? key}) : super(key: key);

  @override
  State<ShopApprovalScreen> createState() => _ShopApprovalScreenState();
}

class _ShopApprovalScreenState extends State<ShopApprovalScreen> {
  final ShopService _shopService = ShopService();
  List<RepairShop> _unapprovedShops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUnapprovedShops();
  }

  Future<void> _loadUnapprovedShops() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading unapproved shops...');
      final shops = await _shopService.getUnapprovedShops();
      print('Loaded ${shops.length} unapproved shops');

      setState(() {
        _unapprovedShops = shops;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadUnapprovedShops: $e');
      setState(() {
        _error = 'Failed to load shops: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateShopApprovalStatus(RepairShop shop, bool approved) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _shopService.updateShopApprovalStatus(
        shop.id,
        approved,
      );

      if (success) {
        // Remove the shop from the list
        setState(() {
          _unapprovedShops.removeWhere((s) => s.id == shop.id);
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'Shop approved successfully' : 'Shop rejected',
            ),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to update shop status');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building ShopApprovalScreen with ${_unapprovedShops.length} shops');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shop Approvals',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUnapprovedShops,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
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
                      'No shops pending approval',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All shops have been reviewed',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                    print('Building shop card for: ${shop.name}');
                    return _buildShopCard(shop);
                  },
                ),
              ),
    );
  }

  Widget _buildShopCard(RepairShop shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                shop.photos.isNotEmpty
                    ? shop.photos.first
                    : AssetHelpers.getStockImageUrl('shop'),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.network(
                    AssetHelpers.getStockImageUrl('shop'),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Name
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category[0].toUpperCase() + category.substring(1),
                            style: TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                // Address
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${shop.address}, ${shop.area}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateShopApprovalStatus(shop, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateShopApprovalStatus(shop, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
