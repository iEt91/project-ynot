import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final joinedActivities = ref.watch(appStateProvider).activities.where((activity) {
      return activity.myStatus == ParticipantStatus.joinedPendingConfirmation ||
          activity.myStatus == ParticipantStatus.confirmed;
    }).toList();

    return KawaiiScene(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 92),
        children: [
          Text(
            'Chats',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
          ),
          const SizedBox(height: 14),
          KawaiiCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estos chats desaparecen al terminar la actividad.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (joinedActivities.isEmpty)
            _EmptyChats(onDiscover: () => context.go('/'))
          else
            ...joinedActivities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChatRow(
                  activity: activity,
                  onTap: () => context.push('/chat/${activity.id}'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.activity,
    required this.onTap,
  });

  final Activity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = activity.lastMessagePreview.isNotEmpty
        ? activity.lastMessagePreview
        : 'Todavía no hay mensajes.';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: KawaiiCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            KawaiiAvatar(
              emoji: activity.emoji,
              size: 48,
              accentColor: _categoryColor(activity.category),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        activity.myStatus == ParticipantStatus.confirmed ? 'Abierto' : 'En espera',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: activity.myStatus == ParticipantStatus.confirmed
                                  ? Colors.pinkAccent
                                  : Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activity.zone} · ${formatTimeOfDay(activity.startTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        activity.unreadMessageCount > 0 ? '${activity.unreadMessageCount} nuevos' : 'En vivo',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('›', style: TextStyle(fontSize: 28, color: Colors.white70)),
          ],
        ),
      ),
    );
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

class _EmptyChats extends StatelessWidget {
  const _EmptyChats({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Todavía no hay chats abiertos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Entra a una actividad, confirma tu asistencia y verás cómo aparece su espacio temporal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onDiscover,
            child: const Text('Explorar actividades'),
          ),
        ],
      ),
    );
  }
}
