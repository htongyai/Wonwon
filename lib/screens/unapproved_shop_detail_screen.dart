import 'package:flutter/material.dart';
import 'package:wonwonw2/models/repair_shop.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class UnapprovedShopDetailScreen extends StatelessWidget {
  final RepairShop shop;
  const UnapprovedShopDetailScreen({Key? key, required this.shop})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shop.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(shop.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              'address'.tr(context) + ': ${shop.address}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'categories'.tr(context) + ': ${shop.categories.join(", ")}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            if (shop.soi != null)
              Text(
                'soi'.tr(context) + ': ${shop.soi}',
                style: const TextStyle(fontSize: 15),
              ),
            if (shop.district != null)
              Text(
                'district'.tr(context) + ': ${shop.district}',
                style: const TextStyle(fontSize: 15),
              ),
            if (shop.province != null)
              Text(
                'province'.tr(context) + ': ${shop.province}',
                style: const TextStyle(fontSize: 15),
              ),
            if (shop.lineId != null)
              Text(
                'line_id'.tr(context) + ': ${shop.lineId}',
                style: const TextStyle(fontSize: 15),
              ),
            if (shop.facebookPage != null)
              Text(
                'facebook'.tr(context) + ': ${shop.facebookPage}',
                style: const TextStyle(fontSize: 15),
              ),
            if (shop.instagramPage != null)
              Text(
                'instagram'.tr(context) + ': ${shop.instagramPage}',
                style: const TextStyle(fontSize: 15),
              ),
            if (shop.otherContacts != null)
              Text(
                'other_contacts'.tr(context) + ': ${shop.otherContacts}',
                style: const TextStyle(fontSize: 15),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
              ),
              child: const Text('Approve', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
