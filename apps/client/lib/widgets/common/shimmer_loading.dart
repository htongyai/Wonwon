import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Returns the shimmer base/highlight colors appropriate to the current theme.
/// Light mode uses the original greys; dark mode uses darker surfaces so the
/// shimmer doesn't glow bright white on a dark background.
({Color base, Color highlight}) _shimmerColors(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return (base: const Color(0xFF2A2A2A), highlight: const Color(0xFF3A3A3A));
  }
  return (base: const Color(0xFFE0E0E0), highlight: const Color(0xFFF5F5F5));
}

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _shimmerColors(context);
    return Shimmer.fromColors(
      baseColor: colors.base,
      highlightColor: colors.highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerProfileCard extends StatelessWidget {
  final double avatarRadius;
  final bool showStats;

  const ShimmerProfileCard({
    Key? key,
    this.avatarRadius = 40,
    this.showStats = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _shimmerColors(context);
    return Shimmer.fromColors(
      baseColor: colors.base,
      highlightColor: colors.highlight,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Avatar
            Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                color: colors.base,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Name placeholder
            Container(
              width: 160,
              height: 20,
              decoration: BoxDecoration(
                color: colors.base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Email placeholder
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: colors.base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (showStats) ...[
              const SizedBox(height: 24),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 20,
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Action button placeholder
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: colors.base,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerShopCard extends StatelessWidget {
  const ShimmerShopCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _shimmerColors(context);
    return Shimmer.fromColors(
      baseColor: colors.base,
      highlightColor: colors.highlight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colors.base,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating row
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colors.base,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 60,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colors.base,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Address row
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: colors.base,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Category chips
                  Row(
                    children: List.generate(
                      2,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 64,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.base,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  final bool hasLeadingCircle;
  final bool hasTrailing;

  const ShimmerListTile({
    Key? key,
    this.hasLeadingCircle = true,
    this.hasTrailing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _shimmerColors(context);
    return Shimmer.fromColors(
      baseColor: colors.base,
      highlightColor: colors.highlight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (hasLeadingCircle)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.base,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            if (hasLeadingCircle) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            if (hasTrailing) ...[
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ShimmerRepairRecordList extends StatelessWidget {
  final int itemCount;

  const ShimmerRepairRecordList({Key? key, this.itemCount = 4})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerListTile(hasTrailing: true),
    );
  }
}
