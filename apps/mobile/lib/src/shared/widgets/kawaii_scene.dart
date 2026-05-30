import 'package:flutter/material.dart';

import '../../app/theme.dart';

class KawaiiScene extends StatelessWidget {
  const KawaiiScene({
    super.key,
    required this.child,
    this.bottomPadding = 0,
  });

  final Widget child;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [YnotTheme.bg, YnotTheme.bg2, Color(0xFF090E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: _Glow(color: YnotTheme.primary.withValues(alpha: 0.10), size: 220),
          ),
          Positioned(
            top: 180,
            right: -60,
            child: _Glow(color: YnotTheme.purple.withValues(alpha: 0.10), size: 180),
          ),
          Positioned(
            bottom: 60 + bottomPadding,
            left: -40,
            child: _Glow(color: YnotTheme.mint.withValues(alpha: 0.05), size: 200),
          ),
          Positioned(
            top: 70,
            right: 44,
            child: _Star(size: 8, color: Colors.white.withValues(alpha: 0.18)),
          ),
          Positioned(
            top: 240,
            left: 28,
            child: _Star(size: 5, color: YnotTheme.primary.withValues(alpha: 0.22)),
          ),
          Positioned(
            bottom: 180 + bottomPadding,
            right: 32,
            child: _Star(size: 7, color: YnotTheme.purple.withValues(alpha: 0.18)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
