import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.user?.sanitizedForDisplay();

    return KawaiiScene(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
        children: [
          const SectionHeader(
            title: 'Perfil',
            subtitle: 'Tu rincón, simple, bonito y privado.',
          ),
          const SizedBox(height: 16),
          if (user == null)
            const KawaiiCard(child: Text('No encontramos una sesión activa.'))
          else ...[
            KawaiiCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        user.photoUrl!,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    KawaiiAvatar(
                      emoji: safeDisplayText(user.avatarEmoji, fallback: '🌙'),
                      size: 82,
                      accentColor: YnotTheme.primary,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          safeDisplayText(user.nickname, fallback: 'Luna'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          safePhoneDisplay(user.phoneMasked),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (safeDisplayText(
                              user.bio,
                              fallback: 'Pequeños momentos, juntos.',
                            ).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            safeDisplayText(
                              user.bio,
                              fallback: 'Pequeños momentos, juntos.',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusPill(label: 'Calm', color: YnotTheme.primary),
                            StatusPill(label: 'Social', color: YnotTheme.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          KawaiiCard(
            child: Column(
              children: [
                _ProfileAction(
                  label: 'Mis actividades',
                  emoji: '🗂️',
                  onTap: () => context.push('/my-activities'),
                ),
                const Divider(height: 24),
                _ProfileAction(
                  label: 'Historial',
                  emoji: '🕯️',
                  onTap: () => context.push('/history'),
                ),
                const Divider(height: 24),
                _ProfileAction(
                  label: 'Guardadas',
                  emoji: '💖',
                  onTap: () => context.push('/saved'),
                ),
                const Divider(height: 24),
                _ProfileAction(
                  label: 'Configuración',
                  emoji: '⚙️',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          KawaiiCard(
            child: FilledButton.tonal(
              onPressed: () {
                ref.read(appControllerProvider).signOut();
                context.go('/');
              },
              child: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const Text(
              '›',
              style: TextStyle(fontSize: 28, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
