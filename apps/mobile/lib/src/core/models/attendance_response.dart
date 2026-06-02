enum AttendanceResponse {
  attended,
  noShow,
  unknown,
}

extension AttendanceResponseX on AttendanceResponse {
  String get label => switch (this) {
    AttendanceResponse.attended => 'Sí, asistí',
    AttendanceResponse.noShow => 'No pude ir',
    AttendanceResponse.unknown => 'Prefiero no decir',
  };

  String get shortLabel => switch (this) {
    AttendanceResponse.attended => 'Asistí',
    AttendanceResponse.noShow => 'No pude ir',
    AttendanceResponse.unknown => 'Prefiero no decir',
  };

  String get storageValue => name;
}

