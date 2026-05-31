import 'package:flutter/material.dart';

class ActivitySearchField extends StatefulWidget {
  const ActivitySearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.onDismiss,
    this.autofocus = false,
    this.onClear,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onDismiss;
  final bool autofocus;

  @override
  State<ActivitySearchField> createState() => _ActivitySearchFieldState();
}

class _ActivitySearchFieldState extends State<ActivitySearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  late final FocusNode _focusNode = FocusNode()..addListener(_handleFocus);

  bool _isFocused = false;

  void _handleFocus() {
    if (!mounted) {
      return;
    }
    final focused = _focusNode.hasFocus;
    if (_isFocused != focused) {
      setState(() {
        _isFocused = focused;
      });
    }
  }

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
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    final borderColor = _isFocused || hasText
        ? const Color(0xFFFF5DB8).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                autofocus: widget.autofocus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Buscar actividad...',
                  hintStyle: TextStyle(color: Colors.white54),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (_controller.text.trim().isEmpty) {
                  widget.onDismiss?.call();
                  return;
                }
                _controller.clear();
                widget.onClear?.call();
                widget.onChanged('');
              },
              icon: const Icon(Icons.close_rounded),
              color: Colors.white70,
              tooltip: hasText ? 'Limpiar búsqueda' : 'Cerrar',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
    );
  }
}
