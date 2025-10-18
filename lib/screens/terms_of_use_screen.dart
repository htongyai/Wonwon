import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('terms_of_use'.tr(context)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'terms_of_use'.tr(context),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Last updated: ${DateTime.now().year}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildSection(
                'terms_acceptance_title'.tr(context),
                'terms_acceptance_content'.tr(context),
              ),
              _buildSection(
                'terms_license_title'.tr(context),
                'terms_license_content'.tr(context),
              ),
              _buildSection(
                'terms_account_title'.tr(context),
                'terms_account_content'.tr(context),
              ),
              _buildSection(
                'Prohibited Uses',
                'You may not use our service for any illegal or unauthorized purpose nor may you, in the use of the service, violate any laws.',
              ),
              _buildSection(
                'Limitation of Liability',
                'In no event shall the app or its suppliers be liable for any damages arising out of the use or inability to use this application.',
              ),
              _buildSection(
                'Contact Information',
                'If you have any questions about these Terms of Use, please contact us through the app.',
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
