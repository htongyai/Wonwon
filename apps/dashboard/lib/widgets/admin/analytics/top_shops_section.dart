import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwon_dashboard/localization/app_localizations_wrapper.dart';

class TopShopsSection extends StatelessWidget {
  final List topShops;
  final void Function(String shopId, Map<String, dynamic> shop)? onShopTap;

  const TopShopsSection({
    Key? key,
    required this.topShops,
    this.onShopTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.trophy,
                color: const Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Top Performing Shops',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topShops.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('no_data_available'.tr(context)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topShops.length > 5 ? 5 : topShops.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final shop = topShops[index].value as Map<String, dynamic>;
                final shopId = topShops[index].key;
                return InkWell(
                  onTap: onShopTap != null ? () => onShopTap!(shopId, shop) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop['name'] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shop['category'] ?? 'Unknown',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.star,
                                  size: 12,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (shop['rating'] as double).toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'n_reviews_count'.tr(context).replaceAll('{count}', '${shop['reviewCount']}'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
