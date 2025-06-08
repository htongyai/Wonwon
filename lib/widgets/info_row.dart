import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textStyle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor ?? Colors.brown),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: (textStyle ?? const TextStyle(fontSize: 15)).copyWith(
                  color: onTap != null ? Colors.blue : null,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
