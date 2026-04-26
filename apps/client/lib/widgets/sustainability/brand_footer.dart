import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';

/// Quiet brand mark pinned to the foot of long scrolls. A small grace note,
/// not a call to action.
class BrandFooter extends StatelessWidget {
  const BrandFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 24,
              height: 1,
              color: EcoPalette.hairline,
            ),
            const SizedBox(height: 10),
            Text(
              'Repair > Replace',
              style: EditorialTypography.displayQuote.copyWith(
                fontSize: 14,
                color: EcoPalette.inkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Bangkok, 2026',
              style: EditorialTypography.caption.copyWith(
                fontSize: 10,
                color: EcoPalette.inkMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
