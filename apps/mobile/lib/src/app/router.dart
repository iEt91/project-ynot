import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activities/presentation/activity_detail_screen.dart';
import '../features/activities/presentation/create_activity_screen.dart';
import 'app.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RootGate(),
      ),
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ActivityDetailScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/create-activity',
        builder: (context, state) => const CreateActivityScreen(),
      ),
    ],
  );
});
