import 'package:flutter/material.dart';

class PreActivityChecklistItem {
  const PreActivityChecklistItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const preActivityChecklistItems = <PreActivityChecklistItem>[
  PreActivityChecklistItem(
    id: 'location',
    label: '📍 Revisar ubicación',
    icon: Icons.place_rounded,
  ),
  PreActivityChecklistItem(
    id: 'time',
    label: '🕒 Confirmar horario',
    icon: Icons.schedule_rounded,
  ),
  PreActivityChecklistItem(
    id: 'attendees',
    label: '👥 Ver asistentes',
    icon: Icons.groups_rounded,
  ),
  PreActivityChecklistItem(
    id: 'chat',
    label: '💬 Leer el chat',
    icon: Icons.chat_bubble_outline_rounded,
  ),
  PreActivityChecklistItem(
    id: 'report',
    label: '⚠️ Reportar si algo se siente raro',
    icon: Icons.report_gmailerrorred_rounded,
  ),
];

