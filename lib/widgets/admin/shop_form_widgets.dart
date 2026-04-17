import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wonwonw2/constants/app_constants.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';

class ShopFormWidgets {
  ShopFormWidgets._();

  static Widget buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  static Widget buildPriceRangeSection({
    required BuildContext context,
    required double value,
    required ValueChanged<double> onChanged,
    required String Function(double) formatPriceRange,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'price_range'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '฿',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: Slider(
                  value: value,
                  min: 1.0,
                  max: 5.0,
                  divisions: 4,
                  activeColor: AppConstants.primaryColor,
                  onChanged: onChanged,
                ),
              ),
              Text(
                '฿฿฿฿฿',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.primaryColor),
              ),
              child: Text(
                formatPriceRange(value),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildPaymentMethodsSection({
    required BuildContext context,
    required List<String> availablePaymentMethods,
    required List<String> selectedPaymentMethods,
    required void Function(String method, bool selected) onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin_payment_methods'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availablePaymentMethods.map((method) {
                  final isSelected = selectedPaymentMethods.contains(method);
                  IconData icon;
                  String label;

                  switch (method) {
                    case 'cash':
                      icon = Icons.money;
                      label = 'admin_payment_cash'.tr(context);
                      break;
                    case 'card':
                      icon = Icons.credit_card;
                      label = 'admin_payment_card'.tr(context);
                      break;
                    case 'qr':
                      icon = Icons.qr_code;
                      label = 'admin_payment_qr_code'.tr(context);
                      break;
                    case 'bank_transfer':
                      icon = Icons.account_balance;
                      label = 'admin_payment_bank_transfer'.tr(context);
                      break;
                    case 'true_money':
                      icon = Icons.account_balance_wallet;
                      label = 'admin_payment_truemoney'.tr(context);
                      break;
                    case 'line_pay':
                      icon = Icons.chat;
                      label = 'admin_payment_line_pay'.tr(context);
                      break;
                    default:
                      icon = Icons.payment;
                      label = method;
                  }

                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) => onToggle(method, selected),
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  static Widget buildAmenitiesSection({
    required BuildContext context,
    required List<String> availableAmenities,
    required List<String> selectedAmenities,
    required Map<String, String> amenityToKey,
    required void Function(String amenity, bool selected) onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin_amenities'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableAmenities.map((amenity) {
                  final isSelected = selectedAmenities.contains(amenity);
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) => onToggle(amenity, selected),
                    label: Text(amenityToKey[amenity]!.tr(context)),
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  static Widget buildFeaturesSection({
    required BuildContext context,
    required List<String> availableFeatures,
    required Map<String, bool> selectedFeatures,
    required Map<String, String> featureToKey,
    required void Function(String feature, bool selected) onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin_features'.tr(context),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableFeatures.map((feature) {
                  final isSelected = selectedFeatures[feature] ?? false;
                  return FilterChip(
                    selected: isSelected,
                    onSelected: (selected) => onToggle(feature, selected),
                    label: Text(featureToKey[feature]!.tr(context)),
                    selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  static Widget buildQuickActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.grey.shade700,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
    );
  }

  static Widget buildPresetButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
        foregroundColor: AppConstants.primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12)),
    );
  }
}
