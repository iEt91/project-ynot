import 'package:flutter/material.dart';

import 'kawaii_card.dart';

class ActivitySearchField extends StatefulWidget {
  const ActivitySearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.onClear,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  State<ActivitySearchField> createState() => _ActivitySearchFieldState();
}

class _ActivitySearchFieldState extends State<ActivitySearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant ActivitySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) {
      return;
    }
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return KawaiiCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Buscar actividad...',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          if (hasText)
            IconButton(
              onPressed: () {
                _controller.clear();
                widget.onClear?.call();
                widget.onChanged('');
              },
              icon: const Icon(Icons.close_rounded),
              color: Colors.white70,
              tooltip: 'Limpiar búsqueda',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
