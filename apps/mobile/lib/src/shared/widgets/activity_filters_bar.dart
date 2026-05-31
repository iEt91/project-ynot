import 'package:flutter/material.dart';

import '../../core/models/activity_filters.dart';
import '../../app/theme.dart';
import 'kawaii_card.dart';

class ActivityFiltersBar extends StatelessWidget {
  const ActivityFiltersBar({
    super.key,
    required this.filters,
    required this.onToggleToday,
    required this.onTimeSlotSelected,
    required this.onCategoryToggled,
    required this.onPeopleRangeSelected,
    required this.onClear,
  });

  final ActivityDiscoveryFilters filters;
  final VoidCallback onToggleToday;
  final ValueChanged<ActivityTimeSlot?> onTimeSlotSelected;
  final ValueChanged<String> onCategoryToggled;
  final ValueChanged<ActivityPeopleRange?> onPeopleRangeSelected;
  final VoidCallback onClear;

  static const _categories = <String, String>{
    'Coffee': 'Café',
    'Study': 'Estudio',
    'Walks': 'Paseo',
    'Art': 'Arte',
    'Food': 'Comida',
    'Music': 'Música',
  };

  static const _timeSlots = <ActivityTimeSlot, String>{
    ActivityTimeSlot.morning: 'Mañana',
    ActivityTimeSlot.afternoon: 'Tarde',
    ActivityTimeSlot.night: 'Noche',
  };

  static const _peopleRanges = <ActivityPeopleRange, String>{
    ActivityPeopleRange.twoToFour: '2-4',
    ActivityPeopleRange.fiveToEight: '5-8',
    ActivityPeopleRange.ninePlus: '9+',
  };

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (!filters.isEmpty)
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  child: const Text('Limpiar filtros'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _SectionLabel(text: 'Hoy'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _KawaiiFilterChip(
                label: 'Hoy',
                selected: filters.today,
                onSelected: () => onToggleToday(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionLabel(text: 'Horario'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.entries.map((entry) {
              return _KawaiiFilterChip(
                label: entry.value,
                selected: filters.timeSlot == entry.key,
                onSelected: () {
                  onTimeSlotSelected(
                    filters.timeSlot == entry.key ? null : entry.key,
                  );
                },
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          _SectionLabel(text: 'Tipo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.entries.map((entry) {
              return _KawaiiFilterChip(
                label: entry.value,
                selected: filters.categories.contains(entry.key),
                onSelected: () => onCategoryToggled(entry.key),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          _SectionLabel(text: 'Personas'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _peopleRanges.entries.map((entry) {
              return _KawaiiFilterChip(
                label: entry.value,
                selected: filters.peopleRange == entry.key,
                onSelected: () {
                  onPeopleRangeSelected(
                    filters.peopleRange == entry.key ? null : entry.key,
                  );
                },
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: YnotTheme.mutedText,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
    );
  }
}

class _KawaiiFilterChip extends StatelessWidget {
  const _KawaiiFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      side: BorderSide(
        color: selected ? YnotTheme.primary : YnotTheme.border,
      ),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : Colors.white70,
          ),
      selectedColor: YnotTheme.primary.withValues(alpha: 0.22),
      backgroundColor: YnotTheme.surface.withValues(alpha: 0.56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
