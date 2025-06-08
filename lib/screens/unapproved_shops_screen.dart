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
                    return GestureDetector(
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
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      shop.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _approveShop(shop),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AppConstants.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Approve'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                shop.description,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                shop.address,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
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
                                          color: AppConstants.primaryColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            color: AppConstants.primaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
