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
import '../../../shared/widgets/status_pill.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({
    super.key,
    required this.activityId,
    required this.targetType,
    required this.targetId,
  });

  final String activityId;
  final ReportTargetType targetType;
  final String targetId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _noteController = TextEditingController();
  ReportReason? _selectedReason;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final currentUser = state.user;
    final activity = _findActivity(state.activities, widget.activityId);
    final existingReport = currentUser == null
        ? null
        : _existingReport(
            state.reports,
            reporterUserId: currentUser.id,
            targetType: widget.targetType,
            targetId: widget.targetId,
          );

    if (currentUser == null || activity == null) {
      return Scaffold(
        body: KawaiiScene(
          child: SafeArea(
            child: Center(
              child: KawaiiCard(
                child: const Text('No encontramos este reporte.'),
              ),
            ),
          ),
        ),
      );
    }

    final resolvedReason = existingReport?.reason ?? _selectedReason;
    final targetDescription = _targetDescription(state, activity);
    final targetSubtitle = _targetSubtitle(state, activity);
    final targetEmoji = _targetEmoji(state, activity);
    final reasons = ReportReason.values;

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
                      'Reportar',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KawaiiAvatar(
                          emoji: '🛡️',
                          size: 58,
                          accentColor: YnotTheme.purple,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ayúdanos a mantener Ynot seguro.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tu reporte es privado y no será visible para otras personas.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (existingReport != null) ...[
                      const StatusPill(
                        label: 'Ya enviado',
                        icon: '🌸',
                        color: YnotTheme.mint,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Estás reportando',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _TargetPreviewCard(
                      emoji: targetEmoji,
                      title: targetDescription,
                      subtitle: targetSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Motivo del reporte',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reasons
                    .map(
                      (reason) => _ReportReasonButton(
                        reason: reason,
                        selected: resolvedReason == reason,
                        locked: existingReport != null,
                        onTap: existingReport != null
                            ? null
                            : () {
                                setState(() => _selectedReason = reason);
                              },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Nota opcional',
                  hintText: 'Añade un detalle breve si quieres...',
                ),
              ),
              const SizedBox(height: 12),
              const StatusPill(
                label: 'Este reporte se guarda de forma privada',
                icon: '🔒',
                color: YnotTheme.primary,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: existingReport != null || _saving
                    ? null
                    : () async {
                        if (_selectedReason == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Elige un motivo antes de enviar.'),
                            ),
                          );
                          return;
                        }

                        setState(() => _saving = true);
                        try {
                          final controller = ref.read(appControllerProvider);
                          final success = await controller
                              .submitReport(
                                reporterUserId: currentUser.id,
                                targetType: widget.targetType,
                                targetId: widget.targetId,
                                activityId: widget.activityId,
                                reason: _selectedReason!,
                                note: _noteController.text.trim().isEmpty
                                    ? null
                                    : _noteController.text.trim(),
                              );

                          if (!context.mounted) return;
                          final messenger = ScaffoldMessenger.of(context);
                          if (!success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Este reporte ya fue enviado.'),
                              ),
                            );
                            return;
                          }

                          messenger.showSnackBar(
                            const SnackBar(content: Text('Reporte enviado.')),
                          );
                          if (widget.targetType == ReportTargetType.user) {
                            final targetProfile =
                                _resolveTargetProfile(activity, controller);
                            if (targetProfile != null && context.mounted) {
                              final shouldBlock = await _askBlockAfterReport(
                                context,
                              );
                              if (shouldBlock) {
                                await controller.blockUser(targetProfile);
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Usuario bloqueado.'),
                                  ),
                                );
                              }
                            }
                          }
                          if (context.mounted) {
                            context.pop();
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _saving = false);
                          }
                        }
                      },
                child: Text(_saving ? 'Enviando...' : existingReport != null ? 'Ya enviado' : 'Enviar reporte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ModerationReport? _existingReport(
    List<ModerationReport> reports, {
    required String reporterUserId,
    required ReportTargetType targetType,
    required String targetId,
  }) {
    for (final report in reports) {
      if (report.reporterUserId == reporterUserId &&
          report.targetType == targetType &&
          report.targetId == targetId) {
        return report;
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

  AppUser? _resolveTargetProfile(
    Activity activity,
    AppController controller,
  ) {
    if (widget.targetType != ReportTargetType.user) {
      return null;
    }

    final publicProfile = controller.publicProfileForUserId(widget.targetId);
    if (publicProfile != null) {
      return publicProfile;
    }

    if (activity.creatorId == widget.targetId) {
      return AppUser(
        id: activity.creatorId,
        phoneMasked: 'Sesión local',
        nickname: safeDisplayText(activity.creatorLabel, fallback: 'Luna'),
        avatarEmoji: safeDisplayText(activity.emoji, fallback: '🌙'),
        bio: '',
        languages: const [],
        vibes: const [],
        interests: const [],
        status: UserStatus.trusted,
        profileComplete: false,
        createdActivityCount: 0,
        attendingActivityCount: 0,
      );
    }

    for (final target in activity.feedbackTargets) {
      if (target.userId == widget.targetId) {
        return AppUser(
          id: target.userId,
          phoneMasked: 'Sesión local',
          nickname: safeDisplayText(target.label, fallback: 'Usuario'),
          avatarEmoji: safeDisplayText(target.emoji, fallback: '🌙'),
          bio: '',
          languages: const [],
          vibes: const [],
          interests: const [],
          status: UserStatus.trusted,
          profileComplete: false,
          createdActivityCount: 0,
          attendingActivityCount: 0,
        );
      }
    }

    return AppUser(
      id: widget.targetId,
      phoneMasked: 'Sesión local',
      nickname: 'Usuario',
      avatarEmoji: '🌙',
      bio: '',
      languages: const [],
      vibes: const [],
      interests: const [],
      status: UserStatus.trusted,
      profileComplete: false,
      createdActivityCount: 0,
      attendingActivityCount: 0,
    );
  }

  Future<bool> _askBlockAfterReport(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: YnotTheme.surface2,
          title: const Text('¿También quieres bloquear a esta persona?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Bloquear'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _targetDescription(AppState state, Activity activity) {
    return switch (widget.targetType) {
      ReportTargetType.activity => 'Actividad: ${activity.title}',
      ReportTargetType.user => 'Usuario: ${_targetUserName(state, activity)}',
      ReportTargetType.message => 'Mensaje de: ${_targetMessage(state, activity)?.senderName ?? 'Usuario'}',
    };
  }

  String _targetSubtitle(AppState state, Activity activity) {
    return switch (widget.targetType) {
      ReportTargetType.activity => '${activity.zone} · ${formatTimeOfDay(activity.startTime)}',
      ReportTargetType.user => activity.creatorId == state.user?.id
          ? 'Tú'
          : 'Participante de esta actividad',
      ReportTargetType.message =>
          _targetMessage(state, activity)?.content ?? 'Mensaje seleccionado',
    };
  }

  String _targetEmoji(AppState state, Activity activity) {
    return switch (widget.targetType) {
      ReportTargetType.activity => activity.emoji,
      ReportTargetType.user => activity.emoji,
      ReportTargetType.message => _targetMessage(state, activity)?.senderEmoji ?? '💬',
    };
  }

  String _targetUserName(AppState state, Activity activity) {
    return activity.creatorId == state.user?.id
        ? 'Tú'
        : activity.creatorLabel.isNotEmpty
            ? activity.creatorLabel
            : 'Usuario';
  }

  ChatMessage? _targetMessage(AppState state, Activity activity) {
    final messages = state.chatMessages[activity.id] ?? const <ChatMessage>[];
    for (final message in messages) {
      if (message.id == widget.targetId) {
        return message;
      }
    }
    return messages.isNotEmpty ? messages.last : null;
  }
}

class _TargetPreviewCard extends StatelessWidget {
  const _TargetPreviewCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(14),
      gradient: LinearGradient(
          colors: [
          YnotTheme.surface2.withValues(alpha: 0.96),
          YnotTheme.surface.withValues(alpha: 0.88),
        ],
      ),
      child: Row(
        children: [
          KawaiiAvatar(
            emoji: emoji,
            size: 46,
            accentColor: YnotTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ReportReasonButton extends StatelessWidget {
  const _ReportReasonButton({
    required this.reason,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final ReportReason reason;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? YnotTheme.mint : YnotTheme.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 158,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    YnotTheme.mint.withValues(alpha: 0.18),
                    YnotTheme.primary.withValues(alpha: 0.10),
                  ],
                )
              : null,
          color: selected ? null : YnotTheme.surface2.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: locked ? 0.7 : 1),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: YnotTheme.mint.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Text(reason.label.split(' ').first, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                reason.label.split(' ').skip(1).join(' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check_rounded,
                size: 18,
                color: locked ? YnotTheme.mint : Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundBubble extends StatelessWidget {
  const _RoundBubble({
    required this.icon,
    required this.onTap,
  });

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
          color: YnotTheme.surface2.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(color: YnotTheme.border),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
