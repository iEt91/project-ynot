import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/activity.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/google_maps_support.dart';
import '../../../shared/widgets/google_activity_map.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key, this.initialLocation});

  final LatLng? initialLocation;

  @override
  ConsumerState<CreateActivityScreen> createState() => _CreateActivityScreenState();
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
  bool _useMapSelection = false;

  @override
  void initState() {
    super.initState();
    final location = widget.initialLocation;
    if (location != null) {
      _lat = location.latitude;
      _lng = location.longitude;
      _zone = _zoneFromLocation(location.latitude, location.longitude);
      _useMapSelection = true;
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
    final theme = Theme.of(context);

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
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
                      'Crear actividad',
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
                      _SectionLabel(text: 'Categoría'),
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
                            emoji: '🎵',
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
                            label: 'Pública',
                            selected: _visibility == ActivityVisibility.publicActivity,
                            onTap: () => setState(() => _visibility = ActivityVisibility.publicActivity),
                          ),
                          _VibeChip(
                            label: 'Privada',
                            selected: _visibility == ActivityVisibility.privateActivity,
                            onTap: () => setState(() => _visibility = ActivityVisibility.privateActivity),
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
                      _SectionLabel(text: '¿Cuántas personas?'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RoundStepButton(
                            icon: Icons.remove_rounded,
                            onTap: _maxPeople > 2 ? () => setState(() => _maxPeople -= 1) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 220;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: compact
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hasta $_maxPeople personas',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: StatusPill(
                                                label: _maxPeople <= 4 ? 'Íntimo' : _maxPeople <= 6 ? 'Suave' : 'Social',
                                                icon: '👥',
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
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerRight,
                                                child: StatusPill(
                                                  label: _maxPeople <= 4 ? 'Íntimo' : _maxPeople <= 6 ? 'Suave' : 'Social',
                                                  icon: '👥',
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
                            onTap: _maxPeople < 10 ? () => setState(() => _maxPeople += 1) : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SectionLabel(text: '¿Cuándo?'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startTime,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
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
                        child: Text(formatTimeRange(_startTime, _startTime.add(_duration))),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DurationChip(
                            label: '30 min',
                            selected: _duration.inMinutes == 30,
                            onTap: () => setState(() => _duration = const Duration(minutes: 30)),
                          ),
                          _DurationChip(
                            label: '1 h',
                            selected: _duration.inMinutes == 60,
                            onTap: () => setState(() => _duration = const Duration(hours: 1)),
                          ),
                          _DurationChip(
                            label: '1.5 h',
                            selected: _duration.inMinutes == 90,
                            onTap: () => setState(() => _duration = const Duration(minutes: 90)),
                          ),
                          _DurationChip(
                            label: '2 h',
                            selected: _duration.inMinutes == 120,
                            onTap: () => setState(() => _duration = const Duration(hours: 2)),
                          ),
                          _DurationChip(
                            label: '3 h',
                            selected: _duration.inMinutes == 180,
                            onTap: () => setState(() => _duration = const Duration(hours: 3)),
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
                      _SectionLabel(text: '¿Dónde?'),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _useMapSelection,
                        onChanged: (value) => setState(() => _useMapSelection = value),
                        title: const Text('Elegir en mapa'),
                        subtitle: const Text('Mantén presionado para mover el punto.'),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 250,
                        child: _useMapSelection && canUseGoogleMaps()
                            ? _MapPicker(
                                selectedLocation: LatLng(_lat, _lng),
                                onChanged: (lat, lng) {
                                  setState(() {
                                    _lat = lat;
                                    _lng = lng;
                                  });
                                },
                                onCameraChanged: (lat, lng) {
                                  setState(() {
                                    _lat = lat;
                                    _lng = lng;
                                    _zone = _zoneFromLocation(lat, lng);
                                  });
                                },
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
                        'Se mostrará una ubicación aproximada por seguridad.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
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
                          );

                          if (!context.mounted) return;
                          context.pop();
                        },
                        child: const Text('Publicar actividad'),
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
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
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
  const _RoundStepButton({
    required this.icon,
    required this.onTap,
  });

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
          color: onTap == null ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? Colors.white.withValues(alpha: 0.3) : Colors.white,
        ),
      ),
    );
  }
}

class _StaticZonePicker extends StatelessWidget {
  const _StaticZonePicker({
    required this.zone,
    required this.onSelected,
  });

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
            ...zones.entries.map((entry) {
              final index = zones.keys.toList().indexOf(entry.key);
              final left = 20.0 + (index % 2) * 132;
              final top = 18.0 + (index ~/ 2) * 58;
              final selectedZone = zone == entry.key;
              return Positioned(
                left: left,
                top: top,
                child: GestureDetector(
                  onTap: () => onSelected(entry.key, entry.value.lat, entry.value.lng),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectedZone
                          ? Colors.pinkAccent.withValues(alpha: 0.26)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selectedZone ? Colors.pinkAccent : Colors.white.withValues(alpha: 0.12),
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
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MapPicker extends StatelessWidget {
  const _MapPicker({
    required this.onChanged,
    required this.selectedLocation,
    required this.onCameraChanged,
  });

  final void Function(double lat, double lng) onChanged;
  final LatLng selectedLocation;
  final void Function(double lat, double lng) onCameraChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GoogleActivityMap(
        activities: const [],
        interactive: true,
        selectedLocation: selectedLocation,
        animateToSelectedLocation: false,
        onLocationSelected: (position) {
          onChanged(position.latitude, position.longitude);
        },
        onCameraPositionChanged: (position) {
          onCameraChanged(position.latitude, position.longitude);
        },
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
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

class _CityGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
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
