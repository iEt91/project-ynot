import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_card.dart';
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const SectionHeader(
                title: 'Create your vibe',
                subtitle: 'Keep it minimal. No long bios. No social overload.',
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
                    Text(
                      'Languages',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Korean', 'English', 'Japanese', 'Spanish']
                          .map(
                            (label) => FilterChip(
                              label: Text(label),
                              selected: _languages.contains(label),
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _languages.add(label) : _languages.remove(label);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Vibes',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Calm', 'Social', 'Chill', 'Creative', 'Study', 'Walks']
                          .map(
                            (label) => FilterChip(
                              label: Text(label),
                              selected: _vibes.contains(label),
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _vibes.add(label) : _vibes.remove(label);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Interests',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Coffee', 'Study', 'Walks', 'Food', 'Gaming', 'Music', 'Art']
                          .map(
                            (label) => FilterChip(
                              label: Text(label),
                              selected: _interests.contains(label),
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _interests.add(label) : _interests.remove(label);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final nickname = _nicknameController.text.trim();
                        if (nickname.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add a nickname first.')),
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
                      child: const Text('Continue to map'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }
}
