import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/activities/presentation/activity_detail_screen.dart';
import '../features/activities/presentation/create_activity_screen.dart';
import '../features/chat/presentation/chat_thread_screen.dart';
import '../core/state/app_controller.dart';
import 'app.dart';
import '../features/feedback/presentation/feedback_screen.dart';
import '../features/reports/presentation/report_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const RootGate()),
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ActivityDetailScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ChatThreadScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/activity/:id/feedback',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FeedbackScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/activity/:id/report',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final activity = ref
              .read(appStateProvider)
              .activities
              .where((item) => item.id == id)
              .firstOrNull;
          return ReportScreen(title: activity?.title ?? 'Tu actividad');
        },
      ),
      GoRoute(
        path: '/create-activity',
        builder: (context, state) {
          final initialLocation = state.extra is LatLng
              ? state.extra as LatLng
              : null;
          return CreateActivityScreen(initialLocation: initialLocation);
        },
      ),
    ],
  );
});

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
