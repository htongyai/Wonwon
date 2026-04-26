import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton screen that matches the shop detail screen layout so users
/// see a familiar shape while data loads (instead of a blank white screen).
class ShopDetailSkeleton extends StatelessWidget {
  const ShopDetailSkeleton({Key? key}) : super(key: key);

  static const Color _lightBase = Color(0xFFE4E4E7);
  static const Color _lightHighlight = Color(0xFFF4F4F5);
  static const Color _darkBase = Color(0xFF2A2A2A);
  static const Color _darkHighlight = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = isDark ? _darkBase : _lightBase;
    final highlight = isDark ? _darkHighlight : _lightHighlight;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero photo
                      Container(
                        height: 250,
                        width: double.infinity,
                        color: base,
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _block(22, 240),
                            const SizedBox(height: 10),
                            _block(14, 120),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: _block(44, double.infinity)),
                                const SizedBox(width: 10),
                                Expanded(child: _block(44, double.infinity)),
                                const SizedBox(width: 10),
                                _block(44, 48),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _block(16, 100),
                            const SizedBox(height: 12),
                            _block(120, double.infinity),
                            const SizedBox(height: 24),
                            _block(16, 80),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _block(32, 80),
                                _block(32, 110),
                                _block(32, 90),
                                _block(32, 100),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _block(16, 120),
                            const SizedBox(height: 10),
                            _block(14, double.infinity),
                            const SizedBox(height: 6),
                            _block(14, double.infinity),
                            const SizedBox(height: 6),
                            _block(14, 260),
                            const SizedBox(height: 24),
                            _block(16, 100),
                            const SizedBox(height: 12),
                            _block(100, double.infinity),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
              // Bottom bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: theme.cardColor),
                child: Row(
                  children: [
                    Expanded(child: _block(44, double.infinity)),
                    const SizedBox(width: 8),
                    _block(44, 48),
                    const SizedBox(width: 8),
                    _block(44, 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(double height, double width) {
    // Shimmer.fromColors overrides this fill with its animated gradient,
    // so the literal color here is never visible to users.
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: _lightBase,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
