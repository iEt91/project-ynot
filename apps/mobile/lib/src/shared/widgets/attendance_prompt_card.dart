import 'package:flutter/material.dart';

import '../../core/models/attendance_response.dart';
import '../../app/theme.dart';
import 'kawaii_card.dart';

class AttendancePromptCard extends StatefulWidget {
  const AttendancePromptCard({
    super.key,
    required this.onSelected,
    this.compact = false,
  });

  final Future<void> Function(AttendanceResponse response) onSelected;
  final bool compact;

  @override
  State<AttendancePromptCard> createState() => _AttendancePromptCardState();
}

class _AttendancePromptCardState extends State<AttendancePromptCard> {
  bool _saving = false;

  Future<void> _select(AttendanceResponse response) async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSelected(response);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.compact ? 10.0 : 14.0;

    return KawaiiCard(
      padding: EdgeInsets.all(widget.compact ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Asististe a esta actividad?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tu respuesta queda guardada localmente y ayuda a desbloquear feedback.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          SizedBox(height: spacing),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AttendanceResponse.values
                .map(
                  (response) => SizedBox(
                    width: widget.compact ? 132 : 150,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _select(response),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        foregroundColor: Colors.white,
                        backgroundColor: YnotTheme.surface2.withValues(
                          alpha: 0.95,
                        ),
                        side: BorderSide(color: YnotTheme.border),
                      ),
                      child: Text(
                        response.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

