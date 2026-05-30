import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/state/app_controller.dart';
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
    final user = state.user;
    final createdCount = user?.createdActivityCount ?? 0;
    final attendingCount = user?.attendingActivityCount ?? 0;

    return KawaiiScene(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
        children: [
          const SectionHeader(
            title: 'Perfil',
            subtitle: 'Tu rincón, simple, bonito y sin ruido social.',
          ),
          const SizedBox(height: 16),
          if (user == null)
            const KawaiiCard(
              child: Text('No encontramos una sesión activa.'),
            )
          else ...[
            KawaiiCard(
              padding: const EdgeInsets.all(18),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  YnotTheme.surface.withValues(alpha: 0.88),
                ],
              ),
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
                      emoji: user.avatarEmoji,
                      size: 82,
                      accentColor: YnotTheme.primary,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nickname.isEmpty ? 'Tu nombre mágico' : user.nickname,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.phoneMasked,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            user.bio,
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
                            StatusPill(label: '$createdCount creadas', color: YnotTheme.mint),
                            StatusPill(label: '$attendingCount asistiendo', color: Colors.white24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ChipSection(
              title: 'Idiomas',
              chips: user.languages.isEmpty ? const ['Korean', 'English'] : user.languages,
            ),
            const SizedBox(height: 14),
            _ChipSection(
              title: 'Vibes',
              chips: user.vibes.isEmpty ? const ['Calm', 'Creative'] : user.vibes,
            ),
            const SizedBox(height: 14),
            _ChipSection(
              title: 'Intereses',
              chips: user.interests.isEmpty ? const ['Coffee', 'Study', 'Walks'] : user.interests,
            ),
          ],
          const SizedBox(height: 14),
          KawaiiCard(
            child: Column(
              children: [
                _ProfileAction(
                  label: 'Mis actividades',
                  emoji: '🗂️',
                  onTap: () => context.go('/'),
                ),
                const Divider(height: 24),
                _ProfileAction(
                  label: 'Historial',
                  emoji: '🕯️',
                  onTap: () {},
                ),
                const Divider(height: 24),
                _ProfileAction(
                  label: 'Guardadas',
                  emoji: '💖',
                  onTap: () {},
                ),
                const Divider(height: 24),
                _ProfileAction(
                  label: 'Configuración',
                  emoji: '⚙️',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          KawaiiCard(
            child: FilledButton.tonal(
              onPressed: () => ref.read(appControllerProvider).signOut(),
              child: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.chips,
  });

  final String title;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((label) => StatusPill(label: label)).toList(),
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
            const Text('›', style: TextStyle(fontSize: 28, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
