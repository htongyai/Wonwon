import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('terms_of_use'.tr(context))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'terms_placeholder'.tr(context),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
