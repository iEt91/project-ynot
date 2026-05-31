import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/presentation/profile_back_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
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
    _nameController = TextEditingController(text: user?.nickname ?? 'Luna');
    _bioController = TextEditingController(
      text: user?.bio == 'Pequeños momentos, juntos.' ? '' : (user?.bio ?? ''),
    );
    _phoneController = TextEditingController(text: user?.phoneMasked ?? 'Sesión local');
    _selectedEmoji = _emojiOptions.contains(user?.avatarEmoji) ? user!.avatarEmoji : '🌙';
    _selectedLanguages = {...(ref.read(appStateProvider).user?.languages ?? const [])};
    _selectedVibes = {...(ref.read(appStateProvider).user?.vibes ?? const [])};
    _selectedInterests = {...(ref.read(appStateProvider).user?.interests ?? const [])};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider);

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
                title: 'Editar perfil',
                subtitle: 'Ajusta tu vibra y guarda cambios locales.',
              ),
              const SizedBox(height: 16),
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
                child: FilledButton(
                  onPressed: () async {
                    await controller.updateProfile(
                      nickname: _nameController.text.trim().isEmpty
                          ? 'Luna'
                          : _nameController.text.trim(),
                      avatarEmoji: _selectedEmoji,
                      bio: _bioController.text.trim(),
                      languages: _selectedLanguages.toList(growable: false),
                      vibes: _selectedVibes.toList(growable: false),
                      interests: _selectedInterests.toList(growable: false),
                    );
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  child: const Text('Guardar cambios'),
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? YnotTheme.primary.withValues(alpha: 0.22)
              : YnotTheme.surface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? YnotTheme.primary : YnotTheme.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.label,
    required this.controller,
    this.hintText,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: YnotTheme.surface.withValues(alpha: 0.50),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: YnotTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: YnotTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: YnotTheme.primary.withValues(alpha: 0.80)),
            ),
          ),
        ),
      ],
    );
  }
}
