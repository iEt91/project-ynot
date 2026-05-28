import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/state/app_controller.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import 'router.dart';
import 'theme.dart';

class YnotApp extends ConsumerWidget {
  const YnotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Project Ynot',
      theme: YnotTheme.light,
      darkTheme: YnotTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}

class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);

    return switch (state.stage) {
      AppStage.booting => const _BootScreen(),
      AppStage.phoneAuth || AppStage.otpEntry => const AuthScreen(),
      AppStage.onboarding => const OnboardingScreen(),
      AppStage.ready => const AppShell(),
    };
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
