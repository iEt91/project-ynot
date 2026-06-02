import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/moderation_flag.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../profile/presentation/profile_back_button.dart';

class FlagDetailScreen extends ConsumerWidget {
  const FlagDetailScreen({super.key, required this.flagId});

  final String flagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider);
    final state = ref.watch(appStateProvider);
    final flag = controller.moderationFlagById(flagId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [YnotTheme.surface, YnotTheme.surface2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: flag == null
              ? const Center(child: Text('Flag no disponible.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
                  children: [
                    Row(
                      children: [
                        ProfileBackButton(onTap: () => Navigator.of(context).pop()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Detalle del flag',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contexto local para revisar una señal de moderación.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SummaryCard(
                      flag: flag,
                      activity: _findActivity(state.activities, flag.activityId),
                      displayName: _displayNameForFlag(controller, state, flag),
                      avatarEmoji: _avatarForFlag(controller, state, flag),
                    ),
                    const SizedBox(height: 12),
                    if (flag.sourceType == ModerationFlagSourceType.activity)
                      _ActivityContextCard(
                        activity: _findActivity(state.activities, flag.activityId),
                      )
                    else
                      _MessageContextCard(
                        activity: _findActivity(state.activities, flag.activityId),
                        messages: state.chatMessages[flag.activityId] ?? const <ChatMessage>[],
                        sourceId: flag.sourceId,
                      ),
                    const SizedBox(height: 12),
                    _SnippetCard(flag: flag),
                    const SizedBox(height: 12),
                    _ActionsCard(
                      flag: flag,
                      onReviewed: () async {
                        await controller.markModerationFlagReviewed(flag.flagId);
                      },
                      onDismissed: () async {
                        await controller.dismissModerationFlag(flag.flagId);
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Activity? _findActivity(List<Activity> activities, String activityId) {
    for (final activity in activities) {
      if (activity.id == activityId) {
        return activity;
      }
    }
    return null;
  }

  String _displayNameForFlag(
    AppController controller,
    AppState state,
    ModerationFlag flag,
  ) {
    final activity = _findActivity(state.activities, flag.activityId);
    if (flag.sourceType == ModerationFlagSourceType.activity) {
      if (state.user != null && state.user!.id == flag.userId) {
        return state.user!.nickname;
      }
      final profile = controller.publicProfileForUserId(flag.userId);
      if (profile != null) {
        return profile.nickname;
      }
      return activity?.creatorLabel.isNotEmpty == true
          ? activity!.creatorLabel
          : 'Usuario';
    }

    final message = (state.chatMessages[flag.activityId] ?? const <ChatMessage>[])
        .firstWhere(
          (item) => item.id == flag.sourceId,
          orElse: () => ChatMessage(
            id: '',
            chatId: '',
            activityId: flag.activityId,
            senderId: flag.userId,
            senderName: 'Usuario',
            senderEmoji: '💬',
            content: '',
            createdAt: DateTime.now(),
          ),
        );
    if (message.id.isNotEmpty) {
      return safeDisplayText(message.senderName, fallback: 'Usuario');
    }

    final profile = controller.publicProfileForUserId(flag.userId);
    return profile != null ? profile.nickname : 'Usuario';
  }

  String _avatarForFlag(
    AppController controller,
    AppState state,
    ModerationFlag flag,
  ) {
    final activity = _findActivity(state.activities, flag.activityId);
    if (flag.sourceType == ModerationFlagSourceType.activity) {
      if (state.user != null && state.user!.id == flag.userId) {
        return state.user!.avatarEmoji;
      }
      final profile = controller.publicProfileForUserId(flag.userId);
      if (profile != null) {
        return profile.avatarEmoji;
      }
      return activity?.emoji ?? '💬';
    }

    final message = (state.chatMessages[flag.activityId] ?? const <ChatMessage>[])
        .firstWhere(
          (item) => item.id == flag.sourceId,
          orElse: () => ChatMessage(
            id: '',
            chatId: '',
            activityId: flag.activityId,
            senderId: flag.userId,
            senderName: 'Usuario',
            senderEmoji: '💬',
            content: '',
            createdAt: DateTime.now(),
          ),
        );
    if (message.id.isNotEmpty) {
      return safeDisplayText(message.senderEmoji, fallback: '💬');
    }

    final profile = controller.publicProfileForUserId(flag.userId);
    return profile != null ? profile.avatarEmoji : '💬';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.flag,
    required this.activity,
    required this.displayName,
    required this.avatarEmoji,
  });

  final ModerationFlag flag;
  final Activity? activity;
  final String displayName;
  final String avatarEmoji;

  @override
  Widget build(BuildContext context) {
    final sourceTypeLabel = switch (flag.sourceType) {
      ModerationFlagSourceType.activity => 'Actividad',
      ModerationFlagSourceType.message => 'Mensaje',
    };

    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: YnotTheme.surface2.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: YnotTheme.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryLabel(flag.category),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniChip(label: sourceTypeLabel),
                        _MiniChip(label: flag.keyword),
                        _MiniChip(label: flag.statusLabel),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Usuario: ${safeDisplayText(displayName, fallback: 'Usuario')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (activity != null) ...[
            const SizedBox(height: 6),
            Text(
              'Actividad: ${safeDisplayText(activity!.title, fallback: 'Actividad')}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '${formatDateLabel(flag.createdAt)} · ${formatTimeOfDay(flag.createdAt)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'drugs' => 'Drogas',
      'sex' => 'Sexo',
      'self_harm' => 'Autolesión',
      'violence' => 'Violencia',
      'vandalism' => 'Vandalismo',
      'spam' => 'Spam',
      _ => category,
    };
  }
}

class _ActivityContextCard extends StatelessWidget {
  const _ActivityContextCard({required this.activity});

  final Activity? activity;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (activity == null)
            const Text('No pudimos encontrar la actividad asociada.')
          else ...[
            Text(
              safeDisplayText(activity!.title, fallback: 'Actividad'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              safeDisplayText(
                activity!.description,
                fallback: 'Sin descripción disponible.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageContextCard extends StatelessWidget {
  const _MessageContextCard({
    required this.activity,
    required this.messages,
    required this.sourceId,
  });

  final Activity? activity;
  final List<ChatMessage> messages;
  final String sourceId;

  @override
  Widget build(BuildContext context) {
    final contextMessages = _buildContextMessages(messages, sourceId);

    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contexto del chat',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (activity == null)
            const Text('No pudimos encontrar la actividad asociada.')
          else
            Text(
              safeDisplayText(activity!.title, fallback: 'Actividad'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 12),
          if (contextMessages.isEmpty)
            const Text('No pudimos encontrar el mensaje señalado.')
          else
            ...contextMessages.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChatContextRow(
                  message: item.message,
                  highlighted: item.highlighted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_ChatContextItem> _buildContextMessages(
    List<ChatMessage> messages,
    String flaggedMessageId,
  ) {
    final index = messages.indexWhere((message) => message.id == flaggedMessageId);
    if (index < 0) {
      return const [];
    }

    final start = index - 3 < 0 ? 0 : index - 3;
    final end = index + 3 >= messages.length ? messages.length - 1 : index + 3;

    final items = <_ChatContextItem>[];
    for (var i = start; i <= end; i++) {
      items.add(
        _ChatContextItem(
          message: messages[i],
          highlighted: i == index,
        ),
      );
    }
    return items;
  }
}

class _ChatContextItem {
  const _ChatContextItem({
    required this.message,
    required this.highlighted,
  });

  final ChatMessage message;
  final bool highlighted;
}

class _ChatContextRow extends StatelessWidget {
  const _ChatContextRow({
    required this.message,
    required this.highlighted,
  });

  final ChatMessage message;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF6D28D9).withValues(alpha: 0.16)
            : YnotTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? const Color(0xFFEC4899) : YnotTheme.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: YnotTheme.surface2.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              border: Border.all(color: YnotTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(
              safeDisplayText(message.senderEmoji, fallback: '💬'),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        safeDisplayText(message.senderName, fallback: 'Usuario'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.timeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  safeDisplayText(message.content, fallback: ''),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnippetCard extends StatelessWidget {
  const _SnippetCard({required this.flag});

  final ModerationFlag flag;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fragmento detectado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            safeDisplayText(flag.textSnippet, fallback: 'Texto no disponible'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.flag,
    required this.onReviewed,
    required this.onDismissed,
  });

  final ModerationFlag flag;
  final Future<void> Function() onReviewed;
  final Future<void> Function() onDismissed;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: flag.isPending
                    ? () {
                        onReviewed();
                      }
                    : null,
                child: const Text('Marcar revisado'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.18),
                  foregroundColor: Colors.white,
                ),
                onPressed: flag.isPending
                    ? () {
                        onDismissed();
                      }
                    : null,
                child: const Text('Descartar'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: safeDisplayText(flag.textSnippet, fallback: '')),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fragmento copiado.')),
                    );
                  }
                },
                child: const Text('Copiar fragmento'),
              ),
            ],
          ),
        ],
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
