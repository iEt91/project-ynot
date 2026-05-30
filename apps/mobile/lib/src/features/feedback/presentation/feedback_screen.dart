import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/private_feedback.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/status_pill.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final Map<String, PrivateFeedbackOption> _selectedByTargetId = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activity = _findActivity(state.activities, widget.activityId);
    final currentUser = state.user;

    if (activity == null || currentUser == null) {
      return Scaffold(
        body: KawaiiScene(
          child: SafeArea(
            child: Center(
              child: KawaiiCard(
                child: const Text('No encontramos esta actividad.'),
              ),
            ),
          ),
        ),
      );
    }

    final targets = _feedbackTargetsFor(activity, currentUser.id);
    final hasSelectableTargets = targets.isNotEmpty;
    final hasPendingSelection = targets.any((target) {
      return _existingEntry(
                state.feedbackEntries,
                activityId: activity.id,
                reviewerUserId: currentUser.id,
                reviewedUserId: target.userId,
              ) ==
              null &&
          _selectedByTargetId[target.userId] != null;
    });

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Row(
                children: [
                  _RoundBubble(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Feedback',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KawaiiCard(
                padding: const EdgeInsets.all(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    YnotTheme.surface.withValues(alpha: 0.88),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KawaiiAvatar(
                          emoji: activity.emoji,
                          size: 58,
                          accentColor: YnotTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatTimeOfDay(activity.startTime)} · ${activity.zone}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¿Qué te pareció esta persona?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Esto ayuda a mejorar recomendaciones. Tu respuesta no será pública.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const StatusPill(
                      label: 'Tu respuesta no será pública',
                      icon: '🔒',
                      color: Colors.pinkAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!hasSelectableTargets)
                KawaiiCard(
                  child: Text(
                    'Todavía no hay otras personas para calificar en esta actividad.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...targets.map((target) {
                  final existing = _existingEntry(
                    state.feedbackEntries,
                    activityId: activity.id,
                    reviewerUserId: currentUser.id,
                    reviewedUserId: target.userId,
                  );
                  final selected =
                      existing?.selectedFeedback ??
                      _selectedByTargetId[target.userId];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: KawaiiCard(
                      padding: const EdgeInsets.all(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          YnotTheme.surface.withValues(alpha: 0.9),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              KawaiiAvatar(
                                emoji: target.emoji,
                                size: 48,
                                accentColor: YnotTheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      target.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      target.userId == currentUser.id
                                          ? 'Tú'
                                          : 'Feedback privado de esta persona',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (existing != null)
                                const StatusPill(
                                  label: 'Ya enviado',
                                  icon: '✅',
                                  color: Colors.white24,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: PrivateFeedbackOption.values
                                .map(
                                  (option) => _FeedbackOptionButton(
                                    label: option.label,
                                    selected: selected == option,
                                    disabled: existing != null,
                                    onTap: existing != null
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedByTargetId[target
                                                      .userId] =
                                                  option;
                                            });
                                          },
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              FilledButton(
                onPressed:
                    (!_saving && hasSelectableTargets && hasPendingSelection)
                    ? () async {
                        setState(() => _saving = true);
                        try {
                          final controller = ref.read(appControllerProvider);
                          var savedCount = 0;
                          for (final target in targets) {
                            final existing = _existingEntry(
                              state.feedbackEntries,
                              activityId: activity.id,
                              reviewerUserId: currentUser.id,
                              reviewedUserId: target.userId,
                            );
                            if (existing != null) {
                              continue;
                            }

                            final selected = _selectedByTargetId[target.userId];
                            if (selected == null) {
                              continue;
                            }

                            final success = await controller
                                .submitPrivateFeedback(
                                  activityId: activity.id,
                                  reviewerUserId: currentUser.id,
                                  reviewedUserId: target.userId,
                                  selectedFeedback: selected,
                                );
                            if (success) {
                              savedCount += 1;
                            }
                          }

                          if (!context.mounted) return;
                          if (savedCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selecciona al menos una opción antes de enviar.',
                                ),
                              ),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Feedback guardado.')),
                          );
                          context.pop();
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
                          }
                        }
                      }
                    : null,
                child: Text(_saving ? 'Guardando...' : 'Guardar feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<ActivityFeedbackTarget> _feedbackTargetsFor(
    Activity activity,
    String currentUserId,
  ) {
    final targets = activity.feedbackTargets.isEmpty
        ? [
            ActivityFeedbackTarget(
              userId: activity.creatorId,
              label: activity.creatorLabel,
              emoji: activity.emoji,
            ),
          ]
        : activity.feedbackTargets;

    return targets
        .where((target) => target.userId != currentUserId)
        .toList(growable: false);
  }

  PrivateFeedbackEntry? _existingEntry(
    List<PrivateFeedbackEntry> entries, {
    required String activityId,
    required String reviewerUserId,
    required String reviewedUserId,
  }) {
    for (final entry in entries) {
      if (entry.activityId == activityId &&
          entry.reviewerUserId == reviewerUserId &&
          entry.reviewedUserId == reviewedUserId) {
        return entry;
      }
    }
    return null;
  }

  Activity? _findActivity(List<Activity> activities, String activityId) {
    for (final activity in activities) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    return null;
  }
}

class _FeedbackOptionButton extends StatelessWidget {
  const _FeedbackOptionButton({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? YnotTheme.primary
        : Colors.white.withValues(alpha: 0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 154,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? YnotTheme.primary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: disabled ? 0.55 : 1),
          ),
        ),
        child: Row(
          children: [
            Text(label.split(' ').first, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label.split(' ').skip(1).join(' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundBubble extends StatelessWidget {
  const _RoundBubble({required this.icon, required this.onTap});

  final IconData icon;
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
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
