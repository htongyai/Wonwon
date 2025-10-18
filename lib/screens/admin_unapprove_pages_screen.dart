import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/services/shop_service.dart';
import 'package:wonwonw2/screens/shop_detail_screen.dart';
import 'package:intl/intl.dart';

class AdminUnapprovePagesScreen extends StatefulWidget {
  const AdminUnapprovePagesScreen({Key? key}) : super(key: key);

  @override
  _AdminUnapprovePagesScreenState createState() =>
      _AdminUnapprovePagesScreenState();
}

class _AdminUnapprovePagesScreenState extends State<AdminUnapprovePagesScreen> {
  final ShopService _shopService = ShopService();

  List<RepairShop> _unapprovedShops = [];
  List<RepairShop> _filteredShops = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadUnapprovedShops();
  }

  Future<void> _loadUnapprovedShops() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // TODO: Implement getUnapprovedShops method in ShopService
      final shops = await _shopService.getAllShops();
      // Filter for unapproved shops
      final unapprovedShops = shops.where((shop) => !shop.approved).toList();

      setState(() {
        _unapprovedShops = unapprovedShops;
        _filteredShops = unapprovedShops;
        _isLoading = false;
      });
      _applySorting();
    } catch (e) {
      print('Error loading unapproved shops: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _applySearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredShops = _unapprovedShops;
      } else {
        _filteredShops =
            _unapprovedShops.where((shop) {
              final nameMatch = shop.name.toLowerCase().contains(
                query.toLowerCase(),
              );
              final addressMatch = shop.address.toLowerCase().contains(
                query.toLowerCase(),
              );
              final categoryMatch = shop.categories.any(
                (category) =>
                    category.toLowerCase().contains(query.toLowerCase()),
              );
              return nameMatch || addressMatch || categoryMatch;
            }).toList();
      }
    });
    _applySorting();
  }

  void _applySorting() {
    _filteredShops.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'address':
          comparison = a.address.compareTo(b.address);
          break;
        case 'submittedDate':
          comparison = (a.timestamp ?? DateTime.now()).compareTo(
            b.timestamp ?? DateTime.now(),
          );
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _sortByColumn(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = true;
      }
    });
    _applySorting();
  }

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
                  FontAwesomeIcons.clock,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  'Unapproved Pages',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkColor,
                  ),
                ),
                const Spacer(),
                // Refresh button
                IconButton(
                  onPressed: _loadUnapprovedShops,
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
                    onChanged: _applySearch,
                    decoration: InputDecoration(
                      hintText: 'Search unapproved shops...',
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
                Text(
                  '${_filteredShops.length} pending',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Table
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hasError
                    ? _buildErrorState()
                    : _filteredShops.isEmpty
                    ? _buildEmptyState()
                    : _buildUnapprovedShopsTable(),
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
            'Error loading unapproved shops',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUnapprovedShops,
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
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          Text(
            'No unapproved shops',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All shops have been approved',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnapprovedShopsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          _buildSortableColumn('Shop Name', 'name'),
          _buildSortableColumn('Address', 'address'),
          _buildSortableColumn('Submitted', 'submittedDate'),
          const DataColumn(label: Text('Categories')),
          const DataColumn(label: Text('Services')),
          const DataColumn(label: Text('Actions')),
        ],
        rows:
            _filteredShops
                .map((shop) => _buildUnapprovedShopRow(shop))
                .toList(),
      ),
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
      onSort: (columnIndex, ascending) => _sortByColumn(sortKey),
    );
  }

  DataRow _buildUnapprovedShopRow(RepairShop shop) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            shop.name,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
        ),
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
          Text(
            DateFormat('MMM dd, yyyy').format(shop.timestamp ?? DateTime.now()),
            style: GoogleFonts.montserrat(fontSize: 12),
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
                onPressed: () => _approveShop(shop),
                icon: const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                tooltip: 'Approve Shop',
              ),
              IconButton(
                onPressed: () => _rejectShop(shop),
                icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                tooltip: 'Reject Shop',
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

  void _approveShop(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve Shop'),
            content: Text('Are you sure you want to approve "${shop.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement approve shop functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Approved shop: ${shop.name}')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
  }

  void _rejectShop(RepairShop shop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Shop'),
            content: Text('Are you sure you want to reject "${shop.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implement reject shop functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rejected shop: ${shop.name}')),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reject'),
              ),
            ],
          ),
    );
  }
}
