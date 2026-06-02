import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/activities/presentation/activity_detail_screen.dart';
import '../features/activities/presentation/create_activity_screen.dart';
import '../features/activities/presentation/location_picker_screen.dart';
import '../features/chat/presentation/chat_thread_screen.dart';
import '../core/models/activity.dart';
import '../core/models/moderation_report.dart';
import 'app.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import 'package:ynot_mobile/src/features/profile/presentation/activity_history_screen.dart';
import 'package:ynot_mobile/src/features/profile/presentation/my_activities_screen.dart';
import '../features/profile/presentation/blocked_users_screen.dart';
import 'package:ynot_mobile/src/features/profile/presentation/saved_activities_screen.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/moderation/presentation/internal_moderation_screen.dart';
import '../features/moderation/presentation/flag_detail_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/safety_center_screen.dart';
import '../features/feedback/presentation/feedback_screen.dart';
import '../features/reports/presentation/report_screen.dart';
import '../features/reports/presentation/report_user_participant_selector_screen.dart';

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
        path: '/activity/:id/report-user-selector',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReportUserParticipantSelectorScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/create-activity',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ActivityFormSeed) {
            return CreateActivityScreen(
              initialLocation: extra.initialLocation,
              editingActivity: extra.activity,
            );
          }
          if (extra is LatLng) {
            return CreateActivityScreen(initialLocation: extra);
          }
          if (extra is Activity) {
            return CreateActivityScreen(editingActivity: extra);
          }
          return const CreateActivityScreen();
        },
      ),
      GoRoute(
        path: '/location-picker',
        builder: (context, state) {
          final initial = state.extra is LatLng
              ? state.extra as LatLng
              : const LatLng(37.5563, 126.9228);
          return LocationPickerScreen(initialLocation: initial);
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
      GoRoute(
        path: '/saved',
        builder: (context, state) => const SavedActivitiesScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings/blocked-users',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const SafetyCenterScreen(),
      ),
      GoRoute(
        path: '/settings/moderation',
        builder: (context, state) => const InternalModerationScreen(),
      ),
      GoRoute(
        path: '/settings/moderation/flag/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FlagDetailScreen(flagId: id);
        },
      ),
    ],
  );
});
