import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/constants/responsive_breakpoints.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';
import 'package:wonwonw2/screens/edit_shop_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminManageShopsScreen extends StatefulWidget {
  const AdminManageShopsScreen({Key? key}) : super(key: key);

  @override
  _AdminManageShopsScreenState createState() => _AdminManageShopsScreenState();
}

class _AdminManageShopsScreenState extends State<AdminManageShopsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

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
                  FontAwesomeIcons.store,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  'Manage Shops',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkColor,
                  ),
                ),
                const Spacer(),
                // Add Shop button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddShopScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Add Shop',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Import Excel button
                ElevatedButton.icon(
                  onPressed: _importFromExcel,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: Text(
                    'Import Excel',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete All button
                ElevatedButton.icon(
                  onPressed: _showDeleteAllConfirmation,
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: Text(
                    'Delete All',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Refresh button
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Force rebuild
                    });
                  },
                  icon: Icon(Icons.refresh, color: AppConstants.primaryColor),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Search and controls
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search shops...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('shops')
                          .where('approved', isEqualTo: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final shops = snapshot.data!.docs;
                      return Text(
                        '${shops.length} shops',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      );
                    }
                    return Text(
                      'Loading...',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Table
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('shops')
                      .where('approved', isEqualTo: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Process shops with deduplication
                final Map<String, RepairShop> uniqueShops = {};
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  final shop = RepairShop.fromMap(data);

                  // Deduplicate by ID
                  if (!uniqueShops.containsKey(shop.id)) {
                    uniqueShops[shop.id] = shop;
                  }
                }

                final allShops = uniqueShops.values.toList();
                appLog('Total unique shops: ${allShops.length}');

                // Apply search filter
                final filteredShops =
                    _searchQuery.isEmpty
                        ? allShops
                        : allShops.where((shop) {
                          final query = _searchQuery.toLowerCase();
                          return shop.name.toLowerCase().contains(query) ||
                              shop.address.toLowerCase().contains(query) ||
                              shop.categories.any(
                                (category) =>
                                    category.toLowerCase().contains(query),
                              );
                        }).toList();

                // Apply sorting
                filteredShops.sort((a, b) {
                  int comparison = 0;
                  switch (_sortBy) {
                    case 'name':
                      comparison = a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                      break;
                    case 'rating':
                      comparison = a.rating.compareTo(b.rating);
                      break;
                    case 'reviewCount':
                      comparison = a.reviewCount.compareTo(b.reviewCount);
                      break;
                    case 'address':
                      comparison = a.address.toLowerCase().compareTo(
                        b.address.toLowerCase(),
                      );
                      break;
                    case 'categories':
                      final aCategories = a.categories.join(', ').toLowerCase();
                      final bCategories = b.categories.join(', ').toLowerCase();
                      comparison = aCategories.compareTo(bCategories);
                      break;
                    case 'services':
                      final aServices = a.subServices.values.fold<int>(
                        0,
                        (sum, services) => sum + services.length,
                      );
                      final bServices = b.subServices.values.fold<int>(
                        0,
                        (sum, services) => sum + services.length,
                      );
                      comparison = aServices.compareTo(bServices);
                      break;
                    case 'latitude':
                      comparison = a.latitude.compareTo(b.latitude);
                      break;
                    case 'longitude':
                      comparison = a.longitude.compareTo(b.longitude);
                      break;
                    default:
                      comparison = a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                  }
                  return _sortAscending ? comparison : -comparison;
                });

                appLog('Filtered and sorted shops: ${filteredShops.length}');

                return _buildShopsTable(filteredShops);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading shops',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Force rebuild
              });
            },
            child: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No shops found',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopsTable(List<RepairShop> shops) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = ResponsiveBreakpoints.isLargeDesktop(
          constraints.maxWidth,
        );
        final isMediumScreen = constraints.maxWidth > 800;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: isLargeScreen ? 20 : (isMediumScreen ? 16 : 12),
                horizontalMargin: isLargeScreen ? 16 : 12,
                columns: [
                  _buildSortableColumn('Name', 'name'),
                  if (isMediumScreen) _buildSortableColumn('Rating', 'rating'),
                  if (isMediumScreen)
                    _buildSortableColumn('Reviews', 'reviewCount'),
                  _buildSortableColumn('Address', 'address'),
                  if (isLargeScreen)
                    _buildSortableColumn('Categories', 'categories'),
                  if (isLargeScreen)
                    _buildSortableColumn('Services', 'services'),
                  if (isLargeScreen)
                    _buildSortableColumn('Latitude', 'latitude'),
                  if (isLargeScreen)
                    _buildSortableColumn('Longitude', 'longitude'),
                  const DataColumn(label: Text('Actions')),
                ],
                rows:
                    shops
                        .map(
                          (shop) => _buildShopRow(
                            shop,
                            isLargeScreen,
                            isMediumScreen,
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataColumn _buildSortableColumn(String label, String sortKey) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontWeight:
                  _sortBy == sortKey ? FontWeight.w600 : FontWeight.normal,
              color: _sortBy == sortKey ? AppConstants.primaryColor : null,
            ),
          ),
          const SizedBox(width: 4),
          if (_sortBy == sortKey)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: AppConstants.primaryColor,
            )
          else
            Icon(Icons.unfold_more, size: 16, color: Colors.grey[400]),
        ],
      ),
      onSort: (columnIndex, ascending) {
        setState(() {
          if (_sortBy == sortKey) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = sortKey;
            _sortAscending = true;
          }
        });
      },
    );
  }

  DataRow _buildShopRow(
    RepairShop shop,
    bool isLargeScreen,
    bool isMediumScreen,
  ) {
    return DataRow(
      key: ValueKey(shop.id),
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SizedBox(
                  width: 120, // Reduced by ~15% from typical name column width
                  child: Text(
                    shop.name,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showNameEditor(shop),
                icon: const Icon(Icons.edit, size: 12),
                tooltip: 'Edit Name',
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                shop.rating.toStringAsFixed(1),
                style: GoogleFonts.montserrat(fontSize: 12),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            shop.reviewCount.toString(),
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SizedBox(
                  width: 180,
                  child: Text(
                    shop.address,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: GoogleFonts.montserrat(fontSize: 12),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showAddressEditor(shop),
                icon: const Icon(Icons.edit, size: 12),
                tooltip: 'Edit Address',
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shop.categories.isNotEmpty)
                        ...shop.categories
                            .take(2)
                            .map(
                              (category) => Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    color: AppConstants.primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                      if (shop.categories.length > 2)
                        Text(
                          '+${shop.categories.length - 2} more',
                          style: GoogleFonts.montserrat(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showCategoryDropdown(shop),
                icon: const Icon(Icons.settings, size: 14),
                tooltip: 'Manage Categories',
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
              IconButton(
                onPressed: () => _showAddCategoryDropdown(shop),
                icon: const Icon(Icons.add_circle_outline, size: 14),
                tooltip: 'Add Category',
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  shop.subServices.isNotEmpty
                      ? '${shop.subServices.values.fold<int>(0, (sum, services) => sum + services.length)} services'
                      : 'No services',
                  style: GoogleFonts.montserrat(fontSize: 11),
                ),
              ),
              IconButton(
                onPressed: () => _showSubServiceDropdown(shop),
                icon: const Icon(Icons.settings, size: 14),
                tooltip: 'Manage Sub-Services',
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
              IconButton(
                onPressed: () => _showAddServiceDropdown(shop),
                icon: const Icon(Icons.add_circle_outline, size: 14),
                tooltip: 'Add Service',
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              ),
            ],
          ),
        ),
        if (isLargeScreen)
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    shop.latitude.toStringAsFixed(6),
                    style: GoogleFonts.montserrat(fontSize: 11),
                  ),
                ),
                IconButton(
                  onPressed: () => _showCoordinateEditor(shop, 'latitude'),
                  icon: const Icon(Icons.edit, size: 12),
                  tooltip: 'Edit Latitude',
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                ),
              ],
            ),
          ),
        if (isLargeScreen)
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    shop.longitude.toStringAsFixed(6),
                    style: GoogleFonts.montserrat(fontSize: 11),
                  ),
                ),
                IconButton(
                  onPressed: () => _showCoordinateEditor(shop, 'longitude'),
                  icon: const Icon(Icons.edit, size: 12),
                  tooltip: 'Edit Longitude',
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                ),
              ],
            ),
          ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _viewShopDetails(shop),
                icon: const Icon(Icons.visibility, size: 14),
                tooltip: 'View Details',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              IconButton(
                onPressed: () => _editShop(shop),
                icon: const Icon(Icons.edit, size: 14),
                tooltip: 'Edit Shop',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              IconButton(
                onPressed: () => _showPhotoOptions(shop),
                icon: const Icon(Icons.photo_camera, size: 14),
                tooltip: 'Photo Options',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
              IconButton(
                onPressed: () => _deleteShop(shop),
                icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                tooltip: 'Delete Shop',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _viewShopDetails(RepairShop shop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ShopDetailScreen(shopId: shop.id),
      ),
    );
  }

  void _editShop(RepairShop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditShopScreen(shop: shop)),
    ).then((result) {
      if (result == true) {
        // Refresh the list if shop was updated successfully
        setState(() {
          // Force rebuild
        });
      }
    });
  }

  Future<void> _assignCategory(RepairShop shop, String category) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Updating category...'),
                ],
              ),
            ),
      );

      // Update the shop's categories
      List<String> updatedCategories = List.from(shop.categories);
      if (!updatedCategories.contains(category)) {
        updatedCategories.add(category);
      }

      // Update in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'categories': updatedCategories,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$category" added to "${shop.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error updating category: $e');
    }
  }

  Future<void> _removeCategory(RepairShop shop, String category) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Removing category...'),
                ],
              ),
            ),
      );

      // Update the shop's categories
      List<String> updatedCategories = List.from(shop.categories);
      updatedCategories.remove(category);

      // Update in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'categories': updatedCategories,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$category" removed from "${shop.name}"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error removing category: $e');
    }
  }

  void _showCategoryDropdown(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Manage Categories for ${shop.name}'),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current categories: ${shop.categories.isEmpty ? "None" : shop.categories.join(", ")}',
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ..._availableCategories.map((category) {
                    final isAssigned = shop.categories.contains(category);
                    return ListTile(
                      leading: Icon(
                        isAssigned
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isAssigned ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        category,
                        style: GoogleFonts.montserrat(
                          fontWeight:
                              isAssigned ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing:
                          isAssigned
                              ? IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _removeCategory(shop, category);
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Remove category',
                              )
                              : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!isAssigned) {
                          _assignCategory(shop, category);
                        }
                      },
                    );
                  }).toList(),
                ],
              ),
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

  Future<void> _assignSubService(
    RepairShop shop,
    String category,
    String subService,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Adding sub-service...'),
                ],
              ),
            ),
      );

      // Update the shop's sub-services
      Map<String, List<String>> updatedSubServices = Map.from(shop.subServices);
      if (!updatedSubServices.containsKey(category)) {
        updatedSubServices[category] = [];
      }
      if (!updatedSubServices[category]!.contains(subService)) {
        updatedSubServices[category]!.add(subService);
      }

      // Update in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'subServices': updatedSubServices,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sub-service "$subService" added to "${shop.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding sub-service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error adding sub-service: $e');
    }
  }

  Future<void> _removeSubService(
    RepairShop shop,
    String category,
    String subService,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Removing sub-service...'),
                ],
              ),
            ),
      );

      // Update the shop's sub-services
      Map<String, List<String>> updatedSubServices = Map.from(shop.subServices);
      if (updatedSubServices.containsKey(category)) {
        updatedSubServices[category]!.remove(subService);
        if (updatedSubServices[category]!.isEmpty) {
          updatedSubServices.remove(category);
        }
      }

      // Update in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'subServices': updatedSubServices,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sub-service "$subService" removed from "${shop.name}"',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing sub-service: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error removing sub-service: $e');
    }
  }

  void _showSubServiceDropdown(RepairShop shop) {
    if (shop.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please assign categories first before managing sub-services',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Manage Sub-Services for ${shop.name}'),
            content: SizedBox(
              width: 400,
              height: 500,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: shop.categories.length,
                      itemBuilder: (context, index) {
                        final category = shop.categories[index];
                        final subServices =
                            _categorySubServices[category] ?? [];
                        final currentSubServices =
                            shop.subServices[category] ?? [];

                        return ExpansionTile(
                          title: Text(
                            category,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children:
                              subServices.map((subService) {
                                final isAssigned = currentSubServices.contains(
                                  subService,
                                );
                                return ListTile(
                                  leading: Icon(
                                    isAssigned
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        isAssigned ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  title: Text(
                                    subService.replaceAll('_', ' '),
                                    style: GoogleFonts.montserrat(
                                      fontWeight:
                                          isAssigned
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing:
                                      isAssigned
                                          ? IconButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _removeSubService(
                                                shop,
                                                category,
                                                subService,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Remove sub-service',
                                          )
                                          : null,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    if (!isAssigned) {
                                      _assignSubService(
                                        shop,
                                        category,
                                        subService,
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
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

  void _showAddCategoryDropdown(RepairShop shop) {
    final availableCategories =
        _availableCategories
            .where((category) => !shop.categories.contains(category))
            .toList();

    if (availableCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All categories are already assigned to this shop'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Set<String> selectedCategories = {};

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Add Categories to ${shop.name}'),
                  content: SizedBox(
                    width: 350,
                    height: 400,
                    child: Column(
                      children: [
                        Text(
                          'Select categories to add:',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: availableCategories.length,
                            itemBuilder: (context, index) {
                              final category = availableCategories[index];
                              final isSelected = selectedCategories.contains(
                                category,
                              );

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedCategories.add(category);
                                    } else {
                                      selectedCategories.remove(category);
                                    }
                                  });
                                },
                                title: Text(
                                  category,
                                  style: GoogleFonts.montserrat(fontSize: 13),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            },
                          ),
                        ),
                        if (selectedCategories.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${selectedCategories.length} category(ies) selected',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedCategories.isEmpty
                              ? null
                              : () async {
                                Navigator.of(context).pop();
                                await _assignMultipleCategories(
                                  shop,
                                  selectedCategories.toList(),
                                );
                              },
                      child: const Text('Add Selected'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _assignMultipleCategories(
    RepairShop shop,
    List<String> categories,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Adding categories...'),
                ],
              ),
            ),
      );

      // Update the shop's categories
      List<String> updatedCategories = List.from(shop.categories);
      for (final category in categories) {
        if (!updatedCategories.contains(category)) {
          updatedCategories.add(category);
        }
      }

      // Update in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'categories': updatedCategories,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${categories.length} category(ies) added to "${shop.name}"',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error adding multiple categories: $e');
    }
  }

  void _showAddServiceDropdown(RepairShop shop) {
    if (shop.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please assign categories first before adding services',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, Set<String>> selectedServices = {};

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('Add Services to ${shop.name}'),
                  content: SizedBox(
                    width: 400,
                    height: 500,
                    child: Column(
                      children: [
                        Text(
                          'Select services to add:',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: shop.categories.length,
                            itemBuilder: (context, index) {
                              final category = shop.categories[index];
                              final subServices =
                                  _categorySubServices[category] ?? [];
                              final currentSubServices =
                                  shop.subServices[category] ?? [];
                              final availableSubServices =
                                  subServices
                                      .where(
                                        (subService) =>
                                            !currentSubServices.contains(
                                              subService,
                                            ),
                                      )
                                      .toList();

                              if (availableSubServices.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return ExpansionTile(
                                title: Text(
                                  category,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${availableSubServices.length} services available',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                children:
                                    availableSubServices.map((subService) {
                                      final isSelected =
                                          selectedServices[category]?.contains(
                                            subService,
                                          ) ??
                                          false;

                                      return CheckboxListTile(
                                        value: isSelected,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (!selectedServices.containsKey(
                                              category,
                                            )) {
                                              selectedServices[category] = {};
                                            }
                                            if (value == true) {
                                              selectedServices[category]!.add(
                                                subService,
                                              );
                                            } else {
                                              selectedServices[category]!
                                                  .remove(subService);
                                            }
                                          });
                                        },
                                        title: Text(
                                          subService.replaceAll('_', ' '),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                          ),
                                        ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                        ),
                        if (selectedServices.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${selectedServices.values.fold<int>(0, (sum, services) => sum + services.length)} service(s) selected',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedServices.isEmpty
                              ? null
                              : () async {
                                Navigator.of(context).pop();
                                await _assignMultipleServices(
                                  shop,
                                  selectedServices,
                                );
                              },
                      child: const Text('Add Selected'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _assignMultipleServices(
    RepairShop shop,
    Map<String, Set<String>> selectedServices,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Adding services...'),
                ],
              ),
            ),
      );

      // Update the shop's sub-services
      Map<String, List<String>> updatedSubServices = Map.from(shop.subServices);

      for (final entry in selectedServices.entries) {
        final category = entry.key;
        final services = entry.value;

        if (!updatedSubServices.containsKey(category)) {
          updatedSubServices[category] = [];
        }

        for (final service in services) {
          if (!updatedSubServices[category]!.contains(service)) {
            updatedSubServices[category]!.add(service);
          }
        }
      }

      // Update in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'subServices': updatedSubServices,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Calculate total services added
      final totalServices = selectedServices.values.fold<int>(
        0,
        (sum, services) => sum + services.length,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$totalServices service(s) added to "${shop.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error adding multiple services: $e');
    }
  }

  void _showCoordinateEditor(RepairShop shop, String coordinateType) {
    final TextEditingController coordinateController = TextEditingController();
    final String currentValue =
        coordinateType == 'latitude'
            ? shop.latitude.toStringAsFixed(6)
            : shop.longitude.toStringAsFixed(6);

    coordinateController.text = currentValue;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Edit ${coordinateType.toUpperCase()} for ${shop.name}',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current ${coordinateType}: $currentValue',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: coordinateController,
                  decoration: InputDecoration(
                    labelText: 'New ${coordinateType.toUpperCase()}',
                    hintText:
                        coordinateType == 'latitude' ? '13.7563' : '100.5018',
                    prefixIcon: Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                    border: const OutlineInputBorder(),
                    helperText:
                        coordinateType == 'latitude'
                            ? 'Enter latitude (e.g., 13.7563 for Bangkok) - You can paste coordinates'
                            : 'Enter longitude (e.g., 100.5018 for Bangkok) - You can paste coordinates',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Format: Decimal degrees (e.g., 13.7563, 100.5018)',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newValue = coordinateController.text.trim();
                  if (newValue.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid coordinate'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final double? parsedValue = double.tryParse(newValue);
                  if (parsedValue == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid number'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validate coordinate ranges
                  if (coordinateType == 'latitude' &&
                      (parsedValue < -90 || parsedValue > 90)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Latitude must be between -90 and 90 degrees',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (coordinateType == 'longitude' &&
                      (parsedValue < -180 || parsedValue > 180)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Longitude must be between -180 and 180 degrees',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  await _updateCoordinate(shop, coordinateType, parsedValue);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateCoordinate(
    RepairShop shop,
    String coordinateType,
    double newValue,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Updating coordinate...'),
                ],
              ),
            ),
      );

      // Update the coordinate in Firestore
      final updateData =
          coordinateType == 'latitude'
              ? {'latitude': newValue}
              : {'longitude': newValue};

      await _firestore.collection('shops').doc(shop.id).update(updateData);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${coordinateType.toUpperCase()} updated for "${shop.name}"',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating ${coordinateType}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error updating coordinate: $e');
    }
  }

  void _showNameEditor(RepairShop shop) {
    final TextEditingController nameController = TextEditingController();
    nameController.text = shop.name;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Shop Name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current name: ${shop.name}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'New Shop Name',
                    hintText: 'Enter shop name',
                    border: OutlineInputBorder(),
                    helperText: 'Enter the complete shop name',
                  ),
                  maxLength: 100,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid shop name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (newName.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Shop name must be at least 2 characters long',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  await _updateShopName(shop, newName);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _showAddressEditor(RepairShop shop) {
    final TextEditingController addressController = TextEditingController();
    addressController.text = shop.address;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Address for ${shop.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current address: ${shop.address}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'New Address',
                    hintText: 'Enter complete address',
                    border: OutlineInputBorder(),
                    helperText: 'Enter the full shop address',
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newAddress = addressController.text.trim();
                  if (newAddress.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid address'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (newAddress.length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Address must be at least 5 characters long',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.of(context).pop();
                  await _updateShopAddress(shop, newAddress);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateShopName(RepairShop shop, String newName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Updating shop name...'),
                ],
              ),
            ),
      );

      // Update the shop name in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'name': newName,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shop name updated to "$newName"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating shop name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error updating shop name: $e');
    }
  }

  Future<void> _updateShopAddress(RepairShop shop, String newAddress) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Updating address...'),
                ],
              ),
            ),
      );

      // Update the shop address in Firestore
      await _firestore.collection('shops').doc(shop.id).update({
        'address': newAddress,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Address updated for "${shop.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error updating address: $e');
    }
  }

  Future<void> _uploadCoverPhoto(RepairShop shop) async {
    try {
      // Pick image
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
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Uploading photo...'),
                ],
              ),
            ),
      );

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Compress image for web
      Uint8List compressedBytes = imageBytes;
      if (kIsWeb) {
        compressedBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: 800,
          minWidth: 600,
          quality: 85,
        );
      }

      // Upload to Firebase Storage
      final String fileName =
          'shop_${shop.id}_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('shop_photos')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putData(compressedBytes);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update shop with new cover photo
      List<String> updatedPhotos = List.from(shop.photos);
      if (updatedPhotos.isNotEmpty) {
        // Replace the first photo (cover image)
        updatedPhotos[0] = downloadUrl;
      } else {
        // Add as first photo if no photos exist
        updatedPhotos.insert(0, downloadUrl);
      }

      await _firestore.collection('shops').doc(shop.id).update({
        'photos': updatedPhotos,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cover photo updated for "${shop.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error uploading cover photo: $e');
    }
  }

  void _showPhotoOptions(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Photo Options for ${shop.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shop.photos.isNotEmpty) ...[
                  Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        shop.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current cover photo',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Upload New Cover Photo'),
                  subtitle: const Text('Select from gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadCoverPhoto(shop);
                  },
                ),
                if (shop.photos.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.visibility, color: Colors.green),
                    title: const Text('View All Photos'),
                    subtitle: Text('${shop.photos.length} photos'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _viewAllPhotos(shop);
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

  void _viewAllPhotos(RepairShop shop) {
    if (shop.photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photos available for this shop'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Photos for ${shop.name}'),
            content: SizedBox(
              width: 400,
              height: 300,
              child: ListView.builder(
                itemCount: shop.photos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              shop.photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Photo ${index + 1}',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (index == 0)
                                Text(
                                  'Cover Photo',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.green[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteShop(RepairShop shop) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Shop'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${shop.name}"?'),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone. All shop data, reviews, and photos will be permanently deleted.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return; // User cancelled
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Deleting shop...'),
                ],
              ),
            ),
      );

      // Delete the shop document from Firestore
      await _firestore.collection('shops').doc(shop.id).delete();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shop "${shop.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting shop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      appLog('Error deleting shop: $e');
    }
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Text(
                'Delete All Shops',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ALL shops? This action cannot be undone and will permanently remove all shop data from the database.',
            style: GoogleFonts.montserrat(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllShops();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete All',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllShops() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text('Deleting all shops...', style: GoogleFonts.montserrat()),
              ],
            ),
          );
        },
      );

      // Get all shop documents
      final QuerySnapshot snapshot = await _firestore.collection('shops').get();

      if (snapshot.docs.isEmpty) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No shops found to delete.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Delete all documents in batches
      final batch = _firestore.batch();
      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }

      // Commit the batch
      await batch.commit();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deleted $deletedCount shops.'),
          backgroundColor: Colors.green,
        ),
      );

      appLog('Successfully deleted $deletedCount shops');
    } catch (e) {
      // Close loading dialog if it's still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting shops: $e'),
          backgroundColor: Colors.red,
        ),
      );
      appLog('Error deleting all shops: $e');
    }
  }

  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.isEmpty) return;
      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) throw Exception('File could not be read');
      final excelFile = excel.Excel.decodeBytes(fileBytes);
      int importedCount = 0;
      int failedCount = 0;
      List<String> failedRows = [];

      for (final table in excelFile.tables.keys) {
        final sheet = excelFile.tables[table]!;
        if (sheet.maxRows < 2) continue; // skip if no data

        // Get headers and validate required columns
        final headers =
            sheet.rows[0]
                .map(
                  (cell) => cell?.value?.toString().trim().toLowerCase() ?? '',
                )
                .toList();
        final requiredColumns = [
          'name',
          'description',
          'address',
          'area',
          'categories',
          'latitude',
          'longitude',
          'rating',
          'amenities',
          'durationminutes',
          'requirespurchase',
          'pricerange',
          'buildingnumber',
          'buildingname',
          'soi',
          'district',
          'province',
          'landmark',
          'lineid',
          'facebookpage',
          'othercontacts',
          'cash',
          'qr',
          'credit',
          'mon',
          'tue',
          'wed',
          'thu',
          'fri',
          'sat',
          'sun',
          'instagrampage',
          'phonenumber',
          'buildingfloor',
          'isapproved',
          'verification_status',
          'image_url',
          'paymentmethods',
          'tryonareaavailable',
          'notesorconditions',
          'usualopeningtime',
          'gmap link',
          'note',
        ];

        // Validate headers
        final missingColumns =
            requiredColumns
                .where((col) => !headers.contains(col.toLowerCase()))
                .toList();
        if (missingColumns.isNotEmpty) {
          final foundHeaders = headers.where((h) => h.isNotEmpty).join(', ');
          throw Exception(
            'Missing required columns: ${missingColumns.join(", ")}\n\nFound headers in file: $foundHeaders',
          );
        }

        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          // Skip row if all columns are empty or whitespace
          if (row.every(
            (cell) =>
                cell == null ||
                cell.value == null ||
                cell.value.toString().trim().isEmpty,
          )) {
            continue;
          }

          try {
            final Map<String, dynamic> data = {};
            for (int j = 0; j < headers.length && j < row.length; j++) {
              final value = row[j]?.value;
              if (value != null && value.toString().trim().isNotEmpty) {
                data[headers[j]] = value;
              }
            }

            // Process opening hours
            Map<String, String> hours = {};
            final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
            for (final day in days) {
              final timeStr = data[day]?.toString().trim() ?? '';
              if (timeStr.isEmpty || timeStr.toLowerCase() == 'closed') {
                hours[day] = 'Closed';
              } else {
                // Convert periods to colons
                final normalized = timeStr.replaceAll('.', ':');
                final parts = normalized.split('-');
                if (parts.length == 2) {
                  final openingTime = parts[0].trim();
                  final closingTime = parts[1].trim();
                  hours[day] = '$openingTime - $closingTime';
                } else {
                  hours[day] = 'Closed';
                }
              }
            }

            // Process payment methods - check both individual columns and combined column
            List<String> paymentMethods = [];

            // Check individual payment method columns
            if (data['cash']?.toString().toLowerCase() == 'true') {
              paymentMethods.add('cash');
            }
            if (data['qr']?.toString().toLowerCase() == 'true') {
              paymentMethods.add('qr');
            }
            if (data['credit']?.toString().toLowerCase() == 'true') {
              paymentMethods.add('card');
            }

            // If no individual methods found, try the combined column
            if (paymentMethods.isEmpty && data['paymentmethods'] != null) {
              paymentMethods =
                  data['paymentmethods']
                      .toString()
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
            }

            // Generate a unique ID for the shop
            final shopId = const Uuid().v4();

            // Get verification status from Excel or verify coordinates
            String verificationStatus =
                data['verification_status']?.toString() ?? '';
            if (verificationStatus.isEmpty) {
              final lat =
                  double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
              final lng =
                  double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;
              verificationStatus = _verifyGeocoding(
                lat,
                lng,
                data['address']?.toString() ?? '',
              );
            }

            // Process image URL
            String? imageUrl = data['image_url']?.toString();
            if (imageUrl == null || imageUrl.trim().isEmpty) {
              imageUrl = null;
            }

            final shop = RepairShop(
              id: shopId,
              name: data['name']?.toString() ?? '',
              description: data['description']?.toString() ?? '',
              address: data['address']?.toString() ?? '',
              area: data['area']?.toString() ?? '',
              categories:
                  (data['categories'] is String)
                      ? (data['categories'] as String)
                          .split(',')
                          .map((e) => e.trim())
                          .toList()
                      : [],
              rating: double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
              amenities:
                  (data['amenities'] is String)
                      ? (data['amenities'] as String)
                          .split(',')
                          .map((e) => e.trim())
                          .toList()
                      : [],
              hours: hours,
              closingDays: [],
              latitude:
                  double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
              longitude:
                  double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
              durationMinutes:
                  int.tryParse(data['durationminutes']?.toString() ?? '0') ?? 0,
              requiresPurchase:
                  (data['requirespurchase']?.toString().toLowerCase() ==
                      'true'),
              photos: imageUrl != null ? [imageUrl] : [],
              priceRange: data['pricerange']?.toString() ?? '₿',
              features: {},
              approved:
                  (data['isapproved']?.toString().toLowerCase() == 'true'),
              irregularHours: false,
              subServices: {},
              buildingNumber: data['buildingnumber']?.toString(),
              buildingName: data['buildingname']?.toString(),
              soi: data['soi']?.toString(),
              district: data['district']?.toString(),
              province: data['province']?.toString(),
              landmark: data['landmark']?.toString(),
              lineId: data['lineid']?.toString(),
              facebookPage: data['facebookpage']?.toString(),
              otherContacts: data['othercontacts']?.toString(),
              paymentMethods: paymentMethods.isNotEmpty ? paymentMethods : null,
              tryOnAreaAvailable:
                  (data['tryonareaavailable']?.toString().toLowerCase() ==
                      'true'),
              notesOrConditions: data['notesorconditions']?.toString(),
              usualOpeningTime: data['usualopeningtime']?.toString(),
              instagramPage: data['instagrampage']?.toString(),
              phoneNumber: data['phonenumber']?.toString(),
              buildingFloor: data['buildingfloor']?.toString(),
            );

            // Add to Firestore with verification status and additional data
            await FirebaseFirestore.instance
                .collection('shops')
                .doc(shopId)
                .set({
                  ...shop.toMap(),
                  'verification_status': verificationStatus,
                  'gMap_link': data['gmap link']?.toString(),
                  'note': data['note']?.toString(),
                });

            importedCount++;
          } catch (e) {
            failedCount++;
            failedRows.add('Row ${i + 1}: ${e.toString()}');
          }
        }
      }

      // Show import results
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Import Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Successfully imported $importedCount shops.'),
                  if (failedCount > 0) ...[
                    const SizedBox(height: 8),
                    Text('Failed to import $failedCount shops:'),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                      width: double.maxFinite,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              failedRows
                                  .map(
                                    (error) => Text(
                                      '• $error',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Import Failed'),
              content: Text('Error: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  String _verifyGeocoding(double lat, double lng, String address) {
    // Basic verification logic
    if (lat == 0.0 && lng == 0.0) {
      return 'unverified';
    }
    if (lat >= 5.0 && lat <= 21.0 && lng >= 97.0 && lng <= 106.0) {
      return 'verified'; // Thailand coordinates
    }
    return 'unverified';
  }
}
