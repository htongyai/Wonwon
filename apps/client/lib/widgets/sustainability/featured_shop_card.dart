import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:shared/models/repair_shop.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Full-bleed editorial card showcasing one hand-picked shop per week.
/// Sits above the shop list on the home screen.
class FeaturedShopCard extends StatelessWidget {
  final RepairShop shop;
  final VoidCallback onTap;

  const FeaturedShopCard({
    Key? key,
    required this.shop,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: EcoPalette.surfaceLight,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImage(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 1,
                            color: EcoPalette.leaf,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'featured_eyebrow'.tr(context),
                            style: EditorialTypography.eyebrowLeaf,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        shop.name,
                        style: EditorialTypography.displayLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (shop.ownerStory != null &&
                          shop.ownerStory!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '"${shop.ownerStory}"',
                          style: EditorialTypography.displayQuote.copyWith(
                            fontSize: 15,
                            color: EcoPalette.inkSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (shop.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          shop.description,
                          style: EditorialTypography.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            _meta(),
                            style: EditorialTypography.caption.copyWith(
                              color: EcoPalette.inkSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'featured_read_more'.tr(context),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: EcoPalette.leaf,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: EcoPalette.leaf),
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

  String _meta() {
    final parts = <String>[];
    if (shop.categories.isNotEmpty) {
      parts.add(shop.categories.first);
    }
    if (shop.district?.isNotEmpty ?? false) parts.add(shop.district!);
    return parts.join(' · ');
  }

  Widget _buildImage() {
    if (shop.photos.isEmpty) {
      return Container(
        height: 180,
        color: EcoPalette.surfaceDeep,
        child: const Center(
          child: Icon(Icons.store_rounded,
              size: 60, color: EcoPalette.inkMuted),
        ),
      );
    }
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: CachedNetworkImage(
        imageUrl: shop.photos.first,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: EcoPalette.surfaceDeep),
        errorWidget: (_, __, ___) => Container(
          color: EcoPalette.surfaceDeep,
          child: const Icon(Icons.store_rounded,
              size: 60, color: EcoPalette.inkMuted),
        ),
      ),
    );
  }
}
