import 'package:flutter/material.dart';
import 'package:wonwonw2/localization/app_localizations_wrapper.dart';
import 'package:wonwonw2/widgets/common_form_field.dart';

/// Optimized form widget that reduces boilerplate and improves reusability
class OptimizedFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<FormFieldConfig> fields;
  final String submitButtonText;
  final VoidCallback onSubmit;
  final bool isLoading;
  final Color? primaryColor;
  final Widget? header;
  final Widget? footer;
  final EdgeInsets? padding;
  final double? maxWidth;

  const OptimizedFormWidget({
    Key? key,
    required this.formKey,
    required this.fields,
    required this.submitButtonText,
    required this.onSubmit,
    this.isLoading = false,
    this.primaryColor,
    this.header,
    this.footer,
    this.padding,
    this.maxWidth = 400,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = primaryColor ?? theme.primaryColor;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 400),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header != null) ...[header!, const SizedBox(height: 32)],

                  // Build form fields
                  ...fields.map(
                    (field) => _buildFormField(context, field, color),
                  ),

                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: isLoading ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              submitButtonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),

                  if (footer != null) ...[const SizedBox(height: 24), footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context,
    FormFieldConfig field,
    Color color,
  ) {
    return Column(
      children: [
        if (field.type == FormFieldType.radio)
          _buildRadioField(context, field, color)
        else if (field.type == FormFieldType.dropdown)
          _buildDropdownField(context, field, color)
        else
          _buildTextFormField(context, field, color),
        SizedBox(height: field.spacing ?? 20),
      ],
    );
  }

  Widget _buildTextFormField(
    BuildContext context,
    FormFieldConfig field,
    Color color,
  ) {
    return CommonFormField(
      controller: field.controller!,
      labelText: field.labelText?.tr(context) ?? field.label,
      prefixIcon: field.prefixIcon,
      suffixIcon: field.suffixIcon,
      onSuffixPressed: field.onSuffixPressed,
      obscureText: field.obscureText ?? false,
      keyboardType: field.keyboardType ?? TextInputType.text,
      focusedBorderColor: color,
      validator: field.validator,
      enabled: field.enabled ?? true,
      maxLines: field.maxLines,
      hintText: field.hintText?.tr(context),
    );
  }

  Widget _buildRadioField(
    BuildContext context,
    FormFieldConfig field,
    Color color,
  ) {
    if (field.radioOptions == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.label.isNotEmpty)
          Text(
            field.labelText?.tr(context) ?? field.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children:
                field.radioOptions!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;

                  return Column(
                    children: [
                      RadioListTile<String>(
                        title: Row(
                          children: [
                            if (option.icon != null) ...[
                              Icon(option.icon, color: color),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.title.tr(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (option.subtitle != null)
                                    Text(
                                      option.subtitle!.tr(context),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        value: option.value,
                        groupValue: field.radioValue,
                        onChanged: field.onRadioChanged,
                        activeColor: color,
                      ),
                      if (index < field.radioOptions!.length - 1)
                        Divider(height: 1, color: Colors.grey.shade300),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    FormFieldConfig field,
    Color color,
  ) {
    if (field.dropdownItems == null) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      value: field.dropdownValue,
      decoration: InputDecoration(
        labelText: field.labelText?.tr(context) ?? field.label,
        prefixIcon: field.prefixIcon != null ? Icon(field.prefixIcon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      items:
          field.dropdownItems!.map((item) {
            return DropdownMenuItem<String>(
              value: item.value,
              child: Text(item.label.tr(context)),
            );
          }).toList(),
      onChanged: field.onDropdownChanged,
      validator: field.validator,
    );
  }
}

/// Configuration class for form fields
class FormFieldConfig {
  final String label;
  final String? labelText; // For localization key
  final FormFieldType type;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final bool? obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool? enabled;
  final int? maxLines;
  final String? hintText;
  final double? spacing;

  // Radio field properties
  final List<RadioOption>? radioOptions;
  final String? radioValue;
  final void Function(String?)? onRadioChanged;

  // Dropdown field properties
  final List<DropdownItem>? dropdownItems;
  final String? dropdownValue;
  final void Function(String?)? onDropdownChanged;

  const FormFieldConfig({
    required this.label,
    this.labelText,
    this.type = FormFieldType.text,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.obscureText,
    this.keyboardType,
    this.validator,
    this.enabled,
    this.maxLines,
    this.hintText,
    this.spacing,
    this.radioOptions,
    this.radioValue,
    this.onRadioChanged,
    this.dropdownItems,
    this.dropdownValue,
    this.onDropdownChanged,
  });
}

enum FormFieldType { text, radio, dropdown }

class RadioOption {
  final String title;
  final String? subtitle;
  final String value;
  final IconData? icon;

  const RadioOption({
    required this.title,
    this.subtitle,
    required this.value,
    this.icon,
  });
}

class DropdownItem {
  final String label;
  final String value;

  const DropdownItem({required this.label, required this.value});
}
