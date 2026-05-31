import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'kawaii_card.dart';

class KawaiiEmptyState extends StatelessWidget {
  const KawaiiEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.emoji = '🌙',
    this.ctaLabel,
    this.onCtaPressed,
  });

  final String title;
  final String message;
  final String emoji;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: YnotTheme.surface2.withValues(alpha: 0.96),
              border: Border.all(color: YnotTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          if (ctaLabel != null && onCtaPressed != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onCtaPressed,
              child: Text(ctaLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
