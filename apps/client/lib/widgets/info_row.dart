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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final linkColor = isDark ? Colors.lightBlueAccent : Colors.blue;
    return InkWell(
      onTap: onTap,
      mouseCursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor ?? theme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: (textStyle ?? TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)).copyWith(
                  color: onTap != null ? linkColor : null,
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
