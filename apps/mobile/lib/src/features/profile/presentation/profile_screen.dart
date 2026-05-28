import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final user = state.user;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const SectionHeader(
          title: 'Profile',
          subtitle: 'Minimal profile only. No public social graph.',
        ),
        const SizedBox(height: 14),
        if (user == null)
          const KawaiiCard(child: Text('No user session loaded.'))
        else ...[
          KawaiiCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(user.avatarEmoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.nickname,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(user.phoneMasked),
                    ],
                  ),
                ),
                StatusPill(label: user.status.name),
              ],
            ),
          ),
          const SizedBox(height: 14),
          KawaiiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Languages', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.languages.map((label) => StatusPill(label: label)).toList(),
                ),
                const SizedBox(height: 14),
                Text('Vibes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.vibes.map((label) => StatusPill(label: label)).toList(),
                ),
                const SizedBox(height: 14),
                Text('Interests', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.interests.map((label) => StatusPill(label: label)).toList(),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        KawaiiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trust score', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Hidden from the client. Backend only.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.read(appControllerProvider).signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
