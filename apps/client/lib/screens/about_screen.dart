import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Long-scroll editorial page that explains the WonWon brand. Intentionally
/// quiet — generous margins, serif type, no chrome.
class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoPalette.surfaceLight,
      appBar: AppBar(
        title: Text(
          'about_title'.tr(context),
          style: EditorialTypography.displayMedium.copyWith(fontSize: 18),
        ),
        backgroundColor: EcoPalette.surfaceLight,
        foregroundColor: EcoPalette.inkPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEyebrow(context, 'about_manifesto_eyebrow'),
                const SizedBox(height: 12),
                Text(
                  'about_manifesto_headline'.tr(context),
                  style: EditorialTypography.displayHero,
                ),
                const SizedBox(height: 24),
                _body(context, 'about_manifesto_body_1'),
                const SizedBox(height: 18),
                _body(context, 'about_manifesto_body_2'),
                const SizedBox(height: 18),
                _body(context, 'about_manifesto_body_3'),
                const SizedBox(height: 36),
                _divider(),
                const SizedBox(height: 36),
                _buildEyebrow(context, 'about_why_eyebrow'),
                const SizedBox(height: 14),
                Text(
                  'about_why_headline'.tr(context),
                  style: EditorialTypography.displayLarge,
                ),
                const SizedBox(height: 18),
                _body(context, 'about_why_body'),
                const SizedBox(height: 36),
                _divider(),
                const SizedBox(height: 36),
                _buildEyebrow(context, 'about_credits_eyebrow'),
                const SizedBox(height: 14),
                Text(
                  'about_credits_text'.tr(context),
                  style: EditorialTypography.bodyLarge,
                ),
                const SizedBox(height: 32),
                // Subtle signature mark
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 1,
                        color: EcoPalette.inkMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Repair > Replace',
                        style:
                            EditorialTypography.displayQuote.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bangkok, 2026',
                        style: EditorialTypography.caption,
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

  Widget _buildEyebrow(BuildContext context, String key) {
    return Row(
      children: [
        Container(width: 22, height: 1, color: EcoPalette.leaf),
        const SizedBox(width: 8),
        Text(key.tr(context), style: EditorialTypography.eyebrowLeaf),
      ],
    );
  }

  Widget _body(BuildContext context, String key) {
    return Text(
      key.tr(context),
      style: EditorialTypography.bodyLarge.copyWith(
        color: EcoPalette.inkPrimary,
        height: 1.7,
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        color: EcoPalette.hairline,
      );
}
