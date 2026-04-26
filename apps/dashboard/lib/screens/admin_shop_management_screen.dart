import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared/constants/app_constants.dart';
import 'package:wonwon_dashboard/widgets/optimized_screen.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/services/shop_service.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:wonwon_dashboard/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wonwon_dashboard/widgets/admin/shop_form_widgets.dart';
import 'package:shared/services/google_maps_link_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:wonwon_dashboard/widgets/admin/csv_bulk_import_dialog.dart';
import 'package:wonwon_dashboard/widgets/admin/shop_data_warnings.dart';

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
  String _statusFilter = 'all'; // all, approved, pending, rejected
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
              Expanded(
                child: Text(
                  'admin_shop_management'.tr(context),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showBulkActionsDialog,
                    icon: const FaIcon(FontAwesomeIcons.tasks, size: 14),
                    label: Text('admin_bulk_actions'.tr(context)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'manual') {
                        _showAddShopDialog();
                      } else if (value == 'google_maps') {
                        _showGoogleMapsLinkDialog();
                      } else if (value == 'csv_import') {
                        _showCsvImportDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'google_maps',
                        child: Row(
                          children: [
                            Icon(Icons.link, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'add_from_google_maps'.tr(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'add_from_google_maps_desc'.tr(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'manual',
                        child: Row(
                          children: [
                            Icon(Icons.edit_note, color: Colors.grey[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'add_manually'.tr(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'add_manually_desc'.tr(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'csv_import',
                        child: Row(
                          children: [
                            Icon(Icons.upload_file_rounded, color: Colors.teal[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'csv_import'.tr(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'csv_import_desc'.tr(context),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.plus, size: 14, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'add_shop'.tr(context),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                        ],
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search always full width
                  TextField(
                    onChanged: (value) {
                      safeSetState(() { _searchQuery = value; });
                    },
                    decoration: InputDecoration(
                      hintText: 'admin_search_shops'.tr(context),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filters — Row on desktop, Wrap on mobile
                  if (isWide)
                    Row(
                      children: [
                        Expanded(child: _buildStatusDropdown(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCategoryDropdown(context)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildSortDropdown(context)),
                        const SizedBox(width: 8),
                        _buildSortDirectionButton(context),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(width: constraints.maxWidth * 0.48, child: _buildStatusDropdown(context)),
                        SizedBox(width: constraints.maxWidth * 0.48, child: _buildCategoryDropdown(context)),
                        SizedBox(width: constraints.maxWidth * 0.48, child: _buildSortDropdown(context)),
                        _buildSortDirectionButton(context),
                      ],
                    ),
                ],
              );
            },
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
                return Center(child: Text('${'admin_error_loading_shops'.tr(context)}: ${snapshot.error}'));
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
      // Three-way: approved / pending / rejected. We key on
      // shop.approvalStatus rather than the legacy bool because the
      // bool can't distinguish "not yet reviewed" from "explicitly
      // rejected" — both are `approved == false`. Without this branch
      // the rejected items pollute the pending queue forever.
      if (_statusFilter != 'all') {
        if (_statusFilter == 'approved' &&
            !(shop.approved && shop.approvalStatus != 'rejected')) {
          return false;
        }
        if (_statusFilter == 'pending') {
          // Pending = not yet reviewed: not approved AND not rejected.
          if (shop.approved || shop.approvalStatus == 'rejected') {
            return false;
          }
        }
        if (_statusFilter == 'rejected' && shop.approvalStatus != 'rejected') {
          return false;
        }
      } else {
        // "all" should hide rejected by default — these are not
        // actionable in the main list and have their own filter for
        // when an admin needs to review them.
        if (shop.approvalStatus == 'rejected') return false;
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
            'no_shops_found'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'admin_no_shops_match_filters'.tr(context),
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

  Widget _buildStatusDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _statusFilter,
      decoration: InputDecoration(
        labelText: 'status_label'.tr(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: Colors.white,
      ),
      items: [
        DropdownMenuItem(value: 'all', child: Text('admin_all_status'.tr(context))),
        DropdownMenuItem(value: 'approved', child: Text('approved'.tr(context))),
        DropdownMenuItem(value: 'pending', child: Text('admin_filter_pending'.tr(context))),
        DropdownMenuItem(value: 'rejected', child: Text('admin_filter_rejected'.tr(context))),
      ],
      onChanged: (value) { safeSetState(() { _statusFilter = value!; }); },
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _categoryFilter,
      decoration: InputDecoration(
        labelText: 'category_form_label'.tr(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: Colors.white,
      ),
      items: [
        DropdownMenuItem(value: 'all', child: Text('admin_all_categories'.tr(context))),
        ..._categories.map((category) => DropdownMenuItem(value: category, child: Text('category_${category.toLowerCase()}'.tr(context)))),
      ],
      onChanged: (value) { safeSetState(() { _categoryFilter = value!; }); },
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      decoration: InputDecoration(
        labelText: 'admin_sort_by'.tr(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: Colors.white,
      ),
      items: [
        DropdownMenuItem(value: 'name', child: Text('admin_sort_name'.tr(context))),
        DropdownMenuItem(value: 'rating', child: Text('rating'.tr(context))),
        DropdownMenuItem(value: 'area', child: Text('area_label'.tr(context))),
        DropdownMenuItem(value: 'lastViewed', child: Text('admin_last_viewed'.tr(context))),
      ],
      onChanged: (value) { safeSetState(() { _sortBy = value!; }); },
    );
  }

  Widget _buildSortDirectionButton(BuildContext context) {
    return IconButton(
      onPressed: () { safeSetState(() { _sortAscending = !_sortAscending; }); },
      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF64748B)),
      tooltip: _sortAscending ? 'admin_sort_ascending'.tr(context) : 'admin_sort_descending'.tr(context),
      style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE2E8F0))),
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
            color: Colors.black.withValues(alpha: 0.02),
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
                          Flexible(
                            child: Text(
                              shop.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: shop.approvalStatus == 'rejected'
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                  : shop.approved
                                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                      : const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              shop.approvalStatus == 'rejected'
                                  ? 'admin_filter_rejected'.tr(context)
                                  : shop.approved
                                      ? 'admin_status_approved'.tr(context)
                                      : 'admin_status_pending'.tr(context),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: shop.approvalStatus == 'rejected'
                                    ? const Color(0xFFEF4444)
                                    : shop.approved
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFDF59E0B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ShopWarningBadge(shop: shop),
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
                              'admin_last_viewed_time'.tr(context).replaceAll('{time}', _formatLastViewedTime(context, _shopLastViewedMap[shop.id]!)),
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
                          tooltip: 'admin_view_details'.tr(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.1),
                            foregroundColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _editShop(shop),
                          icon: const FaIcon(FontAwesomeIcons.edit, size: 16),
                          tooltip: 'admin_edit_shop'.tr(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.1),
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
                            tooltip: 'admin_approve_shop'.tr(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFF10B981),
                            ),
                          ),
                        if (!shop.approved) const SizedBox(width: 8),
                        if (!shop.approved)
                          IconButton(
                            onPressed: () => _rejectShop(shop),
                            icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                            tooltip: 'admin_reject_shop'.tr(context),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316).withValues(alpha: 0.1),
                              foregroundColor: const Color(0xFFF97316),
                            ),
                          ),
                        if (!shop.approved) const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _deleteShop(shop),
                          icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                          tooltip: 'admin_delete_shop'.tr(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.1),
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
                            color: const Color(0xFF64748B).withValues(alpha: 0.1),
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
              width: min(600, MediaQuery.of(context).size.width * 0.95),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'admin_shop_details'.tr(context),
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
                  _buildDetailRow('admin_label_name'.tr(context), shop.name),
                  _buildDetailRow('description'.tr(context), shop.description),
                  _buildDetailRow('area_label'.tr(context), shop.area),
                  _buildDetailRow('address_label'.tr(context), shop.address),
                  _buildDetailRow(
                    'rating'.tr(context),
                    '${shop.rating.toStringAsFixed(1)} (${shop.reviewCount} reviews)',
                  ),
                  _buildDetailRow(
                    'categories'.tr(context),
                    shop.categories
                        .map((c) => 'category_${c.toLowerCase()}'.tr(context))
                        .join(', '),
                  ),
                  _buildDetailRow('price_range'.tr(context), shop.priceRange.trim().isEmpty ? 'not_set'.tr(context) : shop.priceRange),
                  _buildDetailRow(
                    'status_label'.tr(context),
                    shop.approved ? 'approved'.tr(context) : 'admin_filter_pending'.tr(context),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('ok_label'.tr(context)),
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
              setLoading(true, message: 'admin_updating_shop'.tr(context));
              try {
                final success = await _shopService.updateShop(updatedShop);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('admin_shop_updated'.tr(context).replaceAll('{shop_name}', updatedShop.name)),
                      backgroundColor: AppConstants.primaryColor,
                    ),
                  );
                } else {
                  throw Exception('Failed to update shop');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${'admin_error_updating_shop'.tr(context)}: $e'),
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
            title: Text('admin_approve_shop'.tr(context)),
            content: Text('admin_confirm_approve_shop'.tr(context).replaceAll('{shop_name}', shop.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                child: Text('admin_approve'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'admin_approving_shop'.tr(context));

      try {
        final success = await _shopService.approveShop(shop.id);
        // Also update approvalStatus field
        await FirebaseFirestore.instance.collection('shops').doc(shop.id).update({
          'approvalStatus': 'approved',
          'rejectionReason': null,
        });

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin_shop_approved'.tr(context).replaceAll('{shop_name}', shop.name)),
              backgroundColor: AppConstants.primaryColor,
            ),
          );
        } else {
          throw Exception('Failed to approve shop');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin_error_approving_shop'.tr(context)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  void _rejectShop(RepairShop shop) async {
    final reasonController = TextEditingController();
    // Track validity reactively so the Reject button stays disabled
    // until a non-empty reason is typed. We require a reason because:
    //   - the shop owner needs to know what to fix on resubmission
    //   - audit trail: future admins reviewing the queue need
    //     context for why this was rejected
    // Empty/whitespace-only is treated the same as no input.
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final reasonValid = reasonController.text.trim().isNotEmpty;
          return AlertDialog(
            title: Text('admin_reject_shop'.tr(context)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin_confirm_reject_shop'.tr(context).replaceAll('{shop_name}', shop.name),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: 'rejection_reason_label'.tr(context),
                    hintText: 'rejection_reason_hint'.tr(context),
                    border: const OutlineInputBorder(),
                    errorText: reasonValid
                        ? null
                        : 'rejection_reason_required'.tr(context),
                  ),
                  maxLines: 3,
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: reasonValid
                    ? () => Navigator.of(context)
                        .pop(reasonController.text.trim())
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('admin_reject'.tr(context)),
              ),
            ],
          );
        },
      ),
    );
    reasonController.dispose();

    if (result != null) {
      setLoading(true, message: 'admin_rejecting_shop'.tr(context));

      try {
        await FirebaseFirestore.instance.collection('shops').doc(shop.id).update({
          'approved': false,
          'approvalStatus': 'rejected',
          'rejectionReason': result,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('admin_shop_rejected'.tr(context).replaceAll('{shop_name}', shop.name)),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin_error_rejecting_shop'.tr(context)}: $e'),
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
            title: Text('admin_delete_shop'.tr(context)),
            content: Text(
              'admin_confirm_delete_shop'.tr(context).replaceAll('{shop_name}', shop.name),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('delete'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'admin_deleting_shop'.tr(context));

      try {
        final success = await _shopService.deleteShop(shop.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin_shop_deleted'.tr(context).replaceAll('{shop_name}', shop.name)),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          throw Exception('Failed to delete shop');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin_error_deleting_shop'.tr(context)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  void _showAddShopDialog() {
    _openAddShopForm();
  }

  /// Common save handler for the add shop dialog
  Future<void> _handleShopSave(RepairShop newShop) async {
    setLoading(true, message: 'admin_adding_shop'.tr(context));
    try {
      final success = await _shopService.addShop(newShop);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('admin_shop_added'.tr(context).replaceAll('{shop_name}', newShop.name)),
            backgroundColor: AppConstants.primaryColor,
          ),
        );
      } else {
        throw Exception('Failed to add shop');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'admin_error_adding_shop'.tr(context)}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setLoading(false);
    }
  }

  /// Open the add shop form, optionally with pre-filled data from Google Maps
  void _openAddShopForm({GoogleMapsLinkResult? prefillData, Uint8List? prefillPhoto}) {
    showDialog(
      context: context,
      builder: (context) => _AddShopDialog(
        onSave: _handleShopSave,
        prefillData: prefillData,
        prefillPhoto: prefillPhoto,
      ),
    );
  }

  /// Show the Google Maps link extraction dialog
  void _showCsvImportDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const CsvBulkImportDialog(),
    );
  }

  void _showGoogleMapsLinkDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _GoogleMapsLinkExtractDialog(
        onExtracted: (result, photo) {
          // Close the link dialog, then open the form with pre-filled data
          Navigator.of(ctx).pop();
          _openAddShopForm(prefillData: result, prefillPhoto: photo);
        },
        onCancel: () {
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showBulkActionsDialog() {
    if (_selectedShopIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin_select_shops_for_bulk'.tr(context)),
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
              'admin_bulk_actions_selected'.tr(context).replaceAll('{count}', '${_selectedShopIds.length}'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('admin_approve_all_selected'.tr(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkApproveShops();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.orange),
                  title: Text('admin_unapprove_all_selected'.tr(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _bulkUnapproveShops();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('admin_delete_all_selected'.tr(context)),
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
                child: Text('cancel'.tr(context)),
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
            title: Text('admin_bulk_approve_shops'.tr(context)),
            content: Text(
              'admin_confirm_bulk_approve'.tr(context).replaceAll('{count}', '${_selectedShopIds.length}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('admin_approve_all'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'admin_approving_shops'.tr(context));
      try {
        int successCount = 0;
        for (final shopId in _selectedShopIds) {
          final success = await _shopService.approveShop(shopId);
          if (success) successCount++;
        }

        safeSetState(() {
          _selectedShopIds.clear();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('admin_shops_approved_success'.tr(context).replaceAll('{count}', '$successCount')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin_error_bulk_approval'.tr(context)}: $e'),
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
            title: Text('admin_bulk_unapprove_shops'.tr(context)),
            content: Text(
              'admin_confirm_bulk_unapprove'.tr(context).replaceAll('{count}', '${_selectedShopIds.length}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('admin_unapprove_all'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'admin_unapproving_shops'.tr(context));
      try {
        int successCount = 0;
        for (final shopId in _selectedShopIds) {
          final success = await _shopService.updateShopApprovalStatus(shopId, false);
          if (success) successCount++;
        }

        safeSetState(() {
          _selectedShopIds.clear();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('admin_shops_unapproved_success'.tr(context).replaceAll('{count}', '$successCount')),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin_error_bulk_unapproval'.tr(context)}: $e'),
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
            title: Text('admin_bulk_delete_shops'.tr(context)),
            content: Text(
              'admin_confirm_bulk_delete'.tr(context).replaceAll('{count}', '${_selectedShopIds.length}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('admin_delete_all'.tr(context)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setLoading(true, message: 'admin_deleting_shops'.tr(context));
      try {
        int successCount = 0;
        for (final shopId in _selectedShopIds) {
          final success = await _shopService.deleteShop(shopId);
          if (success) successCount++;
        }

        safeSetState(() {
          _selectedShopIds.clear();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('admin_shops_deleted_success'.tr(context).replaceAll('{count}', '$successCount')),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'admin_error_bulk_deletion'.tr(context)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setLoading(false);
      }
    }
  }

  String _formatLastViewedTime(BuildContext context, DateTime lastViewed) {
    final now = DateTime.now();
    final difference = now.difference(lastViewed);

    if (difference.inMinutes < 1) {
      return 'admin_just_now'.tr(context);
    } else if (difference.inMinutes < 60) {
      return 'admin_minutes_ago'.tr(context).replaceAll('{m}', '${difference.inMinutes}');
    } else if (difference.inHours < 24) {
      return 'admin_hours_ago'.tr(context).replaceAll('{h}', '${difference.inHours}');
    } else if (difference.inDays < 7) {
      return 'admin_days_ago'.tr(context).replaceAll('{d}', '${difference.inDays}');
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'admin_weeks_ago'.tr(context).replaceAll('{w}', '$weeks');
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

  static const Map<String, String> _amenityToKey = {
    'WiFi': 'admin_amenity_wifi',
    'Parking': 'admin_amenity_parking',
    'Air Conditioning': 'admin_amenity_air_conditioning',
    'Waiting Area': 'admin_amenity_waiting_area',
    'Restroom': 'admin_amenity_restroom',
    'Credit Card Payment': 'admin_amenity_credit_card_payment',
    'Cash Only': 'admin_amenity_cash_only',
    'Appointment Required': 'admin_amenity_appointment_required',
    'Walk-in Welcome': 'admin_amenity_walk_in_welcome',
    'Express Service': 'admin_amenity_express_service',
  };

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

  static const Map<String, String> _featureToKey = {
    'Same Day Service': 'admin_feature_same_day_service',
    'Express Repair': 'admin_feature_express_repair',
    'Warranty Provided': 'admin_feature_warranty_provided',
    'Pick-up Service': 'admin_feature_pick_up_service',
    'Delivery Service': 'admin_feature_delivery_service',
    'Online Booking': 'admin_feature_online_booking',
    'Expert Technician': 'admin_feature_expert_technician',
    'Genuine Parts': 'admin_feature_genuine_parts',
    'Free Consultation': 'admin_feature_free_consultation',
    'Quality Guarantee': 'admin_feature_quality_guarantee',
  };

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
    final bahtCount = priceRange.split('฿').length - 1;
    return bahtCount.toDouble().clamp(1.0, 5.0);
  }

  // Convert slider value to baht symbols
  String _formatPriceRange(double value) {
    return '฿' * value.round();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: min(1200, MediaQuery.of(context).size.width * 0.95),
        height: min(1000, MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                  'admin_edit_shop'.tr(context),
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
                      ShopFormWidgets.buildSectionHeader('admin_basic_info'.tr(context)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _nameController,
                              label: 'shop_name_label'.tr(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'admin_shop_name_required'.tr(context);
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _areaController,
                              label: 'area_label'.tr(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'admin_area_required'.tr(context);
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ShopFormWidgets.buildTextField(
                        controller: _descriptionController,
                        label: 'description'.tr(context),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin_description_required'.tr(context);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      ShopFormWidgets.buildTextField(
                        controller: _addressController,
                        label: 'admin_label_full_address'.tr(context),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin_address_required'.tr(context);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Contact Information
                      ShopFormWidgets.buildSectionHeader('admin_contact_info'.tr(context)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _phoneController,
                              label: 'phone_number_label'.tr(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'admin_phone_required'.tr(context);
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _facebookPageController,
                              label: 'facebook_optional_label'.tr(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Range Slider Section
                      ShopFormWidgets.buildPriceRangeSection(
                        context: context,
                        value: _priceRangeValue,
                        onChanged: (value) {
                          setState(() {
                            _priceRangeValue = value;
                          });
                        },
                        formatPriceRange: _formatPriceRange,
                      ),
                      const SizedBox(height: 16),

                      // Payment Methods Section
                      ShopFormWidgets.buildPaymentMethodsSection(
                        context: context,
                        availablePaymentMethods: _availablePaymentMethods,
                        selectedPaymentMethods: _selectedPaymentMethods,
                        onToggle: (method, selected) {
                          setState(() {
                            if (selected) {
                              _selectedPaymentMethods.add(method);
                            } else {
                              _selectedPaymentMethods.remove(method);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Additional Fields Section
                      _buildAdditionalFieldsSection(),
                      const SizedBox(height: 16),

                      // Amenities Section
                      ShopFormWidgets.buildAmenitiesSection(
                        context: context,
                        availableAmenities: _availableAmenities,
                        selectedAmenities: _selectedAmenities,
                        amenityToKey: _amenityToKey,
                        onToggle: (amenity, selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Features Section
                      ShopFormWidgets.buildFeaturesSection(
                        context: context,
                        availableFeatures: _availableFeatures,
                        selectedFeatures: _selectedFeatures,
                        featureToKey: _featureToKey,
                        onToggle: (feature, selected) {
                          setState(() {
                            _selectedFeatures[feature] = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Opening Hours Section
                      _buildOpeningHoursSection(),
                      const SizedBox(height: 24),

                      // Cover Image
                      ShopFormWidgets.buildSectionHeader('admin_cover_image'.tr(context)),
                      const SizedBox(height: 16),
                      _buildImageUploadSection(),
                      const SizedBox(height: 24),

                      // Location
                      ShopFormWidgets.buildSectionHeader('admin_location'.tr(context)),
                      const SizedBox(height: 16),
                      _buildLocationSection(),
                      const SizedBox(height: 24),

                      // Categories
                      ShopFormWidgets.buildSectionHeader('categories'.tr(context)),
                      const SizedBox(height: 16),
                      _buildCategorySelection(),
                      const SizedBox(height: 24),

                      // Sub-Services
                      if (_selectedCategories.isNotEmpty) ...[
                        ShopFormWidgets.buildSectionHeader('admin_sub_services'.tr(context)),
                        const SizedBox(height: 16),
                        _buildSubServicesSelection(),
                        const SizedBox(height: 24),
                      ],

                      // Status
                      ShopFormWidgets.buildSectionHeader('status_label'.tr(context)),
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
                            'approved'.tr(context),
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
                  child: Text('cancel'.tr(context)),
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
                  child: Text('admin_save_changes'.tr(context)),
                ),
              ],
            ),
          ],
        ),
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
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
          if (_selectedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'please_select_at_least_one_category'.tr(context),
                style: const TextStyle(color: Colors.red, fontSize: 12),
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
                    'sub_services_for_category'.tr(context).replaceAll('{category}', category.toUpperCase()),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (availableSubServices.isEmpty)
                    Text(
                      'no_sub_services_available'.tr(context),
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
                                  .withValues(alpha: 0.15),
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
                  Text('admin_uploading_image'.tr(context)),
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
      if (!mounted) return;
      Navigator.of(context).pop();

      // Update state with uploaded image
      setState(() {
        _uploadedImageUrl = downloadUrl;
        _selectedImagePath = image.name;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin_image_uploaded'.tr(context)),
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
          content: Text('${'admin_error_uploading_image'.tr(context)}: $e'),
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
            'admin_upload_cover_photo'.tr(context),
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
                          image: CachedNetworkImageProvider(_uploadedImageUrl!),
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
                        ? 'admin_change_image'.tr(context)
                        : 'admin_upload_image'.tr(context),
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
                    label: Text('remove'.tr(context)),
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
            'admin_shop_location'.tr(context),
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
                        'admin_coordinates'.tr(context),
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
                label: Text('admin_pick_location_on_map'.tr(context)),
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
            'admin_additional_information'.tr(context),
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
                child: ShopFormWidgets.buildTextField(
                  controller: _buildingNumberController,
                  label: 'building_number_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _buildingNameController,
                  label: 'building_name_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _buildingFloorController,
                  label: 'building_floor_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _soiController,
                  label: 'soi_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _districtController,
                  label: 'district_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _provinceController,
                  label: 'province_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ShopFormWidgets.buildTextField(controller: _landmarkController, label: 'landmark_label'.tr(context)),
          const SizedBox(height: 16),

          // Contact Information
          Row(
            children: [
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _lineIdController,
                  label: 'line_id_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _instagramPageController,
                  label: 'instagram_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ShopFormWidgets.buildTextField(
            controller: _otherContactsController,
            label: 'other_contacts_label'.tr(context),
          ),
          const SizedBox(height: 16),

          ShopFormWidgets.buildTextField(
            controller: _notesOrConditionsController,
            label: 'admin_notes_or_conditions'.tr(context),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Duration field
          ShopFormWidgets.buildTextField(
            controller: _durationMinutesController,
            label: 'admin_service_duration_minutes'.tr(context),
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
                'admin_try_on_area_available'.tr(context),
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
                'admin_requires_purchase'.tr(context),
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
                'admin_irregular_hours'.tr(context),
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
                'admin_opening_hours'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  ShopFormWidgets.buildQuickActionButton('admin_copy_mon'.tr(context), () => _copyMondayHours()),
                  const SizedBox(width: 8),
                  ShopFormWidgets.buildQuickActionButton('admin_clear_all'.tr(context), () => _clearAllHours()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time presets
          Wrap(
            spacing: 8,
            children: [
              ShopFormWidgets.buildPresetButton(label: 'admin_preset_9_6'.tr(context), onPressed: () => _applyTimePreset('09:00', '18:00')),
              ShopFormWidgets.buildPresetButton(label: 'admin_preset_10_7'.tr(context), onPressed: () => _applyTimePreset('10:00', '19:00')),
              ShopFormWidgets.buildPresetButton(label: 'admin_preset_8_5'.tr(context), onPressed: () => _applyTimePreset('08:00', '17:00')),
            ],
          ),
          const SizedBox(height: 16),

          // Daily time pickers
          ...[
            'day_monday',
            'day_tuesday',
            'day_wednesday',
            'day_thursday',
            'day_friday',
            'day_saturday',
            'day_sunday',
          ].map((dayKey) {
            final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
            final dayIndex = ['day_monday', 'day_tuesday', 'day_wednesday', 'day_thursday', 'day_friday', 'day_saturday', 'day_sunday'].indexOf(dayKey);
            final dayKeyShort = dayKeys[dayIndex];
            final isClosed = _closedDays[dayKeyShort] ?? false;

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
                      dayKey.tr(context),
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
                        _closedDays[dayKeyShort] = value ?? false;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  Text(
                    'closed_label'.tr(context),
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
                              onTap: () => _selectTime(context, dayKeyShort, true),
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
                                  _openingTimes[dayKeyShort]?.format(context) ??
                                      'admin_open'.tr(context),
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
                              onTap: () => _selectTime(context, dayKeyShort, false),
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
                                  _closingTimes[dayKeyShort]?.format(context) ??
                                      'admin_close'.tr(context),
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
    // The time maps use 3-letter keys ('mon', 'tue', ...) — not full names.
    final mondayOpen = _openingTimes['mon'];
    final mondayClose = _closingTimes['mon'];

    if (mondayOpen == null || mondayClose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin_set_monday_first'.tr(context)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      for (final day in ['tue', 'wed', 'thu', 'fri', 'sat', 'sun']) {
        if (_closedDays[day] == true) continue;
        _openingTimes[day] = mondayOpen;
        _closingTimes[day] = mondayClose;
        _openingTimeControllers[day]?.text = mondayOpen.format(context);
        _closingTimeControllers[day]?.text = mondayClose.format(context);
      }
    });
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_select_at_least_one_category'.tr(context)),
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
  final GoogleMapsLinkResult? prefillData;
  final Uint8List? prefillPhoto;

  const _AddShopDialog({
    required this.onSave,
    this.prefillData,
    this.prefillPhoto,
  });

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

  static const Map<String, String> _amenityToKey = {
    'WiFi': 'admin_amenity_wifi',
    'Parking': 'admin_amenity_parking',
    'Air Conditioning': 'admin_amenity_air_conditioning',
    'Waiting Area': 'admin_amenity_waiting_area',
    'Restroom': 'admin_amenity_restroom',
    'Credit Card Payment': 'admin_amenity_credit_card_payment',
    'Cash Only': 'admin_amenity_cash_only',
    'Appointment Required': 'admin_amenity_appointment_required',
    'Walk-in Welcome': 'admin_amenity_walk_in_welcome',
    'Express Service': 'admin_amenity_express_service',
  };

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

  static const Map<String, String> _featureToKey = {
    'Same Day Service': 'admin_feature_same_day_service',
    'Express Repair': 'admin_feature_express_repair',
    'Warranty Provided': 'admin_feature_warranty_provided',
    'Pick-up Service': 'admin_feature_pick_up_service',
    'Delivery Service': 'admin_feature_delivery_service',
    'Online Booking': 'admin_feature_online_booking',
    'Expert Technician': 'admin_feature_expert_technician',
    'Genuine Parts': 'admin_feature_genuine_parts',
    'Free Consultation': 'admin_feature_free_consultation',
    'Quality Guarantee': 'admin_feature_quality_guarantee',
  };

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
  // Photo bytes from Google Maps extraction (held transiently until uploaded)
  Uint8List? _prefillPhotoBytes;
  // Shown under the Cover Image row while the prefill photo is uploading.
  bool _isUploadingPrefillPhoto = false;

  @override
  void initState() {
    super.initState();
    _applyPrefillData();
    // If the Maps import provided a photo, upload it in the background so
    // the Cover Image field fills in without manual picking.
    if (_prefillPhotoBytes != null) {
      // Defer until after first frame so setState is safe.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _uploadPrefillPhoto();
      });
    }
  }

  /// Apply pre-filled data from Google Maps link extraction
  void _applyPrefillData() {
    final data = widget.prefillData;
    if (data == null) return;

    _selectedLatitude = data.latitude;
    _selectedLongitude = data.longitude;

    if (data.placeName != null) _nameController.text = data.placeName!;
    if (data.phoneNumber != null) _phoneController.text = data.phoneNumber!;
    if (data.fullAddress != null) _addressController.text = data.fullAddress!;
    if (data.district != null) {
      _areaController.text = data.district!;
      _districtController.text = data.district!;
    }
    if (data.province != null) _provinceController.text = data.province!;
    if (data.street != null) _soiController.text = data.street!;
    if (data.buildingNumber != null) {
      _buildingNumberController.text = data.buildingNumber!;
    }
    if (data.buildingName != null) {
      _buildingNameController.text = data.buildingName!;
    }
    if (data.landmark != null) _landmarkController.text = data.landmark!;
    if (data.website != null) _otherContactsController.text = data.website!;

    // Categories
    if (data.matchedCategories != null && data.matchedCategories!.isNotEmpty) {
      for (final cat in data.matchedCategories!) {
        if (_availableCategories.contains(cat) &&
            !_selectedCategories.contains(cat)) {
          _selectedCategories.add(cat);
          _selectedSubServices[cat] = [];
        }
      }
    }

    // Opening hours
    if (data.openingHours != null && data.openingHours!.isNotEmpty) {
      const dayMapping = {
        1: 'mon', 2: 'tue', 3: 'wed', 4: 'thu',
        5: 'fri', 6: 'sat', 0: 'sun',
      };
      for (final entry in data.openingHours!.entries) {
        final dayKey = dayMapping[entry.key];
        if (dayKey == null) continue;
        final period = entry.value;
        if (period.isClosed) {
          _closedDays[dayKey] = true;
        } else {
          _closedDays[dayKey] = false;
          final openTime = TimeOfDay(hour: period.openHour, minute: period.openMinute);
          final closeTime = TimeOfDay(hour: period.closeHour, minute: period.closeMinute);
          _openingTimes[dayKey] = openTime;
          _closingTimes[dayKey] = closeTime;
          _openingTimeControllers[dayKey]?.text = '${period.openHour.toString().padLeft(2, '0')}:${period.openMinute.toString().padLeft(2, '0')}';
          _closingTimeControllers[dayKey]?.text = '${period.closeHour.toString().padLeft(2, '0')}:${period.closeMinute.toString().padLeft(2, '0')}';
        }
      }
    }

    // Photo from extraction — held here; uploaded in initState after first frame.
    _prefillPhotoBytes = widget.prefillPhoto;
  }

  /// Upload the Google-Maps-extracted photo bytes to Firebase Storage and
  /// set [_uploadedImageUrl] so the Cover Image section renders the preview.
  /// Fires on widget init if [widget.prefillPhoto] was provided.
  Future<void> _uploadPrefillPhoto() async {
    final bytes = _prefillPhotoBytes;
    if (bytes == null) return;
    if (!mounted) return;
    setState(() => _isUploadingPrefillPhoto = true);
    try {
      final fileName =
          'shop_import_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('shop_photos')
          .child(fileName);
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        _uploadedImageUrl = downloadUrl;
        _selectedImagePath = fileName;
        _isUploadingPrefillPhoto = false;
        // Drop the raw bytes — we have the URL now.
        _prefillPhotoBytes = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPrefillPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'admin_error_uploading_image'.tr(context)}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatPriceRange(double value) {
    return '฿' * value.round();
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
            'admin_additional_information'.tr(context),
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
                child: ShopFormWidgets.buildTextField(
                  controller: _buildingNumberController,
                  label: 'building_number_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _buildingNameController,
                  label: 'building_name_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _buildingFloorController,
                  label: 'building_floor_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _soiController,
                  label: 'soi_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _districtController,
                  label: 'district_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _provinceController,
                  label: 'province_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ShopFormWidgets.buildTextField(controller: _landmarkController, label: 'landmark_label'.tr(context)),
          const SizedBox(height: 16),

          // Contact Information
          Row(
            children: [
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _lineIdController,
                  label: 'line_id_label'.tr(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShopFormWidgets.buildTextField(
                  controller: _instagramPageController,
                  label: 'instagram_label'.tr(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ShopFormWidgets.buildTextField(
            controller: _otherContactsController,
            label: 'other_contacts_label'.tr(context),
          ),
          const SizedBox(height: 16),

          ShopFormWidgets.buildTextField(
            controller: _notesOrConditionsController,
            label: 'admin_notes_or_conditions'.tr(context),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Duration field
          ShopFormWidgets.buildTextField(
            controller: _durationMinutesController,
            label: 'admin_service_duration_minutes'.tr(context),
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
                'admin_try_on_area_available'.tr(context),
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
                'admin_requires_purchase'.tr(context),
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
                'admin_irregular_hours'.tr(context),
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
                'admin_opening_hours'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  ShopFormWidgets.buildQuickActionButton('admin_copy_mon'.tr(context), () => _copyMondayHours()),
                  const SizedBox(width: 8),
                  ShopFormWidgets.buildQuickActionButton('admin_clear_all'.tr(context), () => _clearAllHours()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time presets
          Wrap(
            spacing: 8,
            children: [
              ShopFormWidgets.buildPresetButton(label: 'admin_preset_9_6'.tr(context), onPressed: () => _applyTimePreset('09:00', '18:00')),
              ShopFormWidgets.buildPresetButton(label: 'admin_preset_10_7'.tr(context), onPressed: () => _applyTimePreset('10:00', '19:00')),
              ShopFormWidgets.buildPresetButton(label: 'admin_preset_8_5'.tr(context), onPressed: () => _applyTimePreset('08:00', '17:00')),
            ],
          ),
          const SizedBox(height: 16),

          // Daily time pickers
          ...[
            'day_monday',
            'day_tuesday',
            'day_wednesday',
            'day_thursday',
            'day_friday',
            'day_saturday',
            'day_sunday',
          ].map((dayKey) {
            final dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
            final dayIndex = ['day_monday', 'day_tuesday', 'day_wednesday', 'day_thursday', 'day_friday', 'day_saturday', 'day_sunday'].indexOf(dayKey);
            final dayKeyShort = dayKeys[dayIndex];
            final isClosed = _closedDays[dayKeyShort] ?? false;

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
                      dayKey.tr(context),
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
                        _closedDays[dayKeyShort] = value ?? false;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                  Text(
                    'closed_label'.tr(context),
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
                              onTap: () => _selectTime(context, dayKeyShort, true),
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
                                  _openingTimes[dayKeyShort]?.format(context) ??
                                      'admin_open'.tr(context),
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
                              onTap: () => _selectTime(context, dayKeyShort, false),
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
                                  _closingTimes[dayKeyShort]?.format(context) ??
                                      'admin_close'.tr(context),
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
    // The time maps use 3-letter keys ('mon', 'tue', ...) — not full names.
    final mondayOpen = _openingTimes['mon'];
    final mondayClose = _closingTimes['mon'];

    if (mondayOpen == null || mondayClose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin_set_monday_first'.tr(context)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      for (final day in ['tue', 'wed', 'thu', 'fri', 'sat', 'sun']) {
        if (_closedDays[day] == true) continue;
        _openingTimes[day] = mondayOpen;
        _closingTimes[day] = mondayClose;
        _openingTimeControllers[day]?.text = mondayOpen.format(context);
        _closingTimeControllers[day]?.text = mondayClose.format(context);
      }
    });
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
  String? _validateHours(BuildContext context) {
    const dayKeyToName = {
      'mon': 'day_monday',
      'tue': 'day_tuesday',
      'wed': 'day_wednesday',
      'thu': 'day_thursday',
      'fri': 'day_friday',
      'sat': 'day_saturday',
      'sun': 'day_sunday',
    };
    for (String day in _openingTimeControllers.keys) {
      if (_closedDays[day] == true) continue;

      final opening = _openingTimes[day];
      final closing = _closingTimes[day];

      if (opening == null || closing == null) {
        final dayName = (dayKeyToName[day] ?? day).tr(context);
        return 'admin_hours_required_for_day'.tr(context).replaceAll('{day}', dayName);
      }

      // Check if closing time is after opening time
      final openingMinutes = opening.hour * 60 + opening.minute;
      final closingMinutes = closing.hour * 60 + closing.minute;

      if (closingMinutes <= openingMinutes) {
        final dayName = (dayKeyToName[day] ?? day).tr(context);
        return 'admin_closing_after_opening'.tr(context).replaceAll('{day}', dayName);
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
        width: min(1200, MediaQuery.of(context).size.width * 0.95),
        height: min(1000, MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                  'admin_add_new_shop'.tr(context),
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
                      ShopFormWidgets.buildSectionHeader('admin_basic_info'.tr(context)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _nameController,
                              label: 'shop_name_label'.tr(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'admin_shop_name_required'.tr(context);
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _areaController,
                              label: 'area_label'.tr(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'admin_area_required'.tr(context);
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ShopFormWidgets.buildTextField(
                        controller: _descriptionController,
                        label: 'description'.tr(context),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin_description_required'.tr(context);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      ShopFormWidgets.buildTextField(
                        controller: _addressController,
                        label: 'admin_label_full_address'.tr(context),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin_address_required'.tr(context);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Contact Information
                      ShopFormWidgets.buildSectionHeader('admin_contact_info'.tr(context)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _phoneController,
                              label: 'phone_number_label'.tr(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'admin_phone_required'.tr(context);
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ShopFormWidgets.buildTextField(
                              controller: _facebookPageController,
                              label: 'facebook_optional_label'.tr(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Price Range Slider Section
                      ShopFormWidgets.buildPriceRangeSection(
                        context: context,
                        value: _priceRangeValue,
                        onChanged: (value) {
                          setState(() {
                            _priceRangeValue = value;
                          });
                        },
                        formatPriceRange: _formatPriceRange,
                      ),
                      const SizedBox(height: 16),

                      // Payment Methods Section
                      ShopFormWidgets.buildPaymentMethodsSection(
                        context: context,
                        availablePaymentMethods: _availablePaymentMethods,
                        selectedPaymentMethods: _selectedPaymentMethods,
                        onToggle: (method, selected) {
                          setState(() {
                            if (selected) {
                              _selectedPaymentMethods.add(method);
                            } else {
                              _selectedPaymentMethods.remove(method);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Additional Fields Section
                      _buildAdditionalFieldsSection(),
                      const SizedBox(height: 16),

                      // Amenities Section
                      ShopFormWidgets.buildAmenitiesSection(
                        context: context,
                        availableAmenities: _availableAmenities,
                        selectedAmenities: _selectedAmenities,
                        amenityToKey: _amenityToKey,
                        onToggle: (amenity, selected) {
                          setState(() {
                            if (selected) {
                              _selectedAmenities.add(amenity);
                            } else {
                              _selectedAmenities.remove(amenity);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Features Section
                      ShopFormWidgets.buildFeaturesSection(
                        context: context,
                        availableFeatures: _availableFeatures,
                        selectedFeatures: _selectedFeatures,
                        featureToKey: _featureToKey,
                        onToggle: (feature, selected) {
                          setState(() {
                            _selectedFeatures[feature] = selected;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Opening Hours Section
                      _buildOpeningHoursSection(),
                      const SizedBox(height: 24),

                      // Cover Image
                      ShopFormWidgets.buildSectionHeader('admin_cover_image'.tr(context)),
                      const SizedBox(height: 16),
                      _buildImageUploadSection(),
                      const SizedBox(height: 24),

                      // Location
                      ShopFormWidgets.buildSectionHeader('admin_location'.tr(context)),
                      const SizedBox(height: 16),
                      _buildLocationSection(),
                      const SizedBox(height: 24),

                      // Categories
                      ShopFormWidgets.buildSectionHeader('categories'.tr(context)),
                      const SizedBox(height: 16),
                      _buildCategorySelection(),
                      const SizedBox(height: 24),

                      // Sub-Services
                      if (_selectedCategories.isNotEmpty) ...[
                        ShopFormWidgets.buildSectionHeader('admin_sub_services'.tr(context)),
                        const SizedBox(height: 16),
                        _buildSubServicesSelection(),
                        const SizedBox(height: 24),
                      ],

                      // Status
                      ShopFormWidgets.buildSectionHeader('status_label'.tr(context)),
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
                            'approved'.tr(context),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            _isApproved
                                ? 'admin_shop_approved_visible'.tr(context)
                                : 'admin_shop_pending_approval'.tr(context),
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
                  child: Text('cancel'.tr(context)),
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
                  child: Text('add_shop'.tr(context)),
                ),
              ],
            ),
          ],
        ),
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
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
          if (_selectedCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'please_select_at_least_one_category'.tr(context),
                style: const TextStyle(color: Colors.red, fontSize: 12),
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
                    'sub_services_for_category'.tr(context).replaceAll('{category}', category.toUpperCase()),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (availableSubServices.isEmpty)
                    Text(
                      'no_sub_services_available'.tr(context),
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
                                  .withValues(alpha: 0.15),
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_select_at_least_one_category'.tr(context)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate opening hours
    final hoursValidationError = _validateHours(context);
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
                  Text('admin_uploading_image'.tr(context)),
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
      if (!mounted) return;
      Navigator.of(context).pop();

      // Update state with uploaded image
      setState(() {
        _uploadedImageUrl = downloadUrl;
        _selectedImagePath = image.name;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin_image_uploaded'.tr(context)),
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
          content: Text('${'admin_error_uploading_image'.tr(context)}: $e'),
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
            'admin_upload_cover_photo'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          // While the Google-Maps photo is uploading, show a live preview of
          // the bytes so the user sees immediate feedback.
          if (_isUploadingPrefillPhoto && _prefillPhotoBytes != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _prefillPhotoBytes!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppConstants.primaryColor,
                            strokeWidth: 2.5,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'admin_uploading_image'.tr(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (_uploadedImageUrl != null || _selectedImagePath != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image:
                    _uploadedImageUrl != null
                        ? DecorationImage(
                          image: CachedNetworkImageProvider(_uploadedImageUrl!),
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
                  onPressed: _isUploadingPrefillPhoto ? null : _pickImage,
                  icon: const Icon(Icons.upload, size: 20),
                  label: Text(
                    _uploadedImageUrl != null || _selectedImagePath != null
                        ? 'admin_change_image'.tr(context)
                        : 'admin_upload_image'.tr(context),
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
                    label: Text('remove'.tr(context)),
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
            'admin_shop_location'.tr(context),
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
                        'admin_coordinates'.tr(context),
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
                label: Text('admin_pick_location_on_map'.tr(context)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Google Maps Link Extraction Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleMapsLinkExtractDialog extends StatefulWidget {
  final void Function(GoogleMapsLinkResult result, Uint8List? photo) onExtracted;
  final VoidCallback onCancel;

  const _GoogleMapsLinkExtractDialog({
    required this.onExtracted,
    required this.onCancel,
  });

  @override
  State<_GoogleMapsLinkExtractDialog> createState() =>
      _GoogleMapsLinkExtractDialogState();
}

class _GoogleMapsLinkExtractDialogState
    extends State<_GoogleMapsLinkExtractDialog> {
  final _linkController = TextEditingController();
  bool _isExtracting = false;
  String? _errorMessage;
  GoogleMapsLinkResult? _result;
  Uint8List? _downloadedPhoto;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;

    if (!GoogleMapsLinkService.isGoogleMapsUrl(url)) {
      setState(() {
        _errorMessage = 'invalid_google_maps_link'.tr(context);
      });
      return;
    }

    // Note: shortened URLs (maps.app.goo.gl, goo.gl) are now resolved
    // server-side by the `resolveShortUrl` Cloud Function, so we no
    // longer block them on web here.

    setState(() {
      _isExtracting = true;
      _errorMessage = null;
    });

    try {
      final result = await GoogleMapsLinkService().parseUrl(url);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isExtracting = false;
          _errorMessage = 'location_extract_failed'.tr(context);
        });
        return;
      }

      // Try downloading photo
      Uint8List? photo;
      if (result.photoUrls != null && result.photoUrls!.isNotEmpty) {
        photo = await _downloadPhoto(result.photoUrls!.first);
      }

      if (!mounted) return;

      setState(() {
        _isExtracting = false;
        _result = result;
        _downloadedPhoto = photo;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExtracting = false;
        _errorMessage = 'location_extract_failed'.tr(context);
      });
    }
  }

  Future<Uint8List?> _downloadPhoto(String url) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.bytes,
      ));
      final response = await dio.get<List<int>>(url);

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        Uint8List? compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 800,
          minWidth: 800,
          quality: 75,
        );
        if (compressed.length > 100 * 1024) {
          compressed = await FlutterImageCompress.compressWithList(
            compressed,
            minHeight: 600,
            minWidth: 600,
            quality: 60,
          );
        }
        return compressed.length <= 100 * 1024 ? compressed : null;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: _result != null ? _buildResultView() : _buildInputView(),
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.link, color: Colors.blue[700], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'paste_google_maps_link'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'google_maps_link_helper'.tr(context),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Link input
        TextField(
          controller: _linkController,
          decoration: InputDecoration(
            hintText: 'google_maps_link_hint'.tr(context),
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.map_outlined, color: Colors.blue[400]),
            suffixIcon: _linkController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _linkController.clear()),
                  )
                : null,
          ),
          maxLines: 3,
          onChanged: (_) => setState(() => _errorMessage = null),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.onCancel,
              child: Text('cancel'.tr(context)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isExtracting || _linkController.text.trim().isEmpty
                  ? null
                  : _extract,
              icon: _isExtracting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_fix_high, size: 18),
              label: Text(
                _isExtracting
                    ? 'extracting_location'.tr(context)
                    : 'auto_fill_from_link'.tr(context),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    final items = <MapEntry<IconData, String>>[];

    items.add(MapEntry(Icons.location_on,
        '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}'));
    if (result.placeName != null) {
      items.add(MapEntry(Icons.store, result.placeName!));
    }
    if (result.phoneNumber != null) {
      items.add(MapEntry(Icons.phone, result.phoneNumber!));
    }
    if (result.fullAddress != null) {
      items.add(MapEntry(Icons.map, result.fullAddress!));
    }
    if (result.district != null) {
      items.add(MapEntry(Icons.location_city, result.district!));
    }
    if (result.province != null) {
      items.add(MapEntry(Icons.flag, result.province!));
    }
    if (result.openingHours != null && result.openingHours!.isNotEmpty) {
      items.add(MapEntry(Icons.access_time,
          'days_count'.tr(context).replaceAll('{count}', '${result.openingHours!.length}')));
    }
    if (result.matchedCategories != null && result.matchedCategories!.isNotEmpty) {
      items.add(MapEntry(Icons.category, result.matchedCategories!.join(', ')));
    }
    if (result.website != null) {
      items.add(MapEntry(Icons.language, result.website!));
    }
    if (_downloadedPhoto != null) {
      items.add(MapEntry(Icons.photo_camera, 'extracted_photo'.tr(context)));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success header
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'location_extracted'.tr(context),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'fields_auto_filled'.tr(context).replaceAll('{count}', '${items.length}'),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // Soft warning if the imported coords fall outside the
        // Thailand bounding box. Doesn't block the import — admin
        // may legitimately add a non-Thai shop — but flags the
        // common mistake of pasting the wrong link.
        if (!GoogleMapsLinkService.isInsideThailandBounds(
            result.latitude, result.longitude)) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB45309).withValues(alpha: 0.45)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'import_outside_thailand_warning'.tr(context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Extracted data list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(item.key, size: 18, color: AppConstants.primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.value,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _result = null;
                  _downloadedPhoto = null;
                  _errorMessage = null;
                });
              },
              child: Text('try_again'.tr(context)),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                widget.onExtracted(_result!, _downloadedPhoto);
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text('continue_to_form'.tr(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
