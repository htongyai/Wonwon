import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wonwonw2/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:wonwonw2/screens/add_shop_screen.dart';

class AdminManageShopsScreen extends StatefulWidget {
  const AdminManageShopsScreen({Key? key}) : super(key: key);

  @override
  _AdminManageShopsScreenState createState() => _AdminManageShopsScreenState();
}

class _AdminManageShopsScreenState extends State<AdminManageShopsScreen> {
  final ShopService _shopService = ShopService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

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
                      comparison = a.name.compareTo(b.name);
                      break;
                    case 'rating':
                      comparison = a.rating.compareTo(b.rating);
                      break;
                    case 'reviewCount':
                      comparison = a.reviewCount.compareTo(b.reviewCount);
                      break;
                    case 'address':
                      comparison = a.address.compareTo(b.address);
                      break;
                    default:
                      comparison = a.name.compareTo(b.name);
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
        final isLargeScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 800;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              columnSpacing: isLargeScreen ? 32 : (isMediumScreen ? 24 : 16),
              horizontalMargin: isLargeScreen ? 24 : 16,
              columns: [
                _buildSortableColumn('Name', 'name'),
                if (isMediumScreen) _buildSortableColumn('Rating', 'rating'),
                if (isMediumScreen)
                  _buildSortableColumn('Reviews', 'reviewCount'),
                _buildSortableColumn('Address', 'address'),
                if (isLargeScreen) const DataColumn(label: Text('Categories')),
                if (isLargeScreen) const DataColumn(label: Text('Services')),
                const DataColumn(label: Text('Actions')),
              ],
              rows:
                  shops
                      .map(
                        (shop) =>
                            _buildShopRow(shop, isLargeScreen, isMediumScreen),
                      )
                      .toList(),
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
          Text(label),
          if (_sortBy == sortKey)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: AppConstants.primaryColor,
            ),
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
          Text(
            shop.name,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(shop.rating.toStringAsFixed(1)),
            ],
          ),
        ),
        DataCell(Text(shop.reviewCount.toString())),
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              shop.address,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  shop.categories
                      .take(3)
                      .map(
                        (category) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
        DataCell(
          Text(
            shop.subServices.isNotEmpty
                ? '${shop.subServices.values.first.length} services'
                : 'No services',
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _viewShopDetails(shop),
                icon: const Icon(Icons.visibility, size: 16),
                tooltip: 'View Details',
              ),
              IconButton(
                onPressed: () => _editShop(shop),
                icon: const Icon(Icons.edit, size: 16),
                tooltip: 'Edit Shop',
              ),
              IconButton(
                onPressed: () => _deleteShop(shop),
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                tooltip: 'Delete Shop',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _viewShopDetails(RepairShop shop) {
    context.push('/shops/${shop.id}');
  }

  void _editShop(RepairShop shop) {
    // TODO: Implement edit shop functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit shop: ${shop.name}')));
  }

  void _deleteShop(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Shop'),
            content: Text('Are you sure you want to delete "${shop.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement delete shop functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete shop: ${shop.name}')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
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
