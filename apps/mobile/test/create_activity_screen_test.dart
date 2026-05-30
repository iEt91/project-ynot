import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ynot_mobile/src/features/activities/presentation/create_activity_screen.dart';

void main() {
  testWidgets('create activity screen fits on a small phone width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateActivityScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hasta 4 personas'), findsOneWidget);
  });
}
