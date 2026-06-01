import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import 'profile_back_button.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final blockedUsers = state.blockedUsers;

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(
                children: [
                  ProfileBackButton(onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Usuarios bloqueados',
                subtitle: 'Personas ocultas en búsquedas, asistentes y perfil público.',
              ),
              const SizedBox(height: 16),
              if (blockedUsers.isEmpty)
                const KawaiiEmptyState(
                  emoji: '🌙',
                  title: 'Aún no bloqueaste a nadie',
                  message:
                      'Cuando bloquees a una persona, aparecerá aquí para que puedas desbloquearla.',
                )
              else
                Column(
                  children: [
                    for (final entry in blockedUsers) ...[
                      _BlockedUserCard(
                        nickname: safeDisplayText(entry.nickname, fallback: 'Luna'),
                        avatarEmoji: safeDisplayText(
                          entry.avatarEmoji,
                          fallback: '🌙',
                        ),
                        blockedAt: entry.blockedAt,
                        onUnblock: () async {
                          await controller.unblockUser(entry.userId);
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario desbloqueado.'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedUserCard extends StatelessWidget {
  const _BlockedUserCard({
    required this.nickname,
    required this.avatarEmoji,
    required this.blockedAt,
    required this.onUnblock,
  });

  final String nickname;
  final String avatarEmoji;
  final DateTime blockedAt;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          KawaiiAvatar(
            emoji: avatarEmoji,
            size: 48,
            accentColor: YnotTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bloqueado el ${_formatDate(blockedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(
            onPressed: onUnblock,
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
  }
}
