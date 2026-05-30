import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/status_pill.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, required this.activityTitle});

  final String activityTitle;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _vibe = '✨ Buena';
  String _person = '🌸 Muy agradable';
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vibeOptions = ['🌸 Increíble', '✨ Buena', '🌙 Normal', '🫠 Meh', '💔 Mala'];
    final personOptions = ['🌸 Muy agradable', '✨ Buena vibra', '🙂 Normal', '🫠 No conectamos', '🚫 No participó'];

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
                      'Después de la actividad',
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
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    YnotTheme.surface.withValues(alpha: 0.88),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KawaiiAvatar(emoji: '🌸', size: 58, accentColor: YnotTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.activityTitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cuéntanos cómo se sintió la vibra.',
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
                    Text(
                      '¿Cómo estuvo la vibra?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vibeOptions
                          .map(
                            (label) => ChoiceChip(
                              label: Text(label),
                              selected: _vibe == label,
                              onSelected: (_) => setState(() => _vibe = label),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¿Qué te pareció esta persona?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: personOptions
                          .map(
                            (label) => ChoiceChip(
                              label: Text(label),
                              selected: _person == label,
                              onSelected: (_) => setState(() => _person = label),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Algo que quieras compartir',
                        hintText: 'Un detalle bonito, una sugerencia suave...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    StatusPill(
                      label: 'Tu respuesta no será pública',
                      icon: '🔒',
                      color: Colors.pinkAccent,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Enviar feedback'),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}
