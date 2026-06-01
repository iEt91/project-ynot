import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../profile/presentation/profile_back_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
            children: [
              Row(
                children: [
                  ProfileBackButton(onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: 14),
              const SectionHeader(
                title: 'Configuración',
                subtitle: 'Ajustes simples, locales y privados.',
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Cuenta',
                children: [
                  _ActionRow(
                    label: 'Editar perfil',
                    onTap: () => context.push('/edit-profile'),
                  ),
                  const SizedBox(height: 10),
                  _ActionRow(
                    label: 'Usuarios bloqueados',
                    value: '${state.blockedUsers.length}',
                    onTap: () => context.push('/settings/blocked-users'),
                  ),
                  const SizedBox(height: 10),
                  _ActionRow(
                    label: 'Cerrar sesión',
                    onTap: () {
                      controller.signOut();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                    danger: true,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Datos locales',
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      final count = await controller.loadDemoActivities();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            count > 0
                                ? 'Se cargaron $count actividades demo.'
                                : 'Los datos demo ya estaban cargados.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Cargar datos demo'),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.20),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final confirmed = await _confirmClearData(context);
                      if (!confirmed || !context.mounted) return;
                      await controller.clearLocalData();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                    child: const Text('Borrar datos locales'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Seguridad',
                children: [
                  _ActionRow(
                    label: 'Reportes enviados',
                    value: '${state.reports.length}',
                    onTap: () => context.push('/settings/reports'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tus reportes son privados y ayudan a mantener la comunidad segura.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Acerca de',
                children: const [
                  _InfoRow(label: 'Versión actual', value: kAppVisibleVersion),
                  SizedBox(height: 12),
                  _InfoRow(label: 'Modo actual', value: 'Mock/local'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmClearData(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: YnotTheme.surface2,
          title: const Text('¿Borrar datos locales?'),
          content: const Text(
            'Esto eliminará actividades, chats, guardadas, feedback, reportes y la sesión local. No se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: YnotTheme.surface2.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: YnotTheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: danger ? Colors.redAccent : null,
                      ),
                ),
              ),
              if (value != null && value!.isNotEmpty) ...[
                Text(
                  value!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: danger
                            ? Colors.redAccent
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
