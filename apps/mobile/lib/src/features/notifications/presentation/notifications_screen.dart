import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/in_app_notification.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/presentation/profile_back_button.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(appControllerProvider).refreshNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final notifications = controller.notifications();
    final unreadCount = state.notifications
        .where((notification) => !notification.isRead)
        .length;

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(children: [ProfileBackButton(onTap: () => context.pop())]),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Notificaciones',
                subtitle: 'Lo que pasa en tus planes, sin salir de la app.',
              ),
              const SizedBox(height: 12),
              if (notifications.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: unreadCount == 0
                          ? null
                          : () async {
                              await controller.markAllNotificationsRead();
                            },
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('Marcar todas como leídas'),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Borrar todas',
                      onPressed: () async {
                        final confirmed = await _confirmClearAll(context);
                        if (!confirmed || !context.mounted) return;
                        await controller.clearNotifications();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Se borraron tus notificaciones.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              if (notifications.isEmpty)
                const KawaiiEmptyState(
                  emoji: '🔔',
                  title: 'No tienes notificaciones.',
                  message:
                      'Cuando pase algo importante en tus actividades, aparecerá aquí.',
                )
              else
                ...notifications.map(
                  (notification) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotificationTile(
                      notification: notification,
                      onTap: () async {
                        await controller.markNotificationRead(notification.id);
                        if (!context.mounted) return;
                        context.push(_routeForNotification(notification));
                      },
                      onDelete: () async {
                        final confirmed = await _confirmDelete(context);
                        if (!confirmed || !context.mounted) return;
                        await controller.deleteNotification(notification.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notificación eliminada.'),
                          ),
                        );
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

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: YnotTheme.surface2,
              title: const Text('Eliminar notificación'),
              content: const Text('Esta notificación desaparecerá sólo para ti.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _confirmClearAll(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: YnotTheme.surface2,
              title: const Text('Borrar notificaciones'),
              content: const Text('Se eliminarán todas tus notificaciones locales.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Borrar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _routeForNotification(InAppNotification notification) {
    return switch (notification.type) {
      InAppNotificationType.newMessage => '/chat/${notification.activityId}',
      InAppNotificationType.feedbackAvailable =>
        '/activity/${notification.activityId}/feedback',
      _ => '/activity/${notification.activityId}',
    };
  }
}

enum _NotificationAction { delete }

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final InAppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return GestureDetector(
      onLongPress: onDelete,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: KawaiiCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KawaiiAvatar(
                emoji: notification.emoji,
                size: 50,
                accentColor: unread ? YnotTheme.primary : YnotTheme.surface2,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                          ),
                        ),
                        PopupMenuButton<_NotificationAction>(
                          icon: const Icon(Icons.more_horiz_rounded),
                          color: YnotTheme.surface2,
                          onSelected: (value) {
                            switch (value) {
                              case _NotificationAction.delete:
                                onDelete();
                                break;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _NotificationAction.delete,
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                        if (unread) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: YnotTheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _formatTime(notification.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        _UnreadLabel(label: unread ? 'Nuevo' : 'Leída'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final now = DateTime.now();
    final sameDay =
        now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;
    final time = formatTimeOfDay(value);
    if (sameDay) {
      return 'Hoy · $time';
    }

    return '${formatDateLabel(value)} · $time';
  }
}

class _UnreadLabel extends StatelessWidget {
  const _UnreadLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: YnotTheme.surface2.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: YnotTheme.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
