import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme.dart';
import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/google_maps_support.dart';
import '../../../shared/widgets/google_activity_map.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class ActivityFormSeed {
  const ActivityFormSeed({this.initialLocation, this.activity});

  final LatLng? initialLocation;
  final Activity? activity;
}

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({
    super.key,
    this.initialLocation,
    this.editingActivity,
  });

  final LatLng? initialLocation;
  final Activity? editingActivity;

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
    final activity = widget.editingActivity;
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
      return;
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

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            children: [
              Row(
                children: [
                  _RoundIcon(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.pop(),
                  ),
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
                  _RoundIcon(
                    icon: Icons.close_rounded,
                    onTap: () => context.pop(),
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
                      _SectionLabel(text: 'Categor?a'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _CategoryChip(
                            value: 'Coffee',
                            emoji: '?',
                            selected: _category == 'Coffee',
                            onTap: () => setState(() => _category = 'Coffee'),
                          ),
                          _CategoryChip(
                            value: 'Study',
                            emoji: '??',
                            selected: _category == 'Study',
                            onTap: () => setState(() => _category = 'Study'),
                          ),
                          _CategoryChip(
                            value: 'Walks',
                            emoji: '??',
                            selected: _category == 'Walks',
                            onTap: () => setState(() => _category = 'Walks'),
                          ),
                          _CategoryChip(
                            value: 'Food',
                            emoji: '??',
                            selected: _category == 'Food',
                            onTap: () => setState(() => _category = 'Food'),
                          ),
                          _CategoryChip(
                            value: 'Art',
                            emoji: '??',
                            selected: _category == 'Art',
                            onTap: () => setState(() => _category = 'Art'),
                          ),
                          _CategoryChip(
                            value: 'Music',
                            emoji: '??',
                            selected: _category == 'Music',
                            onTap: () => setState(() => _category = 'Music'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionLabel(text: 'Visibilidad'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _VibeChip(
                            label: 'P?blica',
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
                      _SectionLabel(text: 'Vibe'),
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
                      _SectionLabel(text: '?Cu?ntas personas?'),
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
                                              child: StatusPill(
                                                label: _maxPeople <= 4
                                                    ? '?ntimo'
                                                    : _maxPeople <= 6
                                                    ? 'Suave'
                                                    : 'Social',
                                                icon: '??',
                                                color: Colors.pinkAccent,
                                              ),
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
                                                child: StatusPill(
                                                  label: _maxPeople <= 4
                                                      ? '?ntimo'
                                                      : _maxPeople <= 6
                                                      ? 'Suave'
                                                      : 'Social',
                                                  icon: '??',
                                                  color: Colors.pinkAccent,
                                                ),
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
                      _SectionLabel(text: '?Cu?ndo?'),
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
                        'Duraci?n: ${formatDurationLabel(_duration)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionLabel(text: '?D?nde?'),
                      const SizedBox(height: 8),
                      Text(
                        'Mueve el mapa para elegir el punto.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 250,
                        child: canUseGoogleMaps()
                            ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned.fill(
                                    child: _MapPicker(
                                      initialLocation: LatLng(_lat, _lng),
                                      onCameraIdleChanged: (lat, lng) {
                                        setState(() {
                                          _lat = lat;
                                          _lng = lng;
                                          _zone = _zoneFromLocation(lat, lng);
                                        });
                                      },
                                    ),
                                  ),
                                  IgnorePointer(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.place_rounded,
                                          size: 44,
                                          color: YnotTheme.primary,
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: YnotTheme.primary,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: YnotTheme.primary
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 18,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : _StaticZonePicker(
                                zone: _zone,
                                onSelected: (zone, lat, lng) {
                                  setState(() {
                                    _zone = zone;
                                    _lat = lat;
                                    _lng = lng;
                                  });
                                },
                              ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Se mostrar? una ubicaci?n aproximada por seguridad.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                if (_isEditing) {
                                  final updated = await controller
                                      .updateActivity(
                                        activityId: widget.editingActivity!.id,
                                        title: _titleController.text.trim(),
                                        description: _descriptionController.text
                                            .trim(),
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
                                      const SnackBar(
                                        content: Text(
                                          'No pudimos guardar los cambios.',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                await controller.createActivity(
                                  title: _titleController.text.trim(),
                                  description: _descriptionController.text
                                      .trim(),
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
                                context.pop();
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

class _StaticZonePicker extends StatelessWidget {
  const _StaticZonePicker({required this.zone, required this.onSelected});

  final String zone;
  final void Function(String zone, double lat, double lng) onSelected;

  @override
  Widget build(BuildContext context) {
    final zones = <String, ({double lat, double lng, String emoji})>{
      'Hongdae': (lat: 37.5563, lng: 126.9228, emoji: '☕'),
      'Gangnam': (lat: 37.4981, lng: 127.0276, emoji: '✨'),
      'Yeouido': (lat: 37.5219, lng: 126.9141, emoji: '🌙'),
      'Insadong': (lat: 37.5744, lng: 126.9838, emoji: '🎨'),
      'Myeongdong': (lat: 37.5636, lng: 126.9826, emoji: '🍜'),
    };

    return KawaiiCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1224), Color(0xFF050810)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CityGridPainter())),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: zones.entries
                      .map((entry) {
                        final selectedZone = zone == entry.key;
                        return GestureDetector(
                          onTap: () => onSelected(
                            entry.key,
                            entry.value.lat,
                            entry.value.lng,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selectedZone
                                  ? Colors.pinkAccent.withValues(alpha: 0.26)
                                  : YnotTheme.surface2.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selectedZone
                                    ? Colors.pinkAccent
                                    : YnotTheme.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(entry.value.emoji),
                                const SizedBox(width: 6),
                                Text(entry.key),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPicker extends StatelessWidget {
  const _MapPicker({
    required this.initialLocation,
    required this.onCameraIdleChanged,
  });

  final LatLng initialLocation;
  final void Function(double lat, double lng) onCameraIdleChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GoogleActivityMap(
        activities: const [],
        interactive: true,
        initialCameraPosition: CameraPosition(
          target: initialLocation,
          zoom: 14.5,
          bearing: 0,
          tilt: 0,
        ),
        onCameraIdlePositionChanged: (position) {
          onCameraIdleChanged(position.latitude, position.longitude);
        },
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

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
          color: YnotTheme.surface2.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(color: YnotTheme.border),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

class _CityGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = YnotTheme.purple.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (var i = 0; i < 6; i++) {
      final y = size.height / 6 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (var i = 0; i < 6; i++) {
      final x = size.width / 6 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
