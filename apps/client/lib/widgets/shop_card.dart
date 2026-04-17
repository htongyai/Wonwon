import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:shared/constants/app_constants.dart';
import '../localization/app_localizations_wrapper.dart';

/// Modern shop card inspired by travel/location card designs.
/// Two modes: grid (carousel/vertical) and compact (horizontal list).
class ShopCard extends StatelessWidget {
  final RepairShop shop;
  final VoidCallback? onTap;
  final bool compact; // compact = horizontal list item, false = grid card
  final double? distanceKm;

  const ShopCard({
    Key? key,
    required this.shop,
    this.onTap,
    this.compact = false,
    this.distanceKm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactCard(context);
    return _buildGridCard(context);
  }

  // ── Grid Card ─────────────────────────────────────────────────────────────
  // Large image-dominant card for carousels and grids.
  // Image with gradient overlay, rating badge, category chips on image.

  Widget _buildGridCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppConstants.primaryColor.withValues(alpha: 0.08),
          highlightColor: AppConstants.primaryColor.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Image section with overlays
              Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  children: [
                    // Main image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 155,
                        width: double.infinity,
                        child: _buildImage(),
                      ),
                    ),

                    // Gradient overlay at bottom for category chip readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16)),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Rating badge — frosted glass, top-right
                    if (shop.rating > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.93),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFB800), size: 14),
                              const SizedBox(width: 3),
                              Text(
                                shop.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Category chips — bottom-left, over gradient
                    if (shop.categories.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 50,
                        child: Row(
                          children: shop.categories
                              .take(2)
                              .map((String cat) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'category_$cat'.tr(context),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D2D2D),
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Info section below image
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            _locationText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF757575),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (distanceKm != null) ...[
                          const SizedBox(width: 6),
                          _buildDistanceBadge(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Compact Card ──────────────────────────────────────────────────────────
  // Horizontal list card with thumbnail, info, category chips, distance.

  Widget _buildCompactCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppConstants.primaryColor.withValues(alpha: 0.08),
          highlightColor: AppConstants.primaryColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // ── Thumbnail with rating overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 94,
                        height: 94,
                        child: _buildImage(),
                      ),
                    ),
                    // Mini rating badge
                    if (shop.rating > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.93),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFFFFB800), size: 11),
                              const SizedBox(width: 2),
                              Text(
                                shop.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // ── Info section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Shop name
                      Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              _locationText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Category chips + distance
                      Row(
                        children: [
                          // Category chips
                          ...shop.categories
                              .take(2)
                              .map((String cat) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'category_$cat'.tr(context),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF616161),
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ),
                                  )),

                          const Spacer(),

                          // Distance badge
                          if (distanceKm != null) _buildDistanceBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  String get _locationText {
    if (shop.district?.isNotEmpty ?? false) {
      return '${shop.district}, ${shop.province ?? ''}';
    }
    return shop.area.isNotEmpty ? shop.area : shop.address;
  }

  Widget _buildImage() {
    if (shop.photos.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: shop.photos.first,
        fit: BoxFit.cover,
        memCacheWidth: compact ? 200 : 500,
        memCacheHeight: compact ? 200 : null,
        placeholder: (BuildContext context, String url) => _buildPlaceholder(),
        errorWidget: (BuildContext context, String url, Object error) =>
            _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0F0F0),
      ),
      child: const Center(
        child: Icon(Icons.store_rounded, color: Color(0xFFBDBDBD), size: 30),
      ),
    );
  }

  Widget _buildDistanceBadge() {
    if (distanceKm == null) return const SizedBox.shrink();

    final String distanceText;
    if (distanceKm! < 1) {
      distanceText = '${(distanceKm! * 1000).round()} m';
    } else if (distanceKm! < 10) {
      distanceText = '${distanceKm!.toStringAsFixed(1)} km';
    } else {
      distanceText = '${distanceKm!.round()} km';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_rounded,
              size: 10, color: Color(0xFF6366F1)),
          const SizedBox(width: 3),
          Text(
            distanceText,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }
}
