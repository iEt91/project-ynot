import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/state/app_controller.dart';
import 'activity_search_field.dart';

class ActivitySearchHeaderButton extends StatelessWidget {
  const ActivitySearchHeaderButton({
    super.key,
    required this.onPressed,
    required this.active,
  });

  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 44,
              height: 40,
              decoration: BoxDecoration(
                color: active
                    ? YnotTheme.primary.withValues(alpha: 0.18)
                    : YnotTheme.surface2.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? YnotTheme.primary : YnotTheme.border,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ),
        if (active)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: YnotTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

Future<void> showActivitySearchSheet(
  BuildContext context, {
  VoidCallback? onChanged,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Buscar actividad',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(appStateProvider);
              final controller = ref.read(appControllerProvider);

              return Stack(
                children: [
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 82,
                    child: FractionallySizedBox(
                      widthFactor: 0.92,
                      alignment: Alignment.topCenter,
                      child: ActivitySearchField(
                        value: state.activitySearchQuery,
                        autofocus: true,
                        onChanged: (value) {
                          controller.setActivitySearchQuery(value);
                          onChanged?.call();
                        },
                        onDismiss: () => Navigator.of(dialogContext).pop(),
                        onClear: () {
                          onChanged?.call();
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
