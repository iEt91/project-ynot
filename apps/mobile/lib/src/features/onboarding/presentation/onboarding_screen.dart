import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nicknameController = TextEditingController();
  final _emojiController = TextEditingController(text: '🌙');
  final Set<String> _languages = {'Korean'};
  final Set<String> _vibes = {'Calm'};
  final Set<String> _interests = {'Coffee'};

  @override
  void dispose() {
    _nicknameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider);
    final state = ref.watch(appStateProvider);

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  title: 'Tu perfil',
                  subtitle: 'Minimal, lindo y fácil de usar.',
                ),
                const SizedBox(height: 16),
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
                      KawaiiAvatar(
                        emoji: _emojiController.text.isEmpty ? '🌙' : _emojiController.text,
                        size: 72,
                        accentColor: YnotTheme.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crea tu vibra',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Un nickname, un emoji y tus gustos para empezar suave.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                KawaiiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Nickname',
                          hintText: 'Mina',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emojiController,
                        decoration: const InputDecoration(
                          labelText: 'Avatar emoji',
                          hintText: '🌙',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ChipGroup(
                        title: 'Idiomas',
                        options: const ['Korean', 'English', 'Japanese', 'Spanish'],
                        selected: _languages,
                        onChanged: (label, selected) => setState(() {
                          selected ? _languages.add(label) : _languages.remove(label);
                        }),
                      ),
                      const SizedBox(height: 14),
                      _ChipGroup(
                        title: 'Vibes',
                        options: const ['Calm', 'Social', 'Chill', 'Creative', 'Study', 'Walks'],
                        selected: _vibes,
                        onChanged: (label, selected) => setState(() {
                          selected ? _vibes.add(label) : _vibes.remove(label);
                        }),
                      ),
                      const SizedBox(height: 14),
                      _ChipGroup(
                        title: 'Intereses',
                        options: const ['Coffee', 'Study', 'Walks', 'Food', 'Gaming', 'Music', 'Art'],
                        selected: _interests,
                        onChanged: (label, selected) => setState(() {
                          selected ? _interests.add(label) : _interests.remove(label);
                        }),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          final nickname = _nicknameController.text.trim();
                          if (nickname.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Añade un nickname primero.')),
                            );
                            return;
                          }

                          controller.completeOnboarding(
                            nickname: nickname,
                            avatarEmoji: _emojiController.text.trim().isEmpty
                                ? '🌙'
                                : _emojiController.text.trim(),
                            languages: _languages.toList(),
                            vibes: _vibes.toList(),
                            interests: _interests.toList(),
                          );
                        },
                        child: const Text('Entrar al mapa'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  state.user?.phoneMasked ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final void Function(String label, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (label) => FilterChip(
                  label: Text(label),
                  selected: selected.contains(label),
                  onSelected: (value) => onChanged(label, value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
