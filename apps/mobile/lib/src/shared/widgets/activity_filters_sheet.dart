import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/state/app_controller.dart';
import 'app_screen_header.dart';
import 'activity_filters_bar.dart';
import 'kawaii_card.dart';

class ActivityFiltersHeaderButton extends StatelessWidget {
  const ActivityFiltersHeaderButton({
    super.key,
    required this.onPressed,
    this.active = false,
  });

  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return HeaderIconButton(
      icon: Icons.tune_rounded,
      onTap: onPressed,
      active: active,
      hasDot: active,
    );
  }
}

Future<void> showActivityFiltersSheet(
  BuildContext context, {
  VoidCallback? onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(appStateProvider);
          final controller = ref.read(appControllerProvider);

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.92,
                  child: KawaiiCard(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.78,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'FILTROS',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: 'Cerrar',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ActivityFiltersBar(
                              filters: state.activityFilters,
                              showCard: false,
                              showHeader: false,
                              showClearButton: false,
                              onToggleToday: () {
                                controller.toggleTodayFilter();
                                onChanged?.call();
                              },
                              onTimeSlotSelected: (timeSlot) {
                                controller.setTimeSlotFilter(timeSlot);
                                onChanged?.call();
                              },
                              onCategoryToggled: (category) {
                                controller.toggleCategoryFilter(category);
                                onChanged?.call();
                              },
                              onPeopleRangeSelected: (range) {
                                controller.setPeopleRangeFilter(range);
                                onChanged?.call();
                              },
                              onClear: () {
                                controller.clearActivityFilters();
                                onChanged?.call();
                              },
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      controller.clearActivityFilters();
                                      onChanged?.call();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: YnotTheme.border,
                                      ),
                                      foregroundColor: Colors.white70,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text('Limpiar filtros'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () =>
                                        Navigator.of(sheetContext).pop(),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: YnotTheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text('Aplicar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
