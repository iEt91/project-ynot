import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/moderation_report.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  bool _loadingMessages = true;

  @override
  void initState() {
    super.initState();
    _bootstrapChat();
  }

  Future<void> _bootstrapChat() async {
    try {
      final controller = ref.read(appControllerProvider);
      await controller.loadChatMessages(widget.activityId);
      if (!mounted) return;
      await controller.watchChatMessages(widget.activityId);
    } finally {
      if (mounted) {
        setState(() => _loadingMessages = false);
      }
    }
  }

  @override
  void dispose() {
    unawaited(
      ref
          .read(appControllerProvider)
          .stopWatchingChatMessages(widget.activityId),
    );
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final activity = state.activities
        .where((item) => item.id == widget.activityId)
        .firstOrNull;

    if (activity == null) {
      return Scaffold(
        body: KawaiiScene(
          child: Center(
            child: KawaiiCard(child: const Text('No encontramos este chat.')),
          ),
        ),
      );
    }

    final messages =
        state.chatMessages[widget.activityId] ?? const <ChatMessage>[];
    final status = activity.myStatus;
    final isConfirmed = status == ParticipantStatus.confirmed;
    final isCreator = state.user?.id == activity.creatorId;
    final canStart = isCreator &&
        (activity.status == ActivityStatus.open ||
            activity.status == ActivityStatus.active);
    final canFinish = isCreator && activity.status == ActivityStatus.ongoing;
    final isFinishedOrArchived = activity.isFinishedOrArchived;
    final canSendMessage = !isFinishedOrArchived;
    final canConfirm = !isCreator &&
        status == ParticipantStatus.joinedPendingConfirmation;
    final canCancel = !isCreator &&
        (status == ParticipantStatus.joinedPendingConfirmation ||
            status == ParticipantStatus.confirmed);
    final canLeave = !isCreator &&
        (status == ParticipantStatus.joinedPendingConfirmation ||
            status == ParticipantStatus.confirmed);
    final userStatus = state.user?.status;
    final isRestricted =
        userStatus == UserStatus.limited || userStatus == UserStatus.banned;
    final canAccessChat =
        !isRestricted &&
        (status == ParticipantStatus.joinedPendingConfirmation ||
            status == ParticipantStatus.confirmed);

    if (!canAccessChat) {
      return Scaffold(
        body: KawaiiScene(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: KawaiiCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'El chat no está disponible ahora mismo.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reúnete desde el detalle de la actividad para volver a entrar al chat.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () =>
                            context.push('/activity/${widget.activityId}'),
                        child: const Text('Volver al detalle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Row(
                  children: [
                    _IconOnlyButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
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
                          const SizedBox(height: 2),
                          Text(
                            '${formatTimeOfDay(activity.startTime)} · ${activity.zone}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<_ChatAction>(
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                      ),
                      color: YnotTheme.surface2,
                      onSelected: (value) async {
                        switch (value) {
                          case _ChatAction.startActivity:
                            if (canStart) {
                              await ref
                                  .read(appControllerProvider)
                                  .startActivity(activity.id);
                            }
                            break;
                          case _ChatAction.finishActivity:
                            if (canFinish) {
                              await ref
                                  .read(appControllerProvider)
                                  .finishActivity(activity.id);
                            }
                            break;
                          case _ChatAction.confirmAttendance:
                            if (canConfirm) {
                              await ref
                                  .read(appControllerProvider)
                                  .confirmAttendance(activity.id);
                            }
                            break;
                          case _ChatAction.cancelAttendance:
                            if (canCancel) {
                              final router = GoRouter.of(context);
                              await ref
                                  .read(appControllerProvider)
                                  .cancelAttendance(activity.id);
                              if (!mounted) return;
                              if (router.canPop()) {
                                router.pop();
                              }
                            }
                            break;
                          case _ChatAction.feedback:
                            context.push('/activity/${activity.id}/feedback');
                            break;
                          case _ChatAction.reportActivity:
                            context.push(
                              '/activity/${activity.id}/report',
                              extra: ReportRequest(
                                activityId: activity.id,
                                targetType: ReportTargetType.activity,
                                targetId: activity.id,
                              ),
                            );
                            break;
                          case _ChatAction.reportUser:
                            context.push(
                              '/activity/${activity.id}/report',
                              extra: ReportRequest(
                                activityId: activity.id,
                                targetType: ReportTargetType.user,
                                targetId: activity.creatorId,
                              ),
                            );
                            break;
                          case _ChatAction.leaveEvent:
                            if (canLeave) {
                              final router = GoRouter.of(context);
                              await ref
                                  .read(appControllerProvider)
                                  .leaveActivity(activity.id);
                              if (!mounted) return;
                              if (router.canPop()) {
                                router.pop();
                              }
                            }
                            break;
                          case _ChatAction.deleteActivity:
                            final confirmed =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      title: const Text('¿Eliminar actividad?'),
                                      content: const Text(
                                        'Esto eliminará la actividad del mapa, la lista y los chats. Esta acción no se puede deshacer.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;
                            if (!confirmed) {
                              break;
                            }

                            final deleted = await ref
                                .read(appControllerProvider)
                                .deleteActivity(activity.id);
                            if (!deleted || !context.mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Actividad eliminada.'),
                              ),
                            );
                            if (!context.mounted) return;
                            context.go('/');
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (canStart)
                          const PopupMenuItem(
                            value: _ChatAction.startActivity,
                            child: Text('Iniciar actividad'),
                          ),
                        if (canFinish)
                          const PopupMenuItem(
                            value: _ChatAction.finishActivity,
                            child: Text('Finalizar actividad'),
                          ),
                        if (!isFinishedOrArchived && !isCreator)
                          PopupMenuItem(
                            value: _ChatAction.confirmAttendance,
                            enabled: canConfirm,
                            child: Text(
                              isConfirmed
                                  ? 'Asistencia confirmada'
                                  : 'Confirmar asistencia',
                            ),
                          ),
                        if (!isFinishedOrArchived && !isCreator)
                          PopupMenuItem(
                            value: _ChatAction.cancelAttendance,
                            enabled: canCancel,
                            child: const Text('Cancelar asistencia'),
                          ),
                        const PopupMenuItem(
                          value: _ChatAction.feedback,
                          child: Text('Feedback'),
                        ),
                        if (!isFinishedOrArchived && !isCreator)
                          PopupMenuItem(
                            value: _ChatAction.leaveEvent,
                            enabled: canLeave,
                            child: const Text('Salir del evento'),
                          ),
                        const PopupMenuItem(
                          value: _ChatAction.reportActivity,
                          child: Text('Reportar actividad'),
                        ),
                        if (!isCreator)
                          const PopupMenuItem(
                            value: _ChatAction.reportUser,
                            child: Text('Reportar usuario'),
                          ),
                        if (isCreator)
                          const PopupMenuItem(
                            value: _ChatAction.deleteActivity,
                            child: Text('Eliminar actividad'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: KawaiiCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 88,
                        height: 30,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              child: _OpaqueAttendeeAvatar(emoji: '☕'),
                            ),
                            Positioned(
                              left: 18,
                              child: _OpaqueAttendeeAvatar(emoji: '🌙'),
                            ),
                            Positioned(
                              left: 36,
                              child: _OpaqueAttendeeAvatar(emoji: '✨'),
                            ),
                            Positioned(
                              left: 54,
                              child: _OpaqueAttendeeAvatar(emoji: '💬'),
                            ),
                            Positioned(
                              left: 72,
                              child: _OpaqueAttendeeAvatar(emoji: '🐾'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${activity.confirmedCount} asistentes confirmados',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isFinishedOrArchived && !isCreator) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canConfirm
                          ? () async {
                              await ref
                                  .read(appControllerProvider)
                                  .confirmAttendance(activity.id);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: isConfirmed
                            ? YnotTheme.mint.withValues(alpha: 0.22)
                            : YnotTheme.mint,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: YnotTheme.mint.withValues(
                          alpha: 0.18,
                        ),
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.82,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        isConfirmed
                            ? 'Asistencia confirmada'
                            : 'Confirmar asistencia',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                const SizedBox(height: 10),
              ],
              Expanded(
                child: _loadingMessages && messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : messages.isEmpty
                    ? Center(
                        child: KawaiiCard(
                          child: Text(
                            'Todavía no hay mensajes.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                        children: [
                          ...messages.map(
                            (message) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ChatMessageBubble(
                                activityId: activity.id,
                                message: message,
                                accentColor: _categoryColor(activity.category),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Column(
                  children: [
                    if (!canSendMessage) ...[
                      KawaiiCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Text(
                          'Chat en modo lectura.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    KawaiiCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: canSendMessage,
                              decoration: const InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                border: InputBorder.none,
                                filled: false,
                              ),
                              onSubmitted: canSendMessage
                                  ? (_) async {
                                      final text = _messageController.text.trim();
                                      if (text.isEmpty) return;
                                      await ref
                                          .read(appControllerProvider)
                                          .sendChatMessage(activity.id, text);
                                      _messageController.clear();
                                    }
                                  : null,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            onPressed: canSendMessage
                                ? () async {
                                    final text = _messageController.text.trim();
                                    if (text.isEmpty) return;
                                    await ref
                                        .read(appControllerProvider)
                                        .sendChatMessage(activity.id, text);
                                    _messageController.clear();
                                  }
                                : null,
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
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

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.activityId,
    required this.message,
    required this.accentColor,
  });

  final String activityId;
  final ChatMessage message;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    final bubbleColor = isMe
        ? LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.88),
              const Color(0xFFA93A7D),
            ],
          )
        : LinearGradient(
            colors: [
              YnotTheme.surface2.withValues(alpha: 0.96),
              YnotTheme.surface.withValues(alpha: 0.88),
            ],
          );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) async {
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
        final selected = await showMenu<_MessageMenuAction>(
          context: context,
          position: RelativeRect.fromRect(
            Rect.fromPoints(details.globalPosition, details.globalPosition),
            Offset.zero & overlay.size,
          ),
          color: YnotTheme.surface2,
          items: const [
            PopupMenuItem(
              value: _MessageMenuAction.report,
              child: Text('Reportar mensaje'),
            ),
          ],
        );
        if (selected == _MessageMenuAction.report) {
          if (!context.mounted) return;
          context.push(
            '/activity/$activityId/report',
            extra: ReportRequest(
              activityId: activityId,
              targetType: ReportTargetType.message,
              targetId: message.id,
            ),
          );
        }
      },
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            KawaiiAvatar(
              emoji: message.senderEmoji,
              size: 34,
              accentColor: accentColor,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    message.senderName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: bubbleColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: YnotTheme.border,
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.timeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 10),
            KawaiiAvatar(
              emoji: message.senderEmoji,
              size: 34,
              accentColor: accentColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _IconOnlyButton extends StatelessWidget {
  const _IconOnlyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
    );
  }
}

class _OpaqueAttendeeAvatar extends StatelessWidget {
  const _OpaqueAttendeeAvatar({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1A2238),
        border: Border.all(color: YnotTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 13)),
    );
  }
}

enum _ChatAction {
  startActivity,
  finishActivity,
  confirmAttendance,
  cancelAttendance,
  feedback,
  leaveEvent,
  reportActivity,
  reportUser,
  deleteActivity,
}

enum _MessageMenuAction { report }

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
