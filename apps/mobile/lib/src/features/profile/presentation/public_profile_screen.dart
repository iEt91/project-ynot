import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/models/app_user.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_empty_state.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';
import 'profile_back_button.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider);
    final profile = controller.publicProfileForUserId(userId);

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(
                children: [
                  ProfileBackButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Perfil público',
                subtitle: 'Lo que otras personas ven en Ynot.',
              ),
              const SizedBox(height: 16),
              if (profile == null)
                const KawaiiEmptyState(
                  emoji: '🌙',
                  title: 'No encontramos este perfil',
                  message:
                      'Puede que esta persona aún no tenga perfil público disponible.',
                )
              else ...[
                _ProfileHero(profile: profile),
                const SizedBox(height: 14),
                _ProfileSection(
                  title: '🌎 Idiomas',
                  emoji: '🌎',
                  emptyTitle: 'Sin idiomas todavía',
                  emptyMessage:
                      'Cuando la persona complete su perfil, aparecerán aquí.',
                  items: profile.languages,
                  accentColor: YnotTheme.primary,
                ),
                const SizedBox(height: 14),
                _ProfileSection(
                  title: '✨ Vibes',
                  emoji: '✨',
                  emptyTitle: 'Sin vibes todavía',
                  emptyMessage:
                      'Aquí verás cómo le gusta moverse y participar en planes.',
                  items: profile.vibes,
                  accentColor: YnotTheme.purple,
                ),
                const SizedBox(height: 14),
                _ProfileSection(
                  title: '🎯 Intereses',
                  emoji: '🎯',
                  emptyTitle: 'Sin intereses todavía',
                  emptyMessage:
                      'Cuando comparta más gustos, los verás en esta sección.',
                  items: profile.interests,
                  accentColor: YnotTheme.mint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile});

  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final bio = safeDisplayText(
      profile.bio,
      fallback: 'Pequeños momentos, juntos.',
    );

    return KawaiiCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty)
            ClipOval(
              child: Image.network(
                profile.photoUrl!,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return KawaiiAvatar(
                    emoji: safeDisplayText(profile.avatarEmoji, fallback: '🌙'),
                    size: 88,
                    accentColor: YnotTheme.primary,
                  );
                },
              ),
            )
          else
            KawaiiAvatar(
              emoji: safeDisplayText(profile.avatarEmoji, fallback: '🌙'),
              size: 88,
              accentColor: YnotTheme.primary,
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeDisplayText(profile.nickname, fallback: 'Luna'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  bio.isEmpty ? 'Sin bio todavía.' : bio,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.45,
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.emoji,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.items,
    required this.accentColor,
  });

  final String title;
  final String emoji;
  final String emptyTitle;
  final String emptyMessage;
  final List<String> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            KawaiiEmptyState(
              emoji: emoji,
              title: emptyTitle,
              message: emptyMessage,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => StatusPill(
                      label: item,
                      color: accentColor,
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}
