import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_avatar.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/kawaii_scene.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_pill.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final controller = ref.read(appControllerProvider);
    final isOtpStep = state.stage == AppStage.otpEntry;

    if (_phoneController.text != state.phoneInput) {
      _phoneController.text = state.phoneInput;
    }
    if (_codeController.text != state.verificationInput) {
      _codeController.text = state.verificationInput;
    }

    return Scaffold(
      body: KawaiiScene(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const SizedBox(height: 18),
                  KawaiiCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('whynot?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 12),
                            KawaiiAvatar(
                              emoji: '🐱',
                              size: 44,
                              accentColor: YnotTheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Pequeños momentos, juntos.',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Explora planes cercanos, entra sin presión y chatea sólo con la gente del momento.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            StatusPill(label: 'Sin DMs', icon: '💬', color: YnotTheme.primary),
                            StatusPill(label: 'Sin followers', icon: '✨', color: YnotTheme.purple),
                            StatusPill(label: 'Chats temporales', icon: '🌙', color: YnotTheme.mint),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(
                    title: 'Entrar',
                    subtitle: 'Usa tu teléfono para abrir tu espacio.',
                  ),
                  const SizedBox(height: 14),
                  KawaiiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: controller.updatePhoneInput,
                          decoration: const InputDecoration(
                            labelText: 'Número de teléfono',
                            hintText: '+82 10 1234 5678',
                          ),
                        ),
                        if (isOtpStep) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            onChanged: controller.updateVerificationInput,
                            decoration: const InputDecoration(
                              labelText: 'Código',
                              hintText: '123456',
                            ),
                          ),
                        ],
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: isOtpStep ? controller.verifyCode : controller.sendVerificationCode,
                          child: Text(isOtpStep ? 'Confirmar' : 'Continuar'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tu acceso es discreto, rápido y pensado para moverte con calma.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  KawaiiCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Una ciudad que se siente cercana.',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sin ruido social. Sin perfiles eternos. Sólo momentos bonitos que aparecen y desaparecen.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Prueba con ${maskPhone(_phoneController.text.isEmpty ? '+82 10 0000 0000' : _phoneController.text)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
