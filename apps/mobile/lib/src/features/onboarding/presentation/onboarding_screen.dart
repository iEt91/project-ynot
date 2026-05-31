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
  static const _emojiOptions = ['🌙', '✨', '☕', '📚', '🎨', '🐾', '🌸'];
  static const _languageOptions = ['Korean', 'English', 'Spanish', 'Japanese'];
  static const _vibeOptions = ['Calm', 'Social', 'Creative', 'Productive'];
  static const _interestOptions = ['Coffee', 'Study', 'Walks', 'Art', 'Food', 'Music'];

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;
  late String _selectedEmoji;
  late Set<String> _selectedLanguages;
  late Set<String> _selectedVibes;
  late Set<String> _selectedInterests;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).user?.sanitizedForDisplay();
    final hasUser = user != null;

    _nameController = TextEditingController(
      text: hasUser && user.nickname.isNotEmpty ? user.nickname : 'Luna',
    );
    _bioController = TextEditingController(
      text: hasUser &&
              user.bio.isNotEmpty &&
              user.bio != 'Pequeños momentos, juntos.'
          ? user.bio
          : '',
    );
    _phoneController = TextEditingController(
      text: hasUser && user.phoneMasked.isNotEmpty ? user.phoneMasked : 'Sesión local',
    );
    _selectedEmoji = hasUser && _emojiOptions.contains(user.avatarEmoji)
        ? user.avatarEmoji
        : '🌙';
    _selectedLanguages = {
      ...(user?.languages ?? const <String>[]),
    };
    _selectedVibes = {
      ...(user?.vibes ?? const <String>[]),
    };
    _selectedInterests = {
      ...((hasUser && user.interests.isNotEmpty) ? user.interests : const ['Coffee']),
    };
    _nameController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldsChanged);
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider);
    final phoneLabel = _phoneController.text.trim().isEmpty
        ? 'Sesión local'
        : _phoneController.text.trim();
    final canSkipLater = _nameController.text.trim().isNotEmpty && _selectedEmoji.isNotEmpty;

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: [
              const SectionHeader(
                title: 'Completa tu perfil',
                subtitle: 'Un toque rápido antes de entrar.',
              ),
              const SizedBox(height: 16),
              KawaiiCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    KawaiiAvatar(
                      emoji: _selectedEmoji,
                      size: 72,
                      accentColor: YnotTheme.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu vibra inicial',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Elige un nombre, un avatar y al menos un interés para entrar.',
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
              _CardSection(
                title: 'Avatar',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _emojiOptions.map((emoji) {
                    final selected = _selectedEmoji == emoji;
                    return _SelectableEmoji(
                      emoji: emoji,
                      selected: selected,
                      onTap: () => setState(() => _selectedEmoji = emoji),
                    );
                  }).toList(growable: false),
                ),
              ),
              const SizedBox(height: 14),
              _CardSection(
                title: 'Cuenta',
                child: Column(
                  children: [
                    _FieldBox(
                      label: 'Nombre visible',
                      controller: _nameController,
                      hintText: 'Luna',
                    ),
                    const SizedBox(height: 12),
                    _FieldBox(
                      label: 'Teléfono',
                      controller: _phoneController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    _FieldBox(
                      label: 'Bio / frase',
                      controller: _bioController,
                      hintText: 'Pequeños momentos, juntos.',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ChipSection(
                title: 'Idiomas',
                options: _languageOptions,
                selected: _selectedLanguages,
                onToggle: (value) => setState(() => _toggleSelection(_selectedLanguages, value)),
              ),
              const SizedBox(height: 14),
              _ChipSection(
                title: 'Vibes',
                options: _vibeOptions,
                selected: _selectedVibes,
                onToggle: (value) => setState(() => _toggleSelection(_selectedVibes, value)),
              ),
              const SizedBox(height: 14),
              _ChipSection(
                title: 'Intereses',
                options: _interestOptions,
                selected: _selectedInterests,
                onToggle: (value) => setState(() => _toggleSelection(_selectedInterests, value)),
              ),
              const SizedBox(height: 14),
              KawaiiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: () async {
                        final nickname = _nameController.text.trim();
                        if (nickname.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Escribe un nombre para continuar.'),
                            ),
                          );
                          return;
                        }
                        if (_selectedInterests.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Elige al menos un interés.'),
                            ),
                          );
                          return;
                        }

                        await controller.completeOnboarding(
                          nickname: nickname,
                          avatarEmoji: _selectedEmoji,
                          languages: _selectedLanguages.toList(growable: false),
                          vibes: _selectedVibes.toList(growable: false),
                          interests: _selectedInterests.toList(growable: false),
                          bio: _bioController.text.trim(),
                        );
                      },
                      child: const Text('Entrar'),
                    ),
                    if (canSkipLater) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () async {
                          await controller.completeOnboarding(
                            nickname: _nameController.text.trim(),
                            avatarEmoji: _selectedEmoji,
                            languages: _selectedLanguages.toList(growable: false),
                            vibes: _selectedVibes.toList(growable: false),
                            interests: _selectedInterests.isEmpty
                                ? const ['Coffee']
                                : _selectedInterests.toList(growable: false),
                            bio: _bioController.text.trim(),
                          );
                        },
                        child: const Text('Completar luego'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                phoneLabel,
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

  void _toggleSelection(Set<String> values, String value) {
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
  }

  void _onFieldsChanged() {
    if (mounted) {
      setState(() {});
    }
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              final isSelected = selected.contains(option);
              return FilterChip(
                selected: isSelected,
                label: Text(option),
                onSelected: (_) => onToggle(option),
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                side: BorderSide(
                  color: isSelected ? YnotTheme.primary : YnotTheme.border,
                ),
                selectedColor: YnotTheme.primary.withValues(alpha: 0.25),
                backgroundColor: YnotTheme.surface.withValues(alpha: 0.45),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.label,
    required this.controller,
    this.hintText,
    this.readOnly = false,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool readOnly;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
          ),
        ),
      ],
    );
  }
}

class _SelectableEmoji extends StatelessWidget {
  const _SelectableEmoji({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? YnotTheme.primary.withValues(alpha: 0.20)
              : YnotTheme.surface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? YnotTheme.primary : YnotTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
