import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/models/mock_current_location.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/presentation/profile_back_button.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final settings = state.settings;

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(
                children: [ProfileBackButton(onTap: () => context.pop())],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Preferencias',
                subtitle:
                    'Controla lo que la app muestra y notifica. Todo queda local.',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Notificaciones',
                children: [
                  _PreferenceSwitch(
                    title: 'Recibir notificaciones',
                    subtitle:
                        'Activa o desactiva todas las notificaciones locales.',
                    value: settings.receiveNotifications,
                    onChanged: controller.setReceiveNotifications,
                  ),
                  const SizedBox(height: 12),
                  _PreferenceSwitch(
                    title: 'Notificaciones de chat',
                    subtitle:
                        'Recibe avisos por mensajes nuevos en chats activos.',
                    value: settings.chatMessagesNotifications,
                    onChanged: controller.setChatMessagesNotifications,
                  ),
                  const SizedBox(height: 12),
                  _PreferenceSwitch(
                    title: 'Recordatorios de actividad',
                    subtitle:
                        'Recibe avisos cuando una actividad esté por empezar.',
                    value: settings.activityStartingSoonNotifications,
                    onChanged: controller.setActivityStartingSoonNotifications,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Descubrimiento',
                children: [
                  Text(
                    'Radio de búsqueda',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final radius in const [1, 3, 5, 10, 25])
                        _RadiusChip(
                          label: '$radius km',
                          selected: settings.searchRadiusKm == radius,
                          onTap: () => controller.setSearchRadiusKm(radius),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ubicación de prueba',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sólo para pruebas locales',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in kMockCurrentLocationOptions)
                        _LocationChip(
                          label: option.label,
                          selected:
                              settings.mockCurrentLocationKey == option.key,
                          onTap: () =>
                              controller.setMockCurrentLocationKey(option.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _PreferenceSwitch(
                    title: 'Mostrar recomendaciones',
                    subtitle:
                        'Oculta badges y ayudas de descubrimiento como "Empieza pronto".',
                    value: settings.showRecommendations,
                    onChanged: (value) =>
                        controller.setRecommendedActivitiesNotifications(
                          value,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _PreferenceSwitch(
                    title: 'Mostrar actividades guardadas en destacados',
                    subtitle: 'Mantiene resaltadas tus actividades guardadas.',
                    value: settings.showSavedHighlights,
                    onChanged: controller.setShowSavedHighlights,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Privacidad',
                children: [
                  _PreferenceSwitch(
                    title: 'Mostrar ubicación exacta sólo 10 min antes',
                    subtitle:
                        'Protege la ubicación exacta hasta que se acerque el horario.',
                    value: settings.hidePreciseLocationUntilUnlock,
                    onChanged: controller.setHidePreciseLocationUntilUnlock,
                  ),
                  const SizedBox(height: 12),
                  _PreferenceSwitch(
                    title: 'Permitir recomendaciones personalizadas',
                    subtitle:
                        'Usa tu actividad local para sugerir momentos más afines.',
                    value: settings.personalizedRecommendations,
                    onChanged: controller.setPersonalizedRecommendations,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Chats',
                children: [
                  _PreferenceSwitch(
                    title: 'Mostrar chats archivados',
                    subtitle: 'Oculta o muestra la sección de chats archivados.',
                    value: settings.showArchivedChats,
                    onChanged: controller.setShowArchivedChats,
                  ),
                  const SizedBox(height: 12),
                  _PreferenceSwitch(
                    title: 'Silenciar todos los chats',
                    subtitle:
                        'No recibes notificaciones locales por mensajes nuevos.',
                    value: settings.muteAllChats,
                    onChanged: controller.setMuteAllChats,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return KawaiiCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onChanged(!value),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: YnotTheme.surface2.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: YnotTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: YnotTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: YnotTheme.surface2.withValues(alpha: 0.72),
      selectedColor: YnotTheme.primary.withValues(alpha: 0.22),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : Colors.white70,
      ),
      side: BorderSide(
        color: selected ? YnotTheme.primary : YnotTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: YnotTheme.surface2.withValues(alpha: 0.72),
      selectedColor: YnotTheme.mint.withValues(alpha: 0.2),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? YnotTheme.bg : Colors.white70,
      ),
      side: BorderSide(
        color: selected ? YnotTheme.mint : YnotTheme.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
