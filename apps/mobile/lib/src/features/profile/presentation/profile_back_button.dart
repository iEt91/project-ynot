import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class ProfileBackButton extends StatelessWidget {
  const ProfileBackButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: YnotTheme.surface2.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(color: YnotTheme.border),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
