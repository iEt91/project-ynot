import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/moderation_flag.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../profile/presentation/profile_back_button.dart';

class InternalModerationScreen extends ConsumerWidget {
  const InternalModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final pendingFlags = controller.pendingModerationFlags();

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(
                children: [
                  ProfileBackButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Moderación interna',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Flags locales pendientes para revisión.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (pendingFlags.isEmpty)
                const KawaiiEmptyState(
                  emoji: '🪶',
                  title: 'Sin flags pendientes',
                  message: 'Todo está tranquilo por ahora.',
                )
              else
                ...pendingFlags.map(
                  (flag) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ModerationFlagCard(
                      flag: flag,
                      activityTitle: _activityTitleForFlag(
                        flag,
                        state.activities,
                      ),
                      onTap: () => context.push(
                        '/settings/moderation/flag/${flag.flagId}',
                      ),
                      onReviewed: () async {
                        await controller.markModerationFlagReviewed(
                          flag.flagId,
                        );
                      },
                      onDismissed: () async {
                        await controller.dismissModerationFlag(flag.flagId);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _activityTitleForFlag(
    ModerationFlag flag,
    List<Activity> activities,
  ) {
    for (final activity in activities) {
      if (activity.id == flag.activityId) {
        return safeDisplayText(activity.title, fallback: 'Actividad');
      }
    }
    return null;
  }
}

class _ModerationFlagCard extends StatelessWidget {
  const _ModerationFlagCard({
    required this.flag,
    required this.onReviewed,
    required this.onDismissed,
    required this.activityTitle,
    required this.onTap,
  });

  final ModerationFlag flag;
  final String? activityTitle;
  final VoidCallback onTap;
  final Future<void> Function() onReviewed;
  final Future<void> Function() onDismissed;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = switch (flag.category) {
      'drugs' => 'Drogas',
      'sex' => 'Sexo',
      'self_harm' => 'Autolesión',
      'violence' => 'Violencia',
      'vandalism' => 'Vandalismo',
      'spam' => 'Spam',
      _ => flag.category,
    };
    final sourceLabel = switch (flag.sourceType) {
      ModerationFlagSourceType.activity => 'Actividad',
      ModerationFlagSourceType.message => 'Mensaje',
    };

    return InkWell(
      borderRadius: BorderRadius.circular(32),
      onTap: onTap,
      child: KawaiiCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: YnotTheme.surface2.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: YnotTheme.border),
                  ),
                  child: const Icon(Icons.flag_rounded, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniChip(label: sourceLabel),
                          _MiniChip(label: flag.keyword),
                          _MiniChip(label: flag.statusLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activityTitle != null) ...[
              Text(
                'Actividad: $activityTitle',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              safeDisplayText(flag.textSnippet, fallback: 'Texto no disponible'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${formatDateLabel(flag.createdAt)} · ${formatTimeOfDay(flag.createdAt)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: flag.isPending
                        ? () {
                            unawaited(onReviewed());
                          }
                        : null,
                    child: const Text('Marcar revisada'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: flag.isPending
                        ? () {
                            unawaited(onDismissed());
                          }
                        : null,
                    child: const Text('Descartar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: YnotTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YnotTheme.border),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
