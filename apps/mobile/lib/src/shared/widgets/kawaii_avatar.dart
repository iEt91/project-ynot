import 'package:flutter/material.dart';

class KawaiiAvatar extends StatelessWidget {
  const KawaiiAvatar({
    super.key,
    required this.emoji,
    this.size = 56,
    this.label,
    this.accentColor,
  });

  final String emoji;
  final double size;
  final String? label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.5),
            color.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
          ],
          stops: const [0.0, 0.65, 1.0],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label ?? emoji,
          style: TextStyle(fontSize: size * 0.46),
        ),
      ),
    );
  }
}
