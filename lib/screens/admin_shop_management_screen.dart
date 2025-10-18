import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/widgets/optimized_screen.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:wonwonw2/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class AdminShopManagementScreen extends OptimizedScreen {
  const AdminShopManagementScreen({Key? key}) : super(key: key);

  @override
  OptimizedLoadingScreen<AdminShopManagementScreen> createState() =>
      _AdminShopManagementScreenState();
}

class _AdminShopManagementScreenState
    extends OptimizedLoadingScreen<AdminShopManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ShopService _shopService = ShopService();

  String _searchQuery = '';
  String _statusFilter = 'all'; // all, approved, pending
  String _categoryFilter = 'all';
  String _sortBy = 'name';
  bool _sortAscending = true;

  Set<String> _selectedShopIds = <String>{};
  Map<String, DateTime> _shopLastViewedMap = <String, DateTime>{};

  final List<String> _categories = [
    'clothing',
    'footwear',
    'watch',
    'bag',
    'electronics',
    'appliance',
  ];

  @override
  void onScreenInit() {
    super.onScreenInit();
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Shop Management',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showBulkActionsDialog,
                    icon: const FaIcon(FontAwesomeIcons.tasks, size: 16),
                    label: const Text('Bulk Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddShopDialog,
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                    label: const Text('Add Shop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Filters and Search
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (value) {
                    safeSetState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search shops...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _statusFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Category Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categoryFilter,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Categories'),
                    ),
                    ..._categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          'category_${category.toLowerCase()}'.tr(context),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _categoryFilter = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Sort By
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'rating', child: Text('Rating')),
                    DropdownMenuItem(value: 'area', child: Text('Area')),
                    DropdownMenuItem(
                      value: 'lastViewed',
                      child: Text('Last Viewed'),
                    ),
                  ],
                  onChanged: (value) {
                    safeSetState(() {
                      _sortBy = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Sort Direction
              IconButton(
                onPressed: () {
                  safeSetState(() {
                    _sortAscending = !_sortAscending;
                  });
                },
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: const Color(0xFF64748B),
                ),
                tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ],
          ),
        ),

        // Shop List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('shops').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Process and filter shops
              final shops =
                  snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;

                    // Handle lastViewedAt field for display
                    DateTime? lastViewedAt;
                    if (data['lastViewedAt'] is Timestamp) {
                      lastViewedAt =
                          (data['lastViewedAt'] as Timestamp).toDate();
                    } else if (data['updatedAt'] is Timestamp) {
                      lastViewedAt = (data['updatedAt'] as Timestamp).toDate();
                    } else if (data['createdAt'] is Timestamp) {
                      lastViewedAt = (data['createdAt'] as Timestamp).toDate();
                    }

                    // Store lastViewedAt in the map for display
                    if (lastViewedAt != null) {
                      _shopLastViewedMap[doc.id] = lastViewedAt;
                    }

                    return RepairShop.fromMap(data);
                  }).toList();

              final filteredShops = _filterShops(shops);
              _sortShops(filteredShops);

              return _buildShopsList(filteredShops);
            },
          ),
        ),
      ],
    );
  }

  List<RepairShop> _filterShops(List<RepairShop> shops) {
    return shops.where((shop) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!shop.name.toLowerCase().contains(query) &&
            !shop.description.toLowerCase().contains(query) &&
            !shop.area.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_statusFilter != 'all') {
        if (_statusFilter == 'approved' && !shop.approved) return false;
        if (_statusFilter == 'pending' && shop.approved) return false;
      }

      // Category filter
      if (_categoryFilter != 'all') {
        if (!shop.categories.contains(_categoryFilter)) return false;
      }

      return true;
    }).toList();
  }

  void _sortShops(List<RepairShop> shops) {
    shops.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'rating':
          comparison = a.rating.compareTo(b.rating);
          break;
        case 'area':
          comparison = a.area.compareTo(b.area);
          break;
        case 'lastViewed':
          final aLastViewed = _shopLastViewedMap[a.id];
          final bLastViewed = _shopLastViewedMap[b.id];
          if (aLastViewed != null && bLastViewed != null) {
            comparison = aLastViewed.compareTo(bLastViewed);
          } else if (aLastViewed != null) {
            comparison = -1; // a has last viewed, b doesn't
          } else if (bLastViewed != null) {
            comparison = 1; // b has last viewed, a doesn't
          } else {
            comparison = 0; // neither has last viewed
          }
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.store, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No shops found',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No shops match your current filters',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopsList(List<RepairShop> shops) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: shops.length,
      itemBuilder: (context, index) => _buildShopCard(shops[index]),
    );
  }

  Widget _buildShopCard(RepairShop shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Selection Checkbox
                Checkbox(
                  value: _selectedShopIds.contains(shop.id),
                  onChanged: (selected) {
                    safeSetState(() {
                      if (selected == true) {
                        _selectedShopIds.add(shop.id);
                      } else {
                        _selectedShopIds.remove(shop.id);
                      }
                    });
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            shop.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  shop.approved
                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                      : const Color(
                                        0xFFF59E0B,
                                      ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              shop.approved ? 'APPROVED' : 'PENDING',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    shop.approved
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFDF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        shop.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_shopLastViewedMap.containsKey(shop.id)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 12,
                              color: _getViewedStatusColor(
                                _shopLastViewedMap[shop.id]!,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Last viewed ${_formatLastViewedTime(_shopLastViewedMap[shop.id]!)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getViewedStatusColor(
                                  _shopLastViewedMap[shop.id]!,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.locationDot,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            shop.area,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 16),
                          FaIcon(
                            FontAwesomeIcons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _viewShopDetails(shop),
                          icon: const FaIcon(FontAwesomeIcons.eye, size: 16),
                          tooltip: 'View Details',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF3B82F6,
                            ).withOpacity(0.1),
                            foregroundColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _editShop(shop),
                          icon: const FaIcon(FontAwesomeIcons.edit, size: 16),
                          tooltip: 'Edit Shop',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFF59E0B,
                            ).withOpacity(0.1),
                            foregroundColor: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!shop.approved)
                          IconButton(
                            onPressed: () => _approveShop(shop),
                            icon: const FaIcon(
                              FontAwesomeIcons.check,
                              size: 16,
                            ),
                            tooltip: 'Approve Shop',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF10B981,
                              ).withOpacity(0.1),
                              foregroundColor: const Color(0xFF10B981),
                            ),
                          ),
                        if (!shop.approved) const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _deleteShop(shop),
                          icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                          tooltip: 'Delete Shop',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFEF4444,
                            ).withOpacity(0.1),
                            foregroundColor: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  shop.categories
                      .map(
                        (category) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64748B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'category_${category.toLowerCase()}'.tr(context),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _viewShopDetails(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: 600,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Shop Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Name', shop.name),
                  _buildDetailRow('Description', shop.description),
                  _buildDetailRow('Area', shop.area),
                  _buildDetailRow('Address', shop.address),
                  _buildDetailRow(
                    'Rating',
                    '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount} reviews)',
                  ),
                  _buildDetailRow('Categories', shop.categories.join(', ')),
                  _buildDetailRow('Price Range', shop.priceRange),
                  _buildDetailRow(
                    'Status',
                    shop.approved ? 'Approved' : 'Pending',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editShop(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => _EditShopDialog(
            shop: shop,
            onSave: (updatedShop) async {
              setLoading(true, message: 'Updating shop...');
              try {
                final success = await _shopService.updateShop(updatedShop);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${updatedShop.name} has been updated'),
                      backgroundColor: AppConstants.primaryColor,
                    ),
                  );
                } else {
                  throw Exception('Failed to update shop');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating shop: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setLoading(false);
              }
            },
          ),
    );
  }

  void _approveShop(RepairShop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve Shop'),
            content: Text('Are you sure you want to approve "${shop.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Approving shop...');

      try {
        final success = await _shopService.approveShop(shop.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${shop.name} has been approved'),
              backgroundColor: AppConstants.primaryColor,
            ),
          );
        } else {
          throw Exception('Failed to approve shop');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving shop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  void _deleteShop(RepairShop shop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Shop'),
            content: Text(
              'Are you sure you want to delete "${shop.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Deleting shop...');

      try {
        final success = await _shopService.deleteShop(shop.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${shop.name} has been deleted'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          throw Exception('Failed to delete shop');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting shop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  void _showAddShopDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _AddShopDialog(
            onSave: (newShop) async {
              setLoading(true, message: 'Adding shop...');
              try {
                final success = await _shopService.addShop(newShop);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${newShop.name} has been added'),
                      backgroundColor: AppConstants.primaryColor,
                    ),
                  );
                } else {
                  throw Exception('Failed to add shop');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding shop: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setLoading(false);
              }
            },
          ),
    );
  }

  void _showBulkActionsDialog() {
    if (_selectedShopIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select shops to perform bulk actions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Bulk Actions (${_selectedShopIds.length} shops selected)',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Approve All Selected'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkApproveShops();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.orange),
                  title: const Text('Unapprove All Selected'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkUnapproveShops();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete All Selected'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkDeleteShops();
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _bulkApproveShops() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bulk Approve Shops'),
            content: Text(
              'Are you sure you want to approve ${_selectedShopIds.length} shops?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Approve All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Approving shops...');
      try {
        int successCount = 0;
        for (final shopId in _selectedShopIds) {
          final success = await _shopService.approveShop(shopId);
          if (success) successCount++;
        }

        safeSetState(() {
          _selectedShopIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount shops approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk approval: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  Future<void> _bulkUnapproveShops() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bulk Unapprove Shops'),
            content: Text(
              'Are you sure you want to unapprove ${_selectedShopIds.length} shops?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Unapprove All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Unapproving shops...');
      try {
        int successCount = 0;
        for (final shopId in _selectedShopIds) {
          // Unapprove shop by updating approved status to false
          await _firestore.collection('shops').doc(shopId).update({
            'approved': false,
          });
          final success = true;
          if (success) successCount++;
        }

        safeSetState(() {
          _selectedShopIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount shops unapproved successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk unapproval: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  Future<void> _bulkDeleteShops() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bulk Delete Shops'),
            content: Text(
              'Are you sure you want to delete ${_selectedShopIds.length} shops? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'Deleting shops...');
      try {
        int successCount = 0;
        for (final shopId in _selectedShopIds) {
          final success = await _shopService.deleteShop(shopId);
          if (success) successCount++;
        }

        safeSetState(() {
          _selectedShopIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount shops deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk deletion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  String _formatLastViewedTime(DateTime lastViewed) {
    final now = DateTime.now();
    final difference = now.difference(lastViewed);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return DateFormat('MMM dd').format(lastViewed);
    }
  }

  Color _getViewedStatusColor(DateTime lastViewed) {
    final now = DateTime.now();
    final difference = now.difference(lastViewed);

    if (difference.inMinutes < 5) {
      return const Color(0xFF10B981); // Green - Very recently viewed
    } else if (difference.inHours < 1) {
      return const Color(0xFF3B82F6); // Blue - Recently viewed
    } else if (difference.inHours < 24) {
      return const Color(0xFFF59E0B); // Orange - Viewed today
    } else if (difference.inDays < 7) {
      return const Color(0xFF8B5CF6); // Purple - Viewed this week
    } else {
      return const Color(0xFF64748B); // Gray - Not recently viewed
    }
  }
}

// Shop Edit Dialog Widget
class _EditShopDialog extends StatefulWidget {
  final RepairShop shop;
  final Function(RepairShop) onSave;

  const _EditShopDialog({required this.shop, required this.onSave});

  @override
  State<_EditShopDialog> createState() => _EditShopDialogState();
}

class _EditShopDialogState extends State<_EditShopDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;
  late TextEditingController _phoneController;
  late TextEditingController _facebookPageController;

  // Detailed opening hours management for edit dialog
  final Map<String, TextEditingController> _openingTimeControllers = {
    'mon': TextEditingController(),
    'tue': TextEditingController(),
    'wed': TextEditingController(),
    'thu': TextEditingController(),
    'fri': TextEditingController(),
    'sat': TextEditingController(),
    'sun': TextEditingController(),
  };

  final Map<String, TextEditingController> _closingTimeControllers = {
    'mon': TextEditingController(),
    'tue': TextEditingController(),
    'wed': TextEditingController(),
    'thu': TextEditingController(),
    'fri': TextEditingController(),
    'sat': TextEditingController(),
    'sun': TextEditingController(),
  };

  // Store actual TimeOfDay objects for time pickers
  final Map<String, TimeOfDay?> _openingTimes = {
    'mon': null,
    'tue': null,
    'wed': null,
    'thu': null,
    'fri': null,
    'sat': null,
    'sun': null,
  };

  final Map<String, TimeOfDay?> _closingTimes = {
    'mon': null,
    'tue': null,
    'wed': null,
    'thu': null,
    'fri': null,
    'sat': null,
    'sun': null,
  };

  // Track which days are closed
  final Map<String, bool> _closedDays = {
    'mon': false,
    'tue': false,
    'wed': false,
    'thu': false,
    'fri': false,
    'sat': false,
    'sun': false,
  };

  // New flag for "Same time every day"
  bool _sameTimeEveryDay = false;

  List<String> _selectedCategories = [];
  Map<String, List<String>> _selectedSubServices =
      {}; // category -> list of subservice IDs
  bool _isApproved = false;
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;
  String? _selectedImagePath;
  String? _uploadedImageUrl;

  // Price range slider (1-5 baht symbols)
  double _priceRangeValue = 1.0;

  // Payment methods
  List<String> _selectedPaymentMethods = [];
  final List<String> _availablePaymentMethods = [
    'cash',
    'card',
    'qr',
    'bank_transfer',
    'true_money',
    'line_pay',
  ];

  // Additional optional fields
  late TextEditingController _buildingNumberController;
  late TextEditingController _buildingNameController;
  late TextEditingController _buildingFloorController;
  late TextEditingController _soiController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;
  late TextEditingController _landmarkController;
  late TextEditingController _lineIdController;
  late TextEditingController _instagramPageController;
  late TextEditingController _otherContactsController;
  late TextEditingController _notesOrConditionsController;
  late TextEditingController _durationMinutesController;

  // Additional boolean fields
  bool _tryOnAreaAvailable = false;
  bool _requiresPurchase = false;
  bool _irregularHours = false;

  // Additional list and map fields
  List<String> _selectedAmenities = [];
  Map<String, bool> _selectedFeatures = {};

  // Available options
  final List<String> _availableAmenities = [
    'WiFi',
    'Parking',
    'Air Conditioning',
    'Waiting Area',
    'Restroom',
    'Credit Card Payment',
    'Cash Only',
    'Appointment Required',
    'Walk-in Welcome',
    'Express Service',
  ];

  final List<String> _availableFeatures = [
    'Same Day Service',
    'Express Repair',
    'Warranty Provided',
    'Pick-up Service',
    'Delivery Service',
    'Online Booking',
    'Expert Technician',
    'Genuine Parts',
    'Free Consultation',
    'Quality Guarantee',
  ];

  final List<String> _availableCategories = [
    'clothing',
    'footwear',
    'watch',
    'bag',
    'electronics',
    'appliance',
  ];

  // Map of categories to their sub-services
  final Map<String, List<String>> _categorySubServices = {
    'clothing': [
      'zipper_replacement',
      'pants_hemming',
      'waist_adjustment',
      'elastic_replacement',
      'button_replacement',
      'collar_replacement',
      'tear_repair',
      'add_pockets',
    ],
    'footwear': [
      'sole_replacement',
      'leather_repair',
      'heel_repair',
      'shoe_cleaning',
    ],
    'watch': [
      'scratch_removal',
      'battery_replacement',
      'watch_cleaning',
      'strap_replacement',
      'glass_replacement',
      'authenticity_check',
    ],
    'bag': [
      'bag_repair',
      'women_bags',
      'brand_bags',
      'travel_bags',
      'document_bags',
      'backpacks',
      'sports_bags',
      'student_bags',
      'golf_bags',
      'belts',
      'leather_jackets',
      'laptop_bags',
      'music_instruments',
      'food_delivery',
      'shoe_repair',
      'stroller_repair',
    ],
    'electronics': [
      'laptop',
      'mac',
      'mobile',
      'network',
      'printer',
      'audio',
      'other_electronics',
    ],
    'appliance': ['small_appliances', 'large_appliances'],
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shop.name);
    _descriptionController = TextEditingController(
      text: widget.shop.description,
    );
    _addressController = TextEditingController(text: widget.shop.address);
    _areaController = TextEditingController(text: widget.shop.area);
    _phoneController = TextEditingController(
      text: widget.shop.phoneNumber ?? '',
    );
    _facebookPageController = TextEditingController(
      text: widget.shop.facebookPage ?? '',
    );
    _selectedCategories = List.from(widget.shop.categories);
    _selectedSubServices = Map.from(widget.shop.subServices);
    _isApproved = widget.shop.approved;
    _selectedLatitude = widget.shop.latitude;
    _selectedLongitude = widget.shop.longitude;
    _uploadedImageUrl =
        widget.shop.photos.isNotEmpty ? widget.shop.photos.first : null;

    // Initialize additional controllers with existing data
    _buildingNumberController = TextEditingController(
      text: widget.shop.buildingNumber ?? '',
    );
    _buildingNameController = TextEditingController(
      text: widget.shop.buildingName ?? '',
    );
    _buildingFloorController = TextEditingController(
      text: widget.shop.buildingFloor ?? '',
    );
    _soiController = TextEditingController(text: widget.shop.soi ?? '');
    _districtController = TextEditingController(
      text: widget.shop.district ?? '',
    );
    _provinceController = TextEditingController(
      text: widget.shop.province ?? '',
    );
    _landmarkController = TextEditingController(
      text: widget.shop.landmark ?? '',
    );
    _lineIdController = TextEditingController(text: widget.shop.lineId ?? '');
    _instagramPageController = TextEditingController(
      text: widget.shop.instagramPage ?? '',
    );
    _otherContactsController = TextEditingController(
      text: widget.shop.otherContacts ?? '',
    );
    _notesOrConditionsController = TextEditingController(
      text: widget.shop.notesOrConditions ?? '',
    );
    _durationMinutesController = TextEditingController(
      text: widget.shop.durationMinutes.toString(),
    );

    // Initialize boolean fields
    _tryOnAreaAvailable = widget.shop.tryOnAreaAvailable ?? false;
    _requiresPurchase = widget.shop.requiresPurchase;
    _irregularHours = widget.shop.irregularHours;

    // Initialize lists and maps
    _selectedAmenities = List.from(widget.shop.amenities);
    _selectedFeatures = Map.from(widget.shop.features);
    _selectedPaymentMethods = List.from(widget.shop.paymentMethods ?? []);

    // Initialize price range from existing data
    _priceRangeValue = _parsePriceRange(widget.shop.priceRange);

    // Initialize opening hours from existing shop data
    _loadExistingHours();
  }

  // Parse price range from baht symbols to slider value
  double _parsePriceRange(String priceRange) {
    final bahtCount = priceRange.split('₿').length - 1;
    return bahtCount.toDouble().clamp(1.0, 5.0);
  }

  // Convert slider value to baht symbols
  String _formatPriceRange(double value) {
    return '₿' * value.round();
  }

  // Load existing hours data from the shop
  void _loadExistingHours() {
    // Parse existing hours data from the shop
    widget.shop.hours.forEach((day, timeRange) {
      if (timeRange.toLowerCase() == 'closed') {
        _closedDays[day] = true;
      } else {
        _closedDays[day] = false;

        // Parse time range like "09:00 - 18:00"
        final parts = timeRange.split(' - ');
        if (parts.length == 2) {
          final openingStr = parts[0].trim();
          final closingStr = parts[1].trim();

          // Parse opening time
          final openingParts = openingStr.split(':');
          if (openingParts.length == 2) {
            final hour = int.tryParse(openingParts[0]);
            final minute = int.tryParse(openingParts[1]);
            if (hour != null && minute != null) {
              _openingTimes[day] = TimeOfDay(hour: hour, minute: minute);
              _openingTimeControllers[day]?.text = openingStr;
            }
          }

          // Parse closing time
          final closingParts = closingStr.split(':');
          if (closingParts.length == 2) {
            final hour = int.tryParse(closingParts[0]);
            final minute = int.tryParse(closingParts[1]);
            if (hour != null && minute != null) {
              _closingTimes[day] = TimeOfDay(hour: hour, minute: minute);
              _closingTimeControllers[day]?.text = closingStr;
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    _facebookPageController.dispose();

    // Dispose opening hours controllers
    _openingTimeControllers.values.forEach(
      (controller) => controller.dispose(),
    );
    _closingTimeControllers.values.forEach(
      (controller) => controller.dispose(),
    );

    // Dispose additional controllers
    _buildingNumberController.dispose();
    _buildingNameController.dispose();
    _buildingFloorController.dispose();
    _soiController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _landmarkController.dispose();
    _lineIdController.dispose();
    _instagramPageController.dispose();
    _otherContactsController.dispose();
    _notesOrConditionsController.dispose();
    _durationMinutesController.dispose();

    super.dispose();
  }

  Future<void> _openMapPicker(BuildContext context) async {
    // Get initial coordinates if available
    double? initialLat = _selectedLatitude != 0.0 ? _selectedLatitude : null;
    double? initialLng = _selectedLongitude != 0.0 ? _selectedLongitude : null;

    // Navigate to the map picker screen
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(
              initialLatitude: initialLat,
              initialLongitude: initialLng,
            ),
      ),
    );

    // Update coordinates if a location was selected
    if (result != null) {
      setState(() {
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;
      });
    }
  }

  // Helper methods for opening hours management in edit dialog

  Future<void> _selectTime(
    BuildContext context,
    String day,
    bool isOpening,
  ) async {
    TimeOfDay? selectedTime =
        isOpening
            ? (_openingTimes[day] ?? TimeOfDay(hour: 9, minute: 0))
            : (_closingTimes[day] ?? TimeOfDay(hour: 18, minute: 0));

    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isOpening) {
          _openingTimes[day] = result;
          _openingTimeControllers[day]!.text = result.format(context);
        } else {
          _closingTimes[day] = result;
          _closingTimeControllers[day]!.text = result.format(context);
        }

        // If "Same time every day" is enabled, apply to all days
        if (_sameTimeEveryDay) {
          _openingTimeControllers.forEach((dayKey, controller) {
            if (isOpening) {
              _openingTimes[dayKey] = result;
              controller.text = result.format(context);
            } else {
              _closingTimes[dayKey] = result;
              _closingTimeControllers[dayKey]!.text = result.format(context);
            }
          });
        }
      });
    }
  }

  // Build price range slider section for edit dialog
  Widget _buildPriceRangeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Range',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '₿',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _priceRangeValue,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  activeColor: AppConstants.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _priceRangeValue = value;
                    });
                  },
                ),
              ),
              Text(
                '₿₿₿₿₿',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.primaryColor),
              ),
              child: Text(
                _formatPriceRange(_priceRangeValue),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1200,
        height: 1000,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Edit Shop',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Basic Information
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Shop Name',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Shop name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _areaController,
                              label: 'Area',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Area is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _addressController,
                        label: 'Full Address',
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Contact Information
                      _buildSectionHeader('Contact Information'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Phone number is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _facebookPageController,
                              label: 'Facebook Page (Optional)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Range Slider Section
                      _buildPriceRangeSection(),
                      const SizedBox(height: 16),

                      // Payment Methods Section
                      _buildPaymentMethodsSection(),
                      const SizedBox(height: 16),

                      // Additional Fields Section
                      _buildAdditionalFieldsSection(),
                      const SizedBox(height: 16),

                      // Amenities Section
                      _buildAmenitiesSection(),
                      const SizedBox(height: 16),

                      // Features Section
                      _buildFeaturesSection(),
                      const SizedBox(height: 16),

                      // Opening Hours Section
                      _buildOpeningHoursSection(),
                      const SizedBox(height: 24),

                      // Cover Image
                      _buildSectionHeader('Cover Image'),
                      const SizedBox(height: 16),
                      _buildImageUploadSection(),
                      const SizedBox(height: 24),

                      // Location
                      _buildSectionHeader('Location'),
                      const SizedBox(height: 16),
                      _buildLocationSection(),
                      const SizedBox(height: 24),

                      // Categories
                      _buildSectionHeader('Categories'),
                      const SizedBox(height: 16),
                      _buildCategorySelection(),
                      const SizedBox(height: 24),

                      // Sub-Services
                      if (_selectedCategories.isNotEmpty) ...[
                        _buildSectionHeader('Sub-Services'),
                        const SizedBox(height: 16),
                        _buildSubServicesSelection(),
                        const SizedBox(height: 24),
                      ],

                      // Status
                      _buildSectionHeader('Status'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Approved',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            _isApproved
                                ? 'Shop is approved and visible to users'
                                : 'Shop is pending approval',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          value: _isApproved,
                          onChanged: (value) {
                            setState(() {
                              _isApproved = value;
                            });
                          },
                          activeColor: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Categories:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                          // Initialize empty subservices list for this category
                          if (!_selectedSubServices.containsKey(category)) {
                            _selectedSubServices[category] = [];
                          }
                        } else {
                          _selectedCategories.remove(category);
                          // Remove subservices for this category
                          _selectedSubServices.remove(category);
                        }
                      });
                    },
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
          if (_selectedCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least one category',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubServicesSelection() {
    return Column(
      children:
          _selectedCategories.map((category) {
            final availableSubServices = _categorySubServices[category] ?? [];
            final selectedSubServices = _selectedSubServices[category] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.toUpperCase()} Sub-Services:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (availableSubServices.isEmpty)
                    Text(
                      'No sub-services available for this category',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          availableSubServices.map((subService) {
                            final isSelected = selectedSubServices.contains(
                              subService,
                            );
                            return FilterChip(
                              label: Text(
                                subService.replaceAll('_', ' ').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSubServices[category] = [
                                      ...selectedSubServices,
                                      subService,
                                    ];
                                  } else {
                                    _selectedSubServices[category] =
                                        selectedSubServices
                                            .where((s) => s != subService)
                                            .toList();
                                  }
                                });
                              },
                              selectedColor: AppConstants.primaryColor
                                  .withOpacity(0.15),
                              checkmarkColor: AppConstants.primaryColor,
                              backgroundColor: Colors.grey[50],
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? AppConstants.primaryColor
                                        : const Color(0xFFE2E8F0),
                              ),
                            );
                          }).toList(),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Future<void> _pickImage() async {
    try {
      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppConstants.primaryColor),
                  const SizedBox(width: 16),
                  const Text('Uploading image...'),
                ],
              ),
            ),
      );

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Upload to Firebase Storage
      final String fileName =
          'shop_edit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('shop_photos')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Close loading dialog
      Navigator.of(context).pop();

      // Update state with uploaded image
      setState(() {
        _uploadedImageUrl = downloadUrl;
        _selectedImagePath = image.path;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image uploaded successfully!'),
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Cover Photo',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          if (_uploadedImageUrl != null || _selectedImagePath != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image:
                    _uploadedImageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(_uploadedImageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  _uploadedImageUrl == null
                      ? const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload, size: 20),
                  label: Text(
                    _uploadedImageUrl != null || _selectedImagePath != null
                        ? 'Change Image'
                        : 'Upload Image',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_uploadedImageUrl != null || _selectedImagePath != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImagePath = null;
                        _uploadedImageUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Location',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_selectedLatitude.toStringAsFixed(6)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Lng: ${_selectedLongitude.toStringAsFixed(6)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openMapPicker(context),
                icon: const Icon(Icons.map, size: 20),
                label: const Text('Pick Location on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build payment methods section for edit dialog
  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availablePaymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethods.contains(method);
                  IconData icon;
                  String label;

                  switch (method) {
                    case 'cash':
                      icon = Icons.money;
                      label = 'Cash';
                      break;
                    case 'card':
                      icon = Icons.credit_card;
                      label = 'Card';
                      break;
                    case 'qr':
                      icon = Icons.qr_code;
                      label = 'QR Code';
                      break;
                    case 'bank_transfer':
                      icon = Icons.account_balance;
                      label = 'Bank Transfer';
                      break;
                    case 'true_money':
                      icon = Icons.account_balance_wallet;
                      label = 'TrueMoney';
                      break;
                    case 'line_pay':
                      icon = Icons.chat;
                      label = 'LINE Pay';
                      break;
                    default:
                      icon = Icons.payment;
                      label = method;
                  }

                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPaymentMethods.add(method);
                        } else {
                          _selectedPaymentMethods.remove(method);
                        }
                      });
                    },
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Build additional fields section for edit dialog
  Widget _buildAdditionalFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Building Information
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _buildingNumberController,
                  label: 'Building Number',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _buildingNameController,
                  label: 'Building Name',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _buildingFloorController,
                  label: 'Floor',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _soiController,
                  label: 'Soi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _districtController,
                  label: 'District',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _provinceController,
                  label: 'Province',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTextField(controller: _landmarkController, label: 'Landmark'),
          const SizedBox(height: 16),

          // Contact Information
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lineIdController,
                  label: 'LINE ID',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _instagramPageController,
                  label: 'Instagram',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _otherContactsController,
            label: 'Other Contacts',
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _notesOrConditionsController,
            label: 'Notes or Conditions',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Duration field
          _buildTextField(
            controller: _durationMinutesController,
            label: 'Service Duration (minutes)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Boolean options
          Row(
            children: [
              Checkbox(
                value: _tryOnAreaAvailable,
                onChanged: (value) {
                  setState(() {
                    _tryOnAreaAvailable = value ?? false;
                  });
                },
                activeColor: AppConstants.primaryColor,
              ),
              Text(
                'Try-on Area Available',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _requiresPurchase,
                onChanged: (value) {
                  setState(() {
                    _requiresPurchase = value ?? false;
                  });
                },
                activeColor: AppConstants.primaryColor,
              ),
              Text(
                'Requires Purchase',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 32),
              Checkbox(
                value: _irregularHours,
                onChanged: (value) {
                  setState(() {
                    _irregularHours = value ?? false;
                  });
                },
                activeColor: AppConstants.primaryColor,
              ),
              Text(
                'Irregular Hours',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build amenities section
  Widget _buildAmenitiesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    label: Text(amenity),
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Build features section
  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableFeatures.map((feature) {
                  final isSelected = _selectedFeatures[feature] ?? false;
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeatures[feature] = selected;
                      });
                    },
                    label: Text(feature),
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Build opening hours section for edit dialog
  Widget _buildOpeningHoursSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Opening Hours',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  _buildQuickActionButton('Copy Mon', () => _copyMondayHours()),
                  const SizedBox(width: 8),
                  _buildQuickActionButton('Clear All', () => _clearAllHours()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time presets
          Wrap(
            spacing: 8,
            children: [
              _buildPresetButton('9:00 AM - 6:00 PM', '09:00', '18:00'),
              _buildPresetButton('10:00 AM - 7:00 PM', '10:00', '19:00'),
              _buildPresetButton('8:00 AM - 5:00 PM', '08:00', '17:00'),
            ],
          ),
          const SizedBox(height: 16),

          // Daily time pickers
          ...[
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ].map((day) {
            final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
            final dayNames = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];
            final dayIndex = dayNames.indexOf(day);
            final dayKey = dayKeys[dayIndex];
            final isClosed = _closedDays[dayKey] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isClosed ? Colors.grey.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            isClosed
                                ? Colors.grey.shade600
                                : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isClosed,
                    onChanged: (value) {
                      setState(() {
                        _closedDays[dayKey] = value ?? false;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  Text(
                    'Closed',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!isClosed) ...[
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, dayKey, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _openingTimes[dayKey]?.format(context) ??
                                      'Open',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('-', style: GoogleFonts.inter(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, dayKey, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _closingTimes[dayKey]?.format(context) ??
                                      'Close',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Helper methods for edit dialog
  Widget _buildQuickActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
    );
  }

  Widget _buildPresetButton(String label, String openTime, String closeTime) {
    return ElevatedButton(
      onPressed: () => _applyTimePreset(openTime, closeTime),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
        foregroundColor: AppConstants.primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
    );
  }

  void _applyTimePreset(String openTime, String closeTime) {
    setState(() {
      for (String day in [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ]) {
        if (!_closedDays.containsKey(day) || !_closedDays[day]!) {
          // Parse time strings to TimeOfDay objects
          final openParts = openTime.split(':');
          final closeParts = closeTime.split(':');

          if (openParts.length == 2 && closeParts.length == 2) {
            final openHour = int.tryParse(openParts[0]);
            final openMinute = int.tryParse(openParts[1]);
            final closeHour = int.tryParse(closeParts[0]);
            final closeMinute = int.tryParse(closeParts[1]);

            if (openHour != null &&
                openMinute != null &&
                closeHour != null &&
                closeMinute != null) {
              _openingTimes[day] = TimeOfDay(
                hour: openHour,
                minute: openMinute,
              );
              _closingTimes[day] = TimeOfDay(
                hour: closeHour,
                minute: closeMinute,
              );
              _openingTimeControllers[day]?.text = openTime;
              _closingTimeControllers[day]?.text = closeTime;
            }
          }
        }
      }
    });
  }

  void _copyMondayHours() {
    final mondayOpen = _openingTimes['monday'];
    final mondayClose = _closingTimes['monday'];

    if (mondayOpen != null && mondayClose != null) {
      setState(() {
        for (String day in [
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ]) {
          if (!_closedDays.containsKey(day) || !_closedDays[day]!) {
            _openingTimes[day] = mondayOpen;
            _closingTimes[day] = mondayClose;
            _openingTimeControllers[day]?.text = mondayOpen.format(context);
            _closingTimeControllers[day]?.text = mondayClose.format(context);
          }
        }
      });
    }
  }

  void _clearAllHours() {
    setState(() {
      _openingTimes.updateAll((key, value) => null);
      _closingTimes.updateAll((key, value) => null);
      _closedDays.updateAll((key, value) => false);
      _openingTimeControllers.forEach((key, controller) => controller.clear());
      _closingTimeControllers.forEach((key, controller) => controller.clear());
    });
  }

  void _saveShop() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create a map of opening hours like in the add shop implementation
    final Map<String, String> hours = {};
    final List<String> closingDays = [];

    _openingTimeControllers.forEach((day, openingController) {
      final closingController = _closingTimeControllers[day]!;
      final isClosed = _closedDays[day] ?? false;

      if (isClosed) {
        hours[day] = 'Closed';
        closingDays.add(day);
      } else if (openingController.text.isNotEmpty &&
          closingController.text.isNotEmpty) {
        hours[day] = '${openingController.text} - ${closingController.text}';
      }
    });

    final updatedShop = RepairShop(
      id: widget.shop.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      area: _areaController.text.trim(),
      phoneNumber:
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
      priceRange: _formatPriceRange(_priceRangeValue),
      usualOpeningTime:
          hours.isNotEmpty
              ? hours.entries.first.value.split(' - ').first
              : null,
      usualClosingTime:
          hours.isNotEmpty ? hours.entries.first.value.split(' - ').last : null,
      facebookPage:
          _facebookPageController.text.trim().isEmpty
              ? null
              : _facebookPageController.text.trim(),
      buildingNumber:
          _buildingNumberController.text.trim().isEmpty
              ? null
              : _buildingNumberController.text.trim(),
      buildingName:
          _buildingNameController.text.trim().isEmpty
              ? null
              : _buildingNameController.text.trim(),
      buildingFloor:
          _buildingFloorController.text.trim().isEmpty
              ? null
              : _buildingFloorController.text.trim(),
      soi:
          _soiController.text.trim().isEmpty
              ? null
              : _soiController.text.trim(),
      district:
          _districtController.text.trim().isEmpty
              ? null
              : _districtController.text.trim(),
      province:
          _provinceController.text.trim().isEmpty
              ? null
              : _provinceController.text.trim(),
      landmark:
          _landmarkController.text.trim().isEmpty
              ? null
              : _landmarkController.text.trim(),
      lineId:
          _lineIdController.text.trim().isEmpty
              ? null
              : _lineIdController.text.trim(),
      instagramPage:
          _instagramPageController.text.trim().isEmpty
              ? null
              : _instagramPageController.text.trim(),
      otherContacts:
          _otherContactsController.text.trim().isEmpty
              ? null
              : _otherContactsController.text.trim(),
      notesOrConditions:
          _notesOrConditionsController.text.trim().isEmpty
              ? null
              : _notesOrConditionsController.text.trim(),
      paymentMethods:
          _selectedPaymentMethods.isNotEmpty ? _selectedPaymentMethods : null,
      tryOnAreaAvailable: _tryOnAreaAvailable,
      requiresPurchase: _requiresPurchase,
      amenities: _selectedAmenities,
      features: _selectedFeatures,
      durationMinutes: int.tryParse(_durationMinutesController.text) ?? 0,
      irregularHours: _irregularHours,
      categories: _selectedCategories,
      subServices: _selectedSubServices,
      approved: _isApproved,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      rating: widget.shop.rating,
      reviewCount: widget.shop.reviewCount,
      photos:
          _uploadedImageUrl != null ? [_uploadedImageUrl!] : widget.shop.photos,
      hours: hours,
      closingDays: closingDays,
      timestamp: widget.shop.timestamp,
    );

    Navigator.of(context).pop();
    widget.onSave(updatedShop);
  }
}

// Add Shop Dialog Widget
class _AddShopDialog extends StatefulWidget {
  final Function(RepairShop) onSave;

  const _AddShopDialog({required this.onSave});

  @override
  State<_AddShopDialog> createState() => _AddShopDialogState();
}

class _AddShopDialogState extends State<_AddShopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookPageController = TextEditingController();

  List<String> _selectedCategories = [];
  Map<String, List<String>> _selectedSubServices =
      {}; // category -> list of subservice IDs
  bool _isApproved = false;
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;
  String? _selectedImagePath;
  String? _uploadedImageUrl;

  // Opening hours controllers - same structure as user-side implementation
  final Map<String, TextEditingController> _openingTimeControllers = {
    'mon': TextEditingController(),
    'tue': TextEditingController(),
    'wed': TextEditingController(),
    'thu': TextEditingController(),
    'fri': TextEditingController(),
    'sat': TextEditingController(),
    'sun': TextEditingController(),
  };

  final Map<String, TextEditingController> _closingTimeControllers = {
    'mon': TextEditingController(),
    'tue': TextEditingController(),
    'wed': TextEditingController(),
    'thu': TextEditingController(),
    'fri': TextEditingController(),
    'sat': TextEditingController(),
    'sun': TextEditingController(),
  };

  // Store actual TimeOfDay objects for time pickers
  final Map<String, TimeOfDay?> _openingTimes = {
    'mon': null,
    'tue': null,
    'wed': null,
    'thu': null,
    'fri': null,
    'sat': null,
    'sun': null,
  };

  final Map<String, TimeOfDay?> _closingTimes = {
    'mon': null,
    'tue': null,
    'wed': null,
    'thu': null,
    'fri': null,
    'sat': null,
    'sun': null,
  };

  // Track which days are closed
  final Map<String, bool> _closedDays = {
    'mon': false,
    'tue': false,
    'wed': false,
    'thu': false,
    'fri': false,
    'sat': false,
    'sun': false,
  };

  // Flag for irregular hours
  // New flag for "Same time every day"
  bool _sameTimeEveryDay = false;

  // Price range slider (1-5 baht symbols)
  double _priceRangeValue = 1.0;

  // Payment methods
  List<String> _selectedPaymentMethods = [];
  final List<String> _availablePaymentMethods = [
    'cash',
    'card',
    'qr',
    'bank_transfer',
    'true_money',
    'line_pay',
  ];

  // Additional optional fields
  final TextEditingController _buildingNumberController =
      TextEditingController();
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _buildingFloorController =
      TextEditingController();
  final TextEditingController _soiController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _lineIdController = TextEditingController();
  final TextEditingController _instagramPageController =
      TextEditingController();
  final TextEditingController _otherContactsController =
      TextEditingController();
  final TextEditingController _notesOrConditionsController =
      TextEditingController();
  final TextEditingController _durationMinutesController =
      TextEditingController(text: '0');

  // Additional boolean fields for Add dialog
  bool _irregularHours = false;

  // Additional list and map fields for Add dialog
  List<String> _selectedAmenities = [];
  Map<String, bool> _selectedFeatures = {};

  // Available options for Add dialog
  final List<String> _availableAmenities = [
    'WiFi',
    'Parking',
    'Air Conditioning',
    'Waiting Area',
    'Restroom',
    'Credit Card Payment',
    'Cash Only',
    'Appointment Required',
    'Walk-in Welcome',
    'Express Service',
  ];

  final List<String> _availableFeatures = [
    'Same Day Service',
    'Express Repair',
    'Warranty Provided',
    'Pick-up Service',
    'Delivery Service',
    'Online Booking',
    'Expert Technician',
    'Genuine Parts',
    'Free Consultation',
    'Quality Guarantee',
  ];

  // Additional boolean fields
  bool _tryOnAreaAvailable = false;
  bool _requiresPurchase = false;

  final List<String> _availableCategories = [
    'clothing',
    'footwear',
    'watch',
    'bag',
    'electronics',
    'appliance',
  ];

  // Map of categories to their sub-services
  final Map<String, List<String>> _categorySubServices = {
    'clothing': [
      'zipper_replacement',
      'pants_hemming',
      'waist_adjustment',
      'elastic_replacement',
      'button_replacement',
      'collar_replacement',
      'tear_repair',
      'add_pockets',
    ],
    'footwear': [
      'sole_replacement',
      'leather_repair',
      'heel_repair',
      'shoe_cleaning',
    ],
    'watch': [
      'scratch_removal',
      'battery_replacement',
      'watch_cleaning',
      'strap_replacement',
      'glass_replacement',
      'authenticity_check',
    ],
    'bag': [
      'bag_repair',
      'women_bags',
      'brand_bags',
      'travel_bags',
      'document_bags',
      'backpacks',
      'sports_bags',
      'student_bags',
      'golf_bags',
      'belts',
      'leather_jackets',
      'laptop_bags',
      'music_instruments',
      'food_delivery',
      'shoe_repair',
      'stroller_repair',
    ],
    'electronics': [
      'laptop',
      'mac',
      'mobile',
      'network',
      'printer',
      'audio',
      'other_electronics',
    ],
    'appliance': ['small_appliances', 'large_appliances'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _phoneController.dispose();
    _facebookPageController.dispose();

    // Dispose opening hours controllers
    _openingTimeControllers.values.forEach(
      (controller) => controller.dispose(),
    );
    _closingTimeControllers.values.forEach(
      (controller) => controller.dispose(),
    );

    // Dispose additional controllers
    _buildingNumberController.dispose();
    _buildingNameController.dispose();
    _buildingFloorController.dispose();
    _soiController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _landmarkController.dispose();
    _lineIdController.dispose();
    _instagramPageController.dispose();
    _otherContactsController.dispose();
    _notesOrConditionsController.dispose();
    _durationMinutesController.dispose();

    super.dispose();
  }

  // Convert slider value to baht symbols
  String _formatPriceRange(double value) {
    return '₿' * value.round();
  }

  // Build price range slider section for add dialog
  Widget _buildPriceRangeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Range',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '₿',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: Slider(
                  value: _priceRangeValue,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  activeColor: AppConstants.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _priceRangeValue = value;
                    });
                  },
                ),
              ),
              Text(
                '₿₿₿₿₿',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.primaryColor),
              ),
              child: Text(
                _formatPriceRange(_priceRangeValue),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build payment methods section for add dialog
  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availablePaymentMethods.map((method) {
                  final isSelected = _selectedPaymentMethods.contains(method);
                  IconData icon;
                  String label;

                  switch (method) {
                    case 'cash':
                      icon = Icons.money;
                      label = 'Cash';
                      break;
                    case 'card':
                      icon = Icons.credit_card;
                      label = 'Card';
                      break;
                    case 'qr':
                      icon = Icons.qr_code;
                      label = 'QR Code';
                      break;
                    case 'bank_transfer':
                      icon = Icons.account_balance;
                      label = 'Bank Transfer';
                      break;
                    case 'true_money':
                      icon = Icons.account_balance_wallet;
                      label = 'TrueMoney';
                      break;
                    case 'line_pay':
                      icon = Icons.chat;
                      label = 'LINE Pay';
                      break;
                    default:
                      icon = Icons.payment;
                      label = method;
                  }

                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPaymentMethods.add(method);
                        } else {
                          _selectedPaymentMethods.remove(method);
                        }
                      });
                    },
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Build additional fields section for add dialog
  Widget _buildAdditionalFieldsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Building Information
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _buildingNumberController,
                  label: 'Building Number',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _buildingNameController,
                  label: 'Building Name',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _buildingFloorController,
                  label: 'Floor',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _soiController,
                  label: 'Soi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _districtController,
                  label: 'District',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _provinceController,
                  label: 'Province',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTextField(controller: _landmarkController, label: 'Landmark'),
          const SizedBox(height: 16),

          // Contact Information
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _lineIdController,
                  label: 'LINE ID',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _instagramPageController,
                  label: 'Instagram',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _otherContactsController,
            label: 'Other Contacts',
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _notesOrConditionsController,
            label: 'Notes or Conditions',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Duration field
          _buildTextField(
            controller: _durationMinutesController,
            label: 'Service Duration (minutes)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Boolean options
          Row(
            children: [
              Checkbox(
                value: _tryOnAreaAvailable,
                onChanged: (value) {
                  setState(() {
                    _tryOnAreaAvailable = value ?? false;
                  });
                },
                activeColor: AppConstants.primaryColor,
              ),
              Text(
                'Try-on Area Available',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: _requiresPurchase,
                onChanged: (value) {
                  setState(() {
                    _requiresPurchase = value ?? false;
                  });
                },
                activeColor: AppConstants.primaryColor,
              ),
              Text(
                'Requires Purchase',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 32),
              Checkbox(
                value: _irregularHours,
                onChanged: (value) {
                  setState(() {
                    _irregularHours = value ?? false;
                  });
                },
                activeColor: AppConstants.primaryColor,
              ),
              Text(
                'Irregular Hours',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build amenities section
  Widget _buildAmenitiesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                    label: Text(amenity),
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Build features section
  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableFeatures.map((feature) {
                  final isSelected = _selectedFeatures[feature] ?? false;
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFeatures[feature] = selected;
                      });
                    },
                    label: Text(feature),
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Build opening hours section for edit dialog
  Widget _buildOpeningHoursSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Opening Hours',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  _buildQuickActionButton('Copy Mon', () => _copyMondayHours()),
                  const SizedBox(width: 8),
                  _buildQuickActionButton('Clear All', () => _clearAllHours()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time presets
          Wrap(
            spacing: 8,
            children: [
              _buildPresetButton('9:00 AM - 6:00 PM', '09:00', '18:00'),
              _buildPresetButton('10:00 AM - 7:00 PM', '10:00', '19:00'),
              _buildPresetButton('8:00 AM - 5:00 PM', '08:00', '17:00'),
            ],
          ),
          const SizedBox(height: 16),

          // Daily time pickers
          ...[
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ].map((day) {
            final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
            final dayNames = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ];
            final dayIndex = dayNames.indexOf(day);
            final dayKey = dayKeys[dayIndex];
            final isClosed = _closedDays[dayKey] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isClosed ? Colors.grey.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      day,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            isClosed
                                ? Colors.grey.shade600
                                : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Checkbox(
                    value: isClosed,
                    onChanged: (value) {
                      setState(() {
                        _closedDays[dayKey] = value ?? false;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  Text(
                    'Closed',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!isClosed) ...[
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, dayKey, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _openingTimes[dayKey]?.format(context) ??
                                      'Open',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('-', style: GoogleFonts.inter(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _selectTime(context, dayKey, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _closingTimes[dayKey]?.format(context) ??
                                      'Close',
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Helper methods for edit dialog
  Widget _buildQuickActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
    );
  }

  Widget _buildPresetButton(String label, String openTime, String closeTime) {
    return ElevatedButton(
      onPressed: () => _applyTimePreset(openTime, closeTime),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
        foregroundColor: AppConstants.primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
    );
  }

  void _applyTimePreset(String openTime, String closeTime) {
    setState(() {
      for (String day in [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday',
      ]) {
        if (!_closedDays.containsKey(day) || !_closedDays[day]!) {
          // Parse time strings to TimeOfDay objects
          final openParts = openTime.split(':');
          final closeParts = closeTime.split(':');

          if (openParts.length == 2 && closeParts.length == 2) {
            final openHour = int.tryParse(openParts[0]);
            final openMinute = int.tryParse(openParts[1]);
            final closeHour = int.tryParse(closeParts[0]);
            final closeMinute = int.tryParse(closeParts[1]);

            if (openHour != null &&
                openMinute != null &&
                closeHour != null &&
                closeMinute != null) {
              _openingTimes[day] = TimeOfDay(
                hour: openHour,
                minute: openMinute,
              );
              _closingTimes[day] = TimeOfDay(
                hour: closeHour,
                minute: closeMinute,
              );
              _openingTimeControllers[day]?.text = openTime;
              _closingTimeControllers[day]?.text = closeTime;
            }
          }
        }
      }
    });
  }

  void _copyMondayHours() {
    final mondayOpen = _openingTimes['monday'];
    final mondayClose = _closingTimes['monday'];

    if (mondayOpen != null && mondayClose != null) {
      setState(() {
        for (String day in [
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ]) {
          if (!_closedDays.containsKey(day) || !_closedDays[day]!) {
            _openingTimes[day] = mondayOpen;
            _closingTimes[day] = mondayClose;
            _openingTimeControllers[day]?.text = mondayOpen.format(context);
            _closingTimeControllers[day]?.text = mondayClose.format(context);
          }
        }
      });
    }
  }

  void _clearAllHours() {
    setState(() {
      _openingTimes.updateAll((key, value) => null);
      _closingTimes.updateAll((key, value) => null);
      _closedDays.updateAll((key, value) => false);
      _openingTimeControllers.forEach((key, controller) => controller.clear());
      _closingTimeControllers.forEach((key, controller) => controller.clear());
    });
  }

  // Helper methods from original user-side implementation

  Future<void> _openMapPicker(BuildContext context) async {
    // Get initial coordinates if available
    double? initialLat;
    double? initialLng;

    if (_selectedLatitude != 0.0 && _selectedLongitude != 0.0) {
      initialLat = _selectedLatitude;
      initialLng = _selectedLongitude;
    }

    // Navigate to the map picker screen
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPickerScreen(
              initialLatitude: initialLat,
              initialLongitude: initialLng,
            ),
      ),
    );

    // Update coordinates if a location was selected
    if (result != null) {
      setState(() {
        _selectedLatitude = result.latitude;
        _selectedLongitude = result.longitude;
      });
    }
  }

  Future<void> _selectTime(
    BuildContext context,
    String day,
    bool isOpening,
  ) async {
    TimeOfDay? selectedTime =
        isOpening
            ? (_openingTimes[day] ?? TimeOfDay(hour: 9, minute: 0))
            : (_closingTimes[day] ?? TimeOfDay(hour: 18, minute: 0));

    final TimeOfDay? result = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        if (isOpening) {
          _openingTimes[day] = result;
          _openingTimeControllers[day]!.text = result.format(context);
        } else {
          _closingTimes[day] = result;
          _closingTimeControllers[day]!.text = result.format(context);
        }

        // If "Same time every day" is enabled, apply to all days
        if (_sameTimeEveryDay) {
          _openingTimeControllers.forEach((dayKey, controller) {
            if (isOpening) {
              _openingTimes[dayKey] = result;
              controller.text = result.format(context);
            } else {
              _closingTimes[dayKey] = result;
              _closingTimeControllers[dayKey]!.text = result.format(context);
            }
          });
        }
      });
    }
  }

  // Validate opening hours
  String? _validateHours() {
    for (String day in _openingTimeControllers.keys) {
      if (_closedDays[day] == true) continue;

      final opening = _openingTimes[day];
      final closing = _closingTimes[day];

      if (opening == null || closing == null) {
        return 'Please set both opening and closing times for $day or mark it as closed';
      }

      // Check if closing time is after opening time
      final openingMinutes = opening.hour * 60 + opening.minute;
      final closingMinutes = closing.hour * 60 + closing.minute;

      if (closingMinutes <= openingMinutes) {
        return '$day: Closing time must be after opening time';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1200,
        height: 1000,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Add New Shop',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Basic Information
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Shop Name',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Shop name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _areaController,
                              label: 'Area',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Area is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _addressController,
                        label: 'Full Address',
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Contact Information
                      _buildSectionHeader('Contact Information'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Phone number is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _facebookPageController,
                              label: 'Facebook Page (Optional)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Range Slider Section
                      _buildPriceRangeSection(),
                      const SizedBox(height: 16),

                      // Payment Methods Section
                      _buildPaymentMethodsSection(),
                      const SizedBox(height: 16),

                      // Additional Fields Section
                      _buildAdditionalFieldsSection(),
                      const SizedBox(height: 16),

                      // Amenities Section
                      _buildAmenitiesSection(),
                      const SizedBox(height: 16),

                      // Features Section
                      _buildFeaturesSection(),
                      const SizedBox(height: 16),

                      // Opening Hours Section
                      _buildOpeningHoursSection(),
                      const SizedBox(height: 24),

                      // Cover Image
                      _buildSectionHeader('Cover Image'),
                      const SizedBox(height: 16),
                      _buildImageUploadSection(),
                      const SizedBox(height: 24),

                      // Location
                      _buildSectionHeader('Location'),
                      const SizedBox(height: 16),
                      _buildLocationSection(),
                      const SizedBox(height: 24),

                      // Categories
                      _buildSectionHeader('Categories'),
                      const SizedBox(height: 16),
                      _buildCategorySelection(),
                      const SizedBox(height: 24),

                      // Sub-Services
                      if (_selectedCategories.isNotEmpty) ...[
                        _buildSectionHeader('Sub-Services'),
                        const SizedBox(height: 16),
                        _buildSubServicesSelection(),
                        const SizedBox(height: 24),
                      ],

                      // Status
                      _buildSectionHeader('Status'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Approved',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            _isApproved
                                ? 'Shop will be approved and visible to users'
                                : 'Shop will be pending approval',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          value: _isApproved,
                          onChanged: (value) {
                            setState(() {
                              _isApproved = value;
                            });
                          },
                          activeColor: AppConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Add Shop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Categories:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _availableCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(category);
                          // Initialize empty subservices list for this category
                          if (!_selectedSubServices.containsKey(category)) {
                            _selectedSubServices[category] = [];
                          }
                        } else {
                          _selectedCategories.remove(category);
                          // Remove subservices for this category
                          _selectedSubServices.remove(category);
                        }
                      });
                    },
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
          if (_selectedCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please select at least one category',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubServicesSelection() {
    return Column(
      children:
          _selectedCategories.map((category) {
            final availableSubServices = _categorySubServices[category] ?? [];
            final selectedSubServices = _selectedSubServices[category] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.toUpperCase()} Sub-Services:',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (availableSubServices.isEmpty)
                    Text(
                      'No sub-services available for this category',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          availableSubServices.map((subService) {
                            final isSelected = selectedSubServices.contains(
                              subService,
                            );
                            return FilterChip(
                              label: Text(
                                subService.replaceAll('_', ' ').toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSubServices[category] = [
                                      ...selectedSubServices,
                                      subService,
                                    ];
                                  } else {
                                    _selectedSubServices[category] =
                                        selectedSubServices
                                            .where((s) => s != subService)
                                            .toList();
                                  }
                                });
                              },
                              selectedColor: AppConstants.primaryColor
                                  .withOpacity(0.15),
                              checkmarkColor: AppConstants.primaryColor,
                              backgroundColor: Colors.grey[50],
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? AppConstants.primaryColor
                                        : const Color(0xFFE2E8F0),
                              ),
                            );
                          }).toList(),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  void _saveShop() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate opening hours
    final hoursValidationError = _validateHours();
    if (hoursValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hoursValidationError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Coordinates are already set via map picker

    // Create a map of opening hours like in the original user implementation
    final Map<String, String> hours = {};
    final List<String> closingDays = [];

    _openingTimeControllers.forEach((day, openingController) {
      final closingController = _closingTimeControllers[day]!;
      final isClosed = _closedDays[day] ?? false;

      if (isClosed) {
        hours[day] = 'Closed';
        closingDays.add(day);
      } else if (openingController.text.isNotEmpty &&
          closingController.text.isNotEmpty) {
        hours[day] = '${openingController.text} - ${closingController.text}';
      }
    });

    // Generate a unique ID for the shop
    final shopId = const Uuid().v4();

    final newShop = RepairShop(
      id: shopId, // Use generated UUID
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      area: _areaController.text.trim(),
      phoneNumber:
          _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
      priceRange: _formatPriceRange(_priceRangeValue),
      usualOpeningTime:
          hours.isNotEmpty
              ? hours
                  .entries
                  .first
                  .value // Use first day's hours as usual opening time
              : null,
      facebookPage:
          _facebookPageController.text.trim().isEmpty
              ? null
              : _facebookPageController.text.trim(),
      categories: _selectedCategories,
      subServices: _selectedSubServices,
      approved: _isApproved,
      latitude: _selectedLatitude,
      longitude: _selectedLongitude,
      rating: 0.0,
      reviewCount: 0,
      photos: _uploadedImageUrl != null ? [_uploadedImageUrl!] : [],
      hours: hours, // Use the properly structured hours map
      timestamp: DateTime.now(),
      buildingNumber:
          _buildingNumberController.text.trim().isEmpty
              ? null
              : _buildingNumberController.text.trim(),
      buildingName:
          _buildingNameController.text.trim().isEmpty
              ? null
              : _buildingNameController.text.trim(),
      buildingFloor:
          _buildingFloorController.text.trim().isEmpty
              ? null
              : _buildingFloorController.text.trim(),
      soi:
          _soiController.text.trim().isEmpty
              ? null
              : _soiController.text.trim(),
      district:
          _districtController.text.trim().isEmpty
              ? null
              : _districtController.text.trim(),
      province:
          _provinceController.text.trim().isEmpty
              ? null
              : _provinceController.text.trim(),
      landmark:
          _landmarkController.text.trim().isEmpty
              ? null
              : _landmarkController.text.trim(),
      lineId:
          _lineIdController.text.trim().isEmpty
              ? null
              : _lineIdController.text.trim(),
      instagramPage:
          _instagramPageController.text.trim().isEmpty
              ? null
              : _instagramPageController.text.trim(),
      otherContacts:
          _otherContactsController.text.trim().isEmpty
              ? null
              : _otherContactsController.text.trim(),
      notesOrConditions:
          _notesOrConditionsController.text.trim().isEmpty
              ? null
              : _notesOrConditionsController.text.trim(),
      paymentMethods:
          _selectedPaymentMethods.isNotEmpty ? _selectedPaymentMethods : null,
      tryOnAreaAvailable: _tryOnAreaAvailable,
      requiresPurchase: _requiresPurchase,
      amenities: _selectedAmenities,
      features: _selectedFeatures,
      durationMinutes: int.tryParse(_durationMinutesController.text) ?? 0,
      irregularHours: _irregularHours,
    );

    Navigator.of(context).pop();
    widget.onSave(newShop);
  }

  Future<void> _pickImage() async {
    try {
      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppConstants.primaryColor),
                  const SizedBox(width: 16),
                  const Text('Uploading image...'),
                ],
              ),
            ),
      );

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Upload to Firebase Storage
      final String fileName =
          'shop_add_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('shop_photos')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Close loading dialog
      Navigator.of(context).pop();

      // Update state with uploaded image
      setState(() {
        _uploadedImageUrl = downloadUrl;
        _selectedImagePath = image.path;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image uploaded successfully!'),
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Cover Photo',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          if (_uploadedImageUrl != null || _selectedImagePath != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image:
                    _uploadedImageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(_uploadedImageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  _uploadedImageUrl == null
                      ? const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Color(0xFF64748B),
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload, size: 20),
                  label: Text(
                    _uploadedImageUrl != null || _selectedImagePath != null
                        ? 'Change Image'
                        : 'Upload Image',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_uploadedImageUrl != null || _selectedImagePath != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImagePath = null;
                        _uploadedImageUrl = null;
                      });
                    },
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop Location',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordinates',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_selectedLatitude.toStringAsFixed(6)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Lng: ${_selectedLongitude.toStringAsFixed(6)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openMapPicker(context),
                icon: const Icon(Icons.map, size: 20),
                label: const Text('Pick Location on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
