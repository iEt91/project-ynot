enum ActivityTimeSlot { morning, afternoon, night }

enum ActivityPeopleRange { twoToFour, fiveToEight, ninePlus }

class ActivityDiscoveryFilters {
  static const _unset = Object();

  const ActivityDiscoveryFilters({
    required this.today,
    required this.timeSlot,
    required this.categories,
    required this.peopleRange,
    required this.searchQuery,
  });

  factory ActivityDiscoveryFilters.initial() {
    return const ActivityDiscoveryFilters(
      today: false,
      timeSlot: null,
      categories: <String>{},
      peopleRange: null,
      searchQuery: '',
    );
  }

  final bool today;
  final ActivityTimeSlot? timeSlot;
  final Set<String> categories;
  final ActivityPeopleRange? peopleRange;
  final String searchQuery;

  bool get isEmpty =>
      !today &&
      timeSlot == null &&
      categories.isEmpty &&
      peopleRange == null &&
      searchQuery.trim().isEmpty;

  ActivityDiscoveryFilters copyWith({
    bool? today,
    Object? timeSlot = _unset,
    Set<String>? categories,
    Object? peopleRange = _unset,
    Object? searchQuery = _unset,
  }) {
    return ActivityDiscoveryFilters(
      today: today ?? this.today,
      timeSlot: timeSlot == _unset ? this.timeSlot : timeSlot as ActivityTimeSlot?,
      categories: categories ?? this.categories,
      peopleRange:
          peopleRange == _unset ? this.peopleRange : peopleRange as ActivityPeopleRange?,
      searchQuery:
          searchQuery == _unset ? this.searchQuery : searchQuery as String,
    );
  }

  ActivityDiscoveryFilters toggleCategory(String category) {
    final next = Set<String>.from(categories);
    if (next.contains(category)) {
      next.remove(category);
    } else {
      next.add(category);
    }
    return copyWith(categories: next);
  }

  ActivityDiscoveryFilters clear() {
    return ActivityDiscoveryFilters.initial();
  }

  Map<String, dynamic> toJson() {
    return {
      'today': today,
      'timeSlot': timeSlot?.name,
      'categories': categories.toList(growable: false),
      'peopleRange': peopleRange?.name,
      'searchQuery': searchQuery,
    };
  }

  factory ActivityDiscoveryFilters.fromJson(Map<String, dynamic> json) {
    final categories = (json['categories'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet();
    return ActivityDiscoveryFilters(
      today: json['today'] as bool? ?? false,
      timeSlot: _timeSlotFromName(json['timeSlot'] as String?),
      categories: categories,
      peopleRange: _peopleRangeFromName(json['peopleRange'] as String?),
      searchQuery: json['searchQuery'] as String? ?? '',
    );
  }
}

ActivityTimeSlot? _timeSlotFromName(String? name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  return ActivityTimeSlot.values.byName(name);
}

ActivityPeopleRange? _peopleRangeFromName(String? name) {
  if (name == null || name.isEmpty) {
    return null;
  }
  return ActivityPeopleRange.values.byName(name);
}
