import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final Color? color;

  const SectionTitle({
    Key? key,
    required this.text,
    this.padding = const EdgeInsets.only(left: 8, bottom: 4),
    this.fontSize = 20,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
