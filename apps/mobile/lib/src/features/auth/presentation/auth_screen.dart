import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/kawaii_card.dart';
import '../../../shared/widgets/section_header.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height - 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                KawaiiCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🌙 Project Ynot'),
                      const SizedBox(height: 12),
                      Text(
                        'Pequeños momentos, juntos.',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Explora actividades cerca de ti, con chats temporales y sin presión social.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Entrar',
                  subtitle: 'Usa tu número de teléfono para crear una sesión segura.',
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
                          labelText: 'Phone number',
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
                            labelText: 'Verification code',
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
                        onPressed: isOtpStep
                            ? controller.verifyCode
                            : controller.sendVerificationCode,
                        child: Text(isOtpStep ? 'Verify code' : 'Send code'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.demoMode
                            ? 'Demo mode: local auth is enabled until Firebase Phone Auth is connected.'
                            : 'Firebase Phone Auth will handle the verification flow.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Utility social only. No DMs. No followers. No feed.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Test hint: phone ${maskPhone(_phoneController.text.isEmpty ? '+82 10 0000 0000' : _phoneController.text)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
