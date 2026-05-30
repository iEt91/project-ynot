import 'package:flutter/material.dart';

import '../app/theme.dart';

class BootstrapErrorApp extends StatelessWidget {
  const BootstrapErrorApp({
    super.key,
    required this.message,
    required this.envLoaded,
    required this.supabaseInitialized,
  });

  final String message;
  final bool envLoaded;
  final bool supabaseInitialized;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: YnotTheme.dark,
      darkTheme: YnotTheme.dark,
      themeMode: ThemeMode.dark,
      home: Scaffold(
        backgroundColor: YnotTheme.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: YnotTheme.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: YnotTheme.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No pudimos abrir la app',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: YnotTheme.mutedText,
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 18),
                      _InfoRow(label: 'envLoaded', value: envLoaded ? 'true' : 'false'),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'supabaseInitialized',
                        value: supabaseInitialized ? 'true' : 'false',
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Revisa apps/mobile/.env y vuelve a abrir la app.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: YnotTheme.mutedText,
                            ),
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
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: YnotTheme.text,
              ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: YnotTheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
