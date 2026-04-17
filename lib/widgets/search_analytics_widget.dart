import 'package:flutter/material.dart';
import 'package:wonwonw2/services/advanced_search_service.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class SearchAnalyticsWidget extends StatelessWidget {
  final AdvancedSearchService searchService;

  const SearchAnalyticsWidget({Key? key, required this.searchService})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'search_analytics'.tr(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAnalyticsContent(context),
        ],
      ),
    );
    } catch (e) {
      debugPrint('SearchAnalyticsWidget build error: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildAnalyticsContent(BuildContext context) {
    final analytics = searchService.getSearchAnalytics();
    final totalSearches = (analytics['totalSearches'] as int?) ?? 0;
    final uniqueSearches = (analytics['uniqueSearches'] as int?) ?? 0;
    final topSearches = (analytics['topSearches'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'total_searches'.tr(context),
                totalSearches.toString(),
                Icons.search,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'unique_terms'.tr(context),
                uniqueSearches.toString(),
                Icons.tag,
              ),
            ),
          ],
        ),

        if (topSearches.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'popular_searches'.tr(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...topSearches
              .take(5)
              .map(
                (search) => _buildTopSearchItem(
                  search['term'] as String,
                  search['count'] as int,
                ),
              ),
        ],

        if (totalSearches == 0)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'no_search_data'.tr(context),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppConstants.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchItem(String term, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              term,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


