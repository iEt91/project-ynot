import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/section_header.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'Coffee';
  String _vibe = 'Calm';
  String _zone = 'Hongdae area';
  int _maxPeople = 4;
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  Duration _duration = const Duration(hours: 2);
  double _lat = 37.5563;
  double _lng = 126.9228;
  bool _useMapSelection = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create activity'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                title: 'New activity',
                subtitle: 'Create a small public moment with a clear vibe.',
              ),
              const SizedBox(height: 14),
              KawaiiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: '☕ Café & Talk',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Add a title.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLength: 200,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Short note about the vibe...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LabelledChoice(
                      label: 'Category',
                      child: _ChoiceRow<String>(
                        value: _category,
                        options: const ['Coffee', 'Study', 'Walks', 'Food', 'Art', 'Music'],
                        onChanged: (value) => setState(() => _category = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LabelledChoice(
                      label: 'Vibe',
                      child: _ChoiceRow<String>(
                        value: _vibe,
                        options: const ['Calm', 'Social', 'Chill', 'Creative', 'Productive'],
                        onChanged: (value) => setState(() => _vibe = value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LabelledChoice(
                      label: 'Group size',
                      child: Slider(
                        min: 2,
                        max: 10,
                        divisions: 8,
                        value: _maxPeople.toDouble(),
                        label: '$_maxPeople',
                        onChanged: (value) => setState(() => _maxPeople = value.round()),
                      ),
                    ),
                    Text('Max people: $_maxPeople'),
                    const SizedBox(height: 12),
                    _LabelledChoice(
                      label: 'When',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.tonal(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startTime,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (date == null) return;
                              if (!context.mounted) {
                                return;
                              }
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_startTime),
                              );
                              if (time == null) return;
                              if (!context.mounted) {
                                return;
                              }

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
                          Slider(
                            min: 30,
                            max: 240,
                            divisions: 7,
                            value: _duration.inMinutes.toDouble(),
                            label: formatDurationLabel(_duration),
                            onChanged: (value) {
                              setState(() {
                                _duration = Duration(minutes: value.round());
                              });
                            },
                          ),
                          Text('Duration: ${formatDurationLabel(_duration)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LabelledChoice(
                      label: 'Location',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SwitchListTile(
                            value: _useMapSelection,
                            onChanged: (value) => setState(() => _useMapSelection = value),
                            title: const Text('Pick on map'),
                            subtitle: const Text('Long-press on the map to set the point.'),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 260,
                          child: _useMapSelection &&
                                  !kIsWeb &&
                                  (defaultTargetPlatform == TargetPlatform.android ||
                                      defaultTargetPlatform == TargetPlatform.iOS)
                                ? _MapPicker(
                                    onChanged: (lat, lng) {
                                      setState(() {
                                        _lat = lat;
                                        _lng = lng;
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        controller.createActivity(
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
                        );

                        if (!context.mounted) {
                          return;
                        }
                        context.pop();
                      },
                      child: const Text('Create activity'),
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

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map(
            (option) => ChoiceChip(
              label: Text(option.toString()),
              selected: value == option,
              onSelected: (_) => onChanged(option),
            ),
          )
          .toList(),
    );
  }
}

class _LabelledChoice extends StatelessWidget {
  const _LabelledChoice({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        child,
      ],
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
    final zones = <String, ({double lat, double lng})>{
      'Hongdae area': (lat: 37.5563, lng: 126.9228),
      'Gangnam': (lat: 37.4981, lng: 127.0276),
      'Yeouido': (lat: 37.5219, lng: 126.9141),
      'Insadong': (lat: 37.5744, lng: 126.9838),
      'Myeongdong': (lat: 37.5636, lng: 126.9826),
    };

    return KawaiiCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10203A), Color(0xFF070B14)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: zones.entries.map((entry) {
                  final normalized = zones.keys.toList().indexOf(entry.key);
                  final left = 28.0 + (normalized % 2) * 130;
                  final top = 24.0 + (normalized ~/ 2) * 56;
                  return Positioned(
                    left: left,
                    top: top,
                    child: GestureDetector(
                      onTap: () => onSelected(entry.key, entry.value.lat, entry.value.lng),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: zone == entry.key
                              ? Colors.pinkAccent.withValues(alpha: 0.28)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: zone == entry.key
                                ? Colors.pinkAccent
                                : Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(entry.key),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Selected: $zone',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPicker extends StatefulWidget {
  const _MapPicker({required this.onChanged});

  final void Function(double lat, double lng) onChanged;

  @override
  State<_MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<_MapPicker> {
  @override
  Widget build(BuildContext context) {
    return NaverMap(
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5666, 126.9780),
          zoom: 13,
        ),
      ),
      onMapReady: (_) {},
      onMapLongTapped: (point, latLng) {
        widget.onChanged(latLng.latitude, latLng.longitude);
      },
    );
  }
}
