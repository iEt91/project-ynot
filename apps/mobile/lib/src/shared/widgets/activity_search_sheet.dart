import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/models/activity.dart';
import '../../core/state/app_controller.dart';
import 'activity_search_field.dart';
import 'kawaii_avatar.dart';
import 'kawaii_card.dart';

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
  ValueChanged<Activity>? onActivitySelected,
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
              final query = state.activitySearchQuery.trim();
              final results = controller.filteredActivities();
              final hasResults = results.isNotEmpty;
              final maxHeight = MediaQuery.of(context).size.height * 0.52;

              return Stack(
                children: [
                  Positioned(
                    left: 18,
                    right: 18,
                    top: 82,
                    child: FractionallySizedBox(
                      widthFactor: 0.92,
                      alignment: Alignment.topCenter,
                      child: KawaiiCard(
                        padding: const EdgeInsets.all(14),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: maxHeight),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ActivitySearchField(
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
                              if (query.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                if (hasResults)
                                  Flexible(
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: results.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: YnotTheme.border.withValues(alpha: 0.8),
                                      ),
                                      itemBuilder: (context, index) {
                                        final activity = results[index];
                                        return _SearchResultTile(
                                          activity: activity,
                                          onTap: () {
                                            Navigator.of(dialogContext).pop();
                                            onActivitySelected?.call(activity);
                                          },
                                        );
                                      },
                                    ),
                                  )
                                else
                                  const _SearchEmptyState(),
                              ],
                            ],
                          ),
                        ),
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.activity,
    required this.onTap,
  });

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            KawaiiAvatar(
              emoji: activity.emoji,
              size: 42,
              accentColor: _categoryColor(activity.category),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activity.zone} · ${_formatHour(activity.startTime)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  String _formatHour(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _categoryColor(String category) {
    return switch (category) {
      'Coffee' => YnotTheme.primary,
      'Study' => YnotTheme.purple,
      'Walks' => YnotTheme.mint,
      'Food' => const Color(0xFFFFB86B),
      'Art' => const Color(0xFFB18CFF),
      'Music' => const Color(0xFF63D2FF),
      _ => YnotTheme.primary,
    };
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: YnotTheme.surface2.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              border: Border.all(color: YnotTheme.border),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: Colors.white70,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No encontramos resultados',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prueba otra palabra o limpia la búsqueda.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
