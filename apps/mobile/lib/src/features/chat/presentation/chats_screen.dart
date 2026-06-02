import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/status_pill.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final currentUser = state.user;
    final activeChats = currentUser == null
        ? const <Activity>[]
        : controller.activeChatsForUser(currentUser.id);
    final archivedChats = currentUser == null
        ? const <Activity>[]
        : controller.archivedChatsForUser(currentUser.id);
    final showRecommendations = state.settings.showRecommendations;
    final showArchivedChats = state.settings.showArchivedChats;
    final unreadNotifications = state.notifications
        .where((notification) => !notification.isRead)
        .length;

    return KawaiiScene(
      child: SafeArea(
        bottom: false,
        child: ListView(
          key: const PageStorageKey('chats-screen-list'),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 92),
          children: [
            AppScreenHeader(
              title: 'Chats',
              actions: [
                NotificationBellButton(
                  unreadCount: unreadNotifications,
                  onTap: () async {
                    await ref
                        .read(appControllerProvider)
                        .refreshNotifications();
                    if (context.mounted) {
                      context.push('/notifications');
                    }
                  },
                ),
              ],
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
            const SizedBox(height: 18),
            _ChatsSection(
              title: 'Chats activos',
              children: activeChats.isEmpty
                  ? [
                      KawaiiEmptyState(
                        emoji: '💬',
                        title: 'No tienes chats activos',
                        message:
                            'Entra a una actividad, confirma tu asistencia y su chat aparecerá aquí.',
                        ctaLabel: 'Explorar actividades',
                        onCtaPressed: () => context.go('/'),
                      ),
                    ]
                  : activeChats
                      .map(
                        (activity) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ChatRow(
                            activity: activity,
                            showStartingSoonBadge:
                                showRecommendations &&
                                controller.isActivityStartingSoonForCurrentUser(
                                  activity,
                                ),
                            onTap: () => context.push('/chat/${activity.id}'),
                          ),
                        ),
                      )
                      .toList(growable: false),
            ),
            if (showArchivedChats) ...[
              const SizedBox(height: 20),
              _ChatsSection(
                title: 'Chats archivados',
                children: archivedChats.isEmpty
                    ? [
                        KawaiiEmptyState(
                          emoji: '???',
                          title: 'No tienes chats archivados',
                          message:
                              'Los chats terminados o archivados aparecer?n aqu? en modo lectura.',
                        ),
                      ]
                    : archivedChats
                        .map(
                          (activity) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ChatRow(
                              activity: activity,
                              showStartingSoonBadge: false,
                              showArchivedBadge: true,
                              onTap: () => context.push('/chat/${activity.id}'),
                              onLongPress: () => _showArchivedChatActions(
                                context,
                                ref.read(appControllerProvider),
                                activity,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showArchivedChatActions(
    BuildContext context,
    AppController controller,
    Activity activity,
  ) async {
    final shouldHide = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: YnotTheme.surface2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Eliminar de mi historial',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este chat desaparecerá sólo para ti. No se eliminará para otras personas ni para moderación.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(sheetContext).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;

    if (!shouldHide) {
      return;
    }

    final hidden = await controller.hideArchivedChatFromHistory(activity.id);
    if (!context.mounted || !hidden) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat eliminado de tu historial.')),
    );
  }
}

class _ChatsSection extends StatelessWidget {
  const _ChatsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.activity,
    required this.onTap,
    required this.showStartingSoonBadge,
    this.showArchivedBadge = false,
    this.onLongPress,
  });

  final Activity activity;
  final VoidCallback onTap;
  final bool showStartingSoonBadge;
  final bool showArchivedBadge;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final preview = activity.lastMessagePreview.isNotEmpty
        ? activity.lastMessagePreview
        : 'Todavía no hay mensajes.';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (showArchivedBadge) ...[
                        const SizedBox(width: 8),
                        const StatusPill(label: 'Archivado'),
                      ] else if (showStartingSoonBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5DB8).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFFF5DB8).withValues(
                                alpha: 0.28,
                              ),
                            ),
                          ),
                          child: Text(
                            'Empieza pronto',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFFFF5DB8),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                      if (!showArchivedBadge) ...[
                        const SizedBox(width: 8),
                        Text(
                          activity.myStatus == ParticipantStatus.confirmed
                              ? 'Abierto'
                              : 'En espera',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: activity.myStatus ==
                                            ParticipantStatus.confirmed
                                        ? Colors.pinkAccent
                                        : Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
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
                        activity.unreadMessageCount > 0
                            ? '${activity.unreadMessageCount} nuevos'
                            : 'En vivo',
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
            const Text(
              '›',
              style: TextStyle(fontSize: 28, color: Colors.white70),
            ),
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
