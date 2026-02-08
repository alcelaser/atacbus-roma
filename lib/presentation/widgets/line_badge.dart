import 'package:flutter/material.dart';

class LineBadge extends StatelessWidget {
  const LineBadge({
    super.key,
    required this.lineNumber,
    this.color,
    this.textColor,
    this.fontSize = 12,
  });

  final String lineNumber;
  final String? color;
  final String? textColor;
  final double fontSize;

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _parseColor(color, theme.colorScheme.primary);
    final fgColor = _parseColor(textColor, Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        lineNumber,
        style: TextStyle(
          color: fgColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
