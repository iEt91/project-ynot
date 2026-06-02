import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/models/moderation_flag.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/moderation_warning_dialog.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/presentation/profile_back_button.dart';
import '../../../shared/widgets/status_pill.dart';

class ActivityFormSeed {
  const ActivityFormSeed({
    this.initialLocation,
    this.activity,
    this.duplicate = false,
  });

  final LatLng? initialLocation;
  final Activity? activity;
  final bool duplicate;
}

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({
    super.key,
    this.initialLocation,
    this.editingActivity,
    this.prefillActivity,
  });

  final LatLng? initialLocation;
  final Activity? editingActivity;
  final Activity? prefillActivity;

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'Coffee';
  String _vibe = 'Calm';
  String _zone = 'Hongdae';
  ActivityVisibility _visibility = ActivityVisibility.publicActivity;
  int _maxPeople = 4;
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  Duration _duration = const Duration(hours: 2);
  double _lat = 37.5563;
  double _lng = 126.9228;

  bool get _isEditing => widget.editingActivity != null;

  @override
  void initState() {
    super.initState();
    final activity = widget.editingActivity ?? widget.prefillActivity;
    if (activity != null) {
      _titleController.text = activity.title;
      _descriptionController.text = activity.description;
      _category = activity.category;
      _vibe = activity.vibe;
      _zone = activity.zone;
      _visibility = activity.visibility;
      _maxPeople = activity.maxPeople;
      _startTime = activity.startTime;
      _duration = activity.endTime.difference(activity.startTime);
      _lat = activity.realLat;
      _lng = activity.realLng;
    }

    final location = widget.initialLocation;
    if (location != null) {
      _lat = location.latitude;
      _lng = location.longitude;
      _zone = _zoneFromLocation(location.latitude, location.longitude);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider);
    final canCreateActivity = _isEditing || controller.canCreateActivity();
    final creationBlockMessage = _isEditing
        ? null
        : controller.creationRestrictionMessage();
    final theme = Theme.of(context);
    final submitLabel = _isEditing ? 'Guardar cambios' : 'Publicar actividad';
    final selectedLocationLabel = _zone;

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              Row(
                children: [
                  ProfileBackButton(onTap: () => context.pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar actividad' : 'Crear actividad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: YnotTheme.surface2.withValues(alpha: 0.96),
                        shape: BoxShape.circle,
                        border: Border.all(color: YnotTheme.border),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Arma un momento bonito',
                subtitle: 'Pequeño, claro y fácil de seguir.',
              ),
              const SizedBox(height: 16),
              KawaiiCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        maxLength: 60,
                        decoration: const InputDecoration(
                          labelText: '¿Qué haremos?',
                          hintText: 'Ej. Tomar un café y charlar ☕',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Escribe un título corto.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 200,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText: 'Un detalle suave sobre la vibra...',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel(text: 'Categoría'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _CategoryChip(
                            value: 'Coffee',
                            emoji: '☕',
                            selected: _category == 'Coffee',
                            onTap: () => setState(() => _category = 'Coffee'),
                          ),
                          _CategoryChip(
                            value: 'Study',
                            emoji: '📚',
                            selected: _category == 'Study',
                            onTap: () => setState(() => _category = 'Study'),
                          ),
                          _CategoryChip(
                            value: 'Walks',
                            emoji: '🌙',
                            selected: _category == 'Walks',
                            onTap: () => setState(() => _category = 'Walks'),
                          ),
                          _CategoryChip(
                            value: 'Food',
                            emoji: '🍜',
                            selected: _category == 'Food',
                            onTap: () => setState(() => _category = 'Food'),
                          ),
                          _CategoryChip(
                            value: 'Art',
                            emoji: '🎨',
                            selected: _category == 'Art',
                            onTap: () => setState(() => _category = 'Art'),
                          ),
                          _CategoryChip(
                            value: 'Music',
                            emoji: '🎧',
                            selected: _category == 'Music',
                            onTap: () => setState(() => _category = 'Music'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel(text: 'Visibilidad'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _VibeChip(
                            label: 'Pública',
                            selected:
                                _visibility ==
                                ActivityVisibility.publicActivity,
                            onTap: () => setState(
                              () => _visibility =
                                  ActivityVisibility.publicActivity,
                            ),
                          ),
                          _VibeChip(
                            label: 'Privada',
                            selected:
                                _visibility ==
                                ActivityVisibility.privateActivity,
                            onTap: () => setState(
                              () => _visibility =
                                  ActivityVisibility.privateActivity,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel(text: 'Vibe'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _VibeChip(
                            label: 'Calm',
                            selected: _vibe == 'Calm',
                            onTap: () => setState(() => _vibe = 'Calm'),
                          ),
                          _VibeChip(
                            label: 'Social',
                            selected: _vibe == 'Social',
                            onTap: () => setState(() => _vibe = 'Social'),
                          ),
                          _VibeChip(
                            label: 'Chill',
                            selected: _vibe == 'Chill',
                            onTap: () => setState(() => _vibe = 'Chill'),
                          ),
                          _VibeChip(
                            label: 'Creative',
                            selected: _vibe == 'Creative',
                            onTap: () => setState(() => _vibe = 'Creative'),
                          ),
                          _VibeChip(
                            label: 'Productive',
                            selected: _vibe == 'Productive',
                            onTap: () => setState(() => _vibe = 'Productive'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel(text: '¿Cuántas personas?'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RoundStepButton(
                            icon: Icons.remove_rounded,
                            onTap: _maxPeople > 2
                                ? () => setState(() => _maxPeople -= 1)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 220;
                                final pill = StatusPill(
                                  label: _maxPeople <= 4
                                      ? 'Íntimo'
                                      : _maxPeople <= 6
                                      ? 'Suave'
                                      : 'Social',
                                  icon: '✨',
                                  color: Colors.pinkAccent,
                                );
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: YnotTheme.surface2.withValues(
                                      alpha: 0.96,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: YnotTheme.border),
                                  ),
                                  child: compact
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Hasta $_maxPeople personas',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: pill,
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Hasta $_maxPeople personas',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment:
                                                    Alignment.centerRight,
                                                child: pill,
                                              ),
                                            ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          _RoundStepButton(
                            icon: Icons.add_rounded,
                            onTap: _maxPeople < 10
                                ? () => setState(() => _maxPeople += 1)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel(text: '¿Cuándo?'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (date == null || !context.mounted) return;

                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_startTime),
                          );
                          if (time == null || !context.mounted) return;

                          setState(() {
                            _startTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        child: Text(
                          formatTimeRange(
                            _startTime,
                            _startTime.add(_duration),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DurationChip(
                            label: '30 min',
                            selected: _duration.inMinutes == 30,
                            onTap: () => setState(
                              () => _duration = const Duration(minutes: 30),
                            ),
                          ),
                          _DurationChip(
                            label: '1 h',
                            selected: _duration.inMinutes == 60,
                            onTap: () => setState(
                              () => _duration = const Duration(hours: 1),
                            ),
                          ),
                          _DurationChip(
                            label: '1.5 h',
                            selected: _duration.inMinutes == 90,
                            onTap: () => setState(
                              () => _duration = const Duration(minutes: 90),
                            ),
                          ),
                          _DurationChip(
                            label: '2 h',
                            selected: _duration.inMinutes == 120,
                            onTap: () => setState(
                              () => _duration = const Duration(hours: 2),
                            ),
                          ),
                          _DurationChip(
                            label: '3 h',
                            selected: _duration.inMinutes == 180,
                            onTap: () => setState(
                              () => _duration = const Duration(hours: 3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Duración: ${formatDurationLabel(_duration)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _SectionLabel(text: 'Ubicación'),
                      const SizedBox(height: 10),
                      KawaiiCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: YnotTheme.surface2.withValues(
                                      alpha: 0.92,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: YnotTheme.border),
                                  ),
                                  child: Icon(
                                    Icons.place_rounded,
                                    color: YnotTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        selectedLocationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'La ubicación exacta sólo se muestra a participantes confirmados cerca del horario.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.tonal(
                                onPressed: () async {
                                  final picked = await context.push<LatLng?>(
                                    '/location-picker',
                                    extra: LatLng(_lat, _lng),
                                  );
                                  if (!context.mounted || picked == null) {
                                    return;
                                  }
                                  setState(() {
                                    _lat = picked.latitude;
                                    _lng = picked.longitude;
                                    _zone = _zoneFromLocation(
                                      picked.latitude,
                                      picked.longitude,
                                    );
                                  });
                                },
                                child: const Text('Elegir en mapa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (creationBlockMessage != null) ...[
                        const SizedBox(height: 12),
                        KawaiiCard(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            creationBlockMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: canCreateActivity
                            ? () async {
                                await _handleSubmit(context, controller);
                              }
                            : null,
                        child: Text(submitLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _zoneFromLocation(double lat, double lng) {
    if (lat >= 37.56 && lng < 126.95) {
      return 'Hongdae';
    }
    if (lat >= 37.54 && lng >= 126.95 && lng < 126.99) {
      return 'Yeouido';
    }
    if (lng >= 126.99) {
      return 'Gangnam';
    }
    if (lat >= 37.56) {
      return 'Seoul';
    }
    return 'Seoul';
  }

  Future<void> _handleSubmit(
    BuildContext context,
    AppController controller,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = _isEditing;
    final combinedText =
        '${_titleController.text.trim()}\n${_descriptionController.text.trim()}';
    final matches = controller.moderationMatchesForText(combinedText);
    if (matches.isNotEmpty) {
      final proceed = await showModerationWarningDialog(context);
      if (!proceed || !context.mounted) {
        return;
      }
    }

    if (isEditing) {
      if (matches.isNotEmpty) {
        controller.logModerationWarningConfirmed(
          sourceType: ModerationFlagSourceType.activity,
          activityId: widget.editingActivity!.id,
          match: matches.first,
        );
      }
      final updated = await controller.updateActivity(
        activityId: widget.editingActivity!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        vibe: _vibe,
        zone: _zone,
        startTime: _startTime,
        duration: _duration,
        maxPeople: _maxPeople,
        realLat: _lat,
        realLng: _lng,
        visibility: _visibility,
      );
      if (!context.mounted) return;
      if (updated) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos guardar los cambios.')),
        );
      }
      return;
    }

    final pendingActivityId = 'activity_${DateTime.now().millisecondsSinceEpoch}';
    if (matches.isNotEmpty) {
      controller.logModerationWarningConfirmed(
        sourceType: ModerationFlagSourceType.activity,
        activityId: pendingActivityId,
        match: matches.first,
      );
    }

    await controller.createActivity(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      vibe: _vibe,
      zone: _zone,
      startTime: _startTime,
      duration: _duration,
      maxPeople: _maxPeople,
      realLat: _lat,
      realLng: _lng,
      visibility: _visibility,
      activityId: pendingActivityId,
    );

    if (!context.mounted) return;
    context.pop();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.value,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Text(emoji),
      label: Text(value),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null
              ? YnotTheme.surface2.withValues(alpha: 0.84)
              : YnotTheme.surface2.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: YnotTheme.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null
              ? YnotTheme.mutedText.withValues(alpha: 0.65)
              : Colors.white,
        ),
      ),
    );
  }
}
