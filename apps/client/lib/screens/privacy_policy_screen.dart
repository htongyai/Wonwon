import 'package:flutter/material.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('privacy_policy'.tr(context)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'privacy_policy'.tr(context),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Last updated: ${DateTime.now().year}',
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'privacy_collect_title'.tr(context),
                'privacy_collect_content'.tr(context),
              ),
              _buildSection(
                'privacy_use_title'.tr(context),
                'privacy_use_content'.tr(context),
              ),
              _buildSection(
                'privacy_sharing_title'.tr(context),
                'privacy_sharing_content'.tr(context),
              ),
              _buildSection(
                'privacy_security_title'.tr(context),
                'privacy_security_content'.tr(context),
              ),
              _buildSection(
                'privacy_contact_title'.tr(context),
                'privacy_contact_content'.tr(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 24),
      ],
    );
  }
}
