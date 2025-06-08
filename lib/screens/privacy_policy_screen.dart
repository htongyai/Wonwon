import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('privacy_policy'.tr(context))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'privacy_policy_placeholder'.tr(context),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
