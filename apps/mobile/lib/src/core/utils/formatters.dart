String twoDigits(int value) => value.toString().padLeft(2, '0');

String formatTimeOfDay(DateTime value) {
  return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
}

String formatDateLabel(DateTime value) {
  return '${twoDigits(value.month)}/${twoDigits(value.day)}';
}

String formatTimeRange(DateTime start, DateTime end) {
  return '${formatDateLabel(start)} · ${formatTimeOfDay(start)} - ${formatTimeOfDay(end)}';
}

String formatDurationLabel(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  }
  if (hours > 0) {
    return '${hours}h';
  }
  return '${minutes}m';
}

String maskPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.length <= 4) {
    return digits;
  }

  final last4 = digits.substring(digits.length - 4);
  return '•••• $last4';
}

bool looksBrokenEncoding(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return true;
  }

  return trimmed.contains('Ã') ||
      trimmed.contains('Â') ||
      trimmed.contains('â') ||
      trimmed.contains('ð') ||
      trimmed.contains('Ÿ') ||
      trimmed.contains('œ') ||
      trimmed.contains('™') ||
      trimmed.contains('�');
}

String safeDisplayText(
  String value, {
  required String fallback,
}) {
  return looksBrokenEncoding(value) ? fallback : value.trim();
}

String safePhoneDisplay(
  String value, {
  String fallback = 'Sesión local',
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || looksBrokenEncoding(trimmed)) {
    return fallback;
  }

  if (trimmed.contains('•')) {
    return trimmed;
  }

  final digits = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.length <= 4) {
    return digits.isEmpty ? fallback : digits;
  }

  return maskPhone(trimmed);
}
