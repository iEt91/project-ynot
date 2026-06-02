import 'package:flutter/material.dart';

import '../../core/models/pre_activity_checklist.dart';
import '../../app/theme.dart';
import 'kawaii_card.dart';
import 'status_pill.dart';

class PreActivityChecklistCard extends StatefulWidget {
  const PreActivityChecklistCard({
    super.key,
    required this.checkedItemIds,
    required this.onToggleItem,
    required this.onCompleteAll,
  });

  final List<String> checkedItemIds;
  final ValueChanged<String> onToggleItem;
  final VoidCallback onCompleteAll;

  @override
  State<PreActivityChecklistCard> createState() =>
      _PreActivityChecklistCardState();
}

class _PreActivityChecklistCardState extends State<PreActivityChecklistCard> {
  late bool _expanded;
  late bool _wasComplete;

  bool get _isComplete =>
      preActivityChecklistItems.every(
        (item) => widget.checkedItemIds.contains(item.id),
      );

  @override
  void initState() {
    super.initState();
    _wasComplete = _isComplete;
    _expanded = !_isComplete;
  }

  @override
  void didUpdateWidget(covariant PreActivityChecklistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentComplete = _isComplete;
    if (!currentComplete) {
      _expanded = true;
    } else if (!_wasComplete && currentComplete) {
      _expanded = false;
    }
    _wasComplete = currentComplete;
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete && !_expanded) {
      return KawaiiCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _expanded = true),
          child: Row(
            children: [
              const StatusPill(
                label: 'Todo listo para la actividad',
                color: YnotTheme.mint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Toca para revisar el checklist.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.expand_more_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      );
    }

    return KawaiiCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Checklist previo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (_isComplete)
                TextButton(
                  onPressed: () => setState(() => _expanded = false),
                  child: const Text('Contraer'),
                )
              else
                TextButton(
                  onPressed: widget.onCompleteAll,
                  child: const Text('Todo listo'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in preActivityChecklistItems) ...[
                _ChecklistRow(
                  label: item.label,
                  icon: item.icon,
                  checked: widget.checkedItemIds.contains(item.id),
                  onTap: () => widget.onToggleItem(item.id),
                ),
                if (item != preActivityChecklistItems.last)
                  const SizedBox(height: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.icon,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: checked
              ? YnotTheme.surface2.withValues(alpha: 0.75)
              : YnotTheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: YnotTheme.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Icon(icon, size: 18, color: checked ? YnotTheme.mint : Colors.white70),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: checked
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Checkbox(
              value: checked,
              onChanged: (_) => onTap(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: YnotTheme.mint,
              side: const BorderSide(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
