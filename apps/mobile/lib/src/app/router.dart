import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/activities/presentation/activity_detail_screen.dart';
import '../features/activities/presentation/create_activity_screen.dart';
import '../features/chat/presentation/chat_thread_screen.dart';
import '../core/models/moderation_report.dart';
import 'app.dart';
import '../features/profile/presentation/activity_history_screen.dart';
import '../features/profile/presentation/my_activities_screen.dart';
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
          final request = state.extra is ReportRequest
              ? state.extra as ReportRequest
              : ReportRequest(
                  activityId: id,
                  targetType: ReportTargetType.activity,
                  targetId: id,
                );
          return ReportScreen(
            activityId: request.activityId,
            targetType: request.targetType,
            targetId: request.targetId,
          );
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
      GoRoute(
        path: '/my-activities',
        builder: (context, state) => const MyActivitiesScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const ActivityHistoryScreen(),
      ),
    ],
  );
});
