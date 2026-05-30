import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/activity.dart';
import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../utils/app_logger.dart';

abstract class ActivityRepository {
  Future<AppUser> getProfile(String clientUid);

  Future<AppUser> upsertProfile({
    required String clientUid,
    String? phoneLast4,
    required String nickname,
    required String avatarEmoji,
    String? avatarUrl,
    required String bio,
    required List<String> languages,
    required List<String> vibes,
    required List<String> interests,
  });

  Future<List<Activity>> listActivities(String clientUid);

  Future<Activity?> getActivity({
    required String clientUid,
    required String activityId,
  });

  Future<Activity> createActivity({
    required String clientUid,
    required String title,
    required String description,
    required String category,
    required String vibe,
    required String zone,
    required DateTime startTime,
    required Duration duration,
    required int maxPeople,
    required double realLat,
    required double realLng,
    required double displayLat,
    required double displayLng,
    required String visibility,
  });

  Future<Activity?> joinActivity({
    required String clientUid,
    required String activityId,
  });

  Future<Activity?> confirmAttendance({
    required String clientUid,
    required String activityId,
  });

  Future<Activity?> cancelAttendance({
    required String clientUid,
    required String activityId,
  });

  Future<Activity?> leaveActivity({
    required String clientUid,
    required String activityId,
  });

  Future<List<ChatMessage>> getMessages({
    required String clientUid,
    required String activityId,
  });

  Future<String?> ensureChatId({
    required String clientUid,
    required String activityId,
  });

  Future<String?> resolveChatId(String activityId);

  Stream<List<ChatMessage>> watchMessages({
    required String clientUid,
    required String activityId,
  });

  Future<ChatMessage?> sendMessage({
    required String clientUid,
    required String activityId,
    required String content,
  });

  Future<String> reportMessage({
    required String clientUid,
    required String messageId,
    required String chatId,
    required String activityId,
    required String senderId,
    required String reason,
    String? details,
    String? content,
    DateTime? timestamp,
  });
}

class AppRepository implements ActivityRepository {
  AppRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<AppUser> getProfile(String clientUid) async {
    AppLogger.log(
      'PROFILE',
      'rpc=app_get_profile table=profiles clientUid=$clientUid',
    );
    final data = await _rpcList('app_get_profile', {'p_client_uid': clientUid});
    if (data.isEmpty) {
      AppLogger.log(
        'PROFILE',
        'rpc=app_get_profile empty_response clientUid=$clientUid',
      );
      throw StateError('No profile returned.');
    }

    AppLogger.log(
      'PROFILE',
      'rpc=app_get_profile response_count=${data.length}',
    );
    return _mapUser(data.first as Map<String, dynamic>);
  }

  @override
  Future<AppUser> upsertProfile({
    required String clientUid,
    String? phoneLast4,
    required String nickname,
    required String avatarEmoji,
    String? avatarUrl,
    required String bio,
    required List<String> languages,
    required List<String> vibes,
    required List<String> interests,
  }) async {
    final data = await _rpcList('app_upsert_profile', {
      'p_client_uid': clientUid,
      'p_phone_last4': phoneLast4,
      'p_nickname': nickname,
      'p_avatar_emoji': avatarEmoji,
      'p_avatar_url': avatarUrl,
      'p_bio': bio,
      'p_languages': languages,
      'p_vibes': vibes,
      'p_interests': interests,
    });

    if (data.isEmpty) {
      throw StateError('No profile returned.');
    }

    return _mapUser(data.first as Map<String, dynamic>);
  }

  @override
  Future<List<Activity>> listActivities(String clientUid) async {
    AppLogger.log(
      'EVENTS',
      'rpc=app_list_activities table=activities clientUid=$clientUid',
    );
    final data = await _rpcList('app_list_activities', {
      'p_client_uid': clientUid,
    });
    AppLogger.log(
      'EVENTS',
      'rpc=app_list_activities response_count=${data.length}',
    );
    return data
        .map((row) => _mapActivity(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Activity?> getActivity({
    required String clientUid,
    required String activityId,
  }) async {
    final data = await _rpcList('app_get_activity', {
      'p_client_uid': clientUid,
      'p_activity_id': activityId,
    });

    if (data.isEmpty) {
      return null;
    }

    return _mapActivity(data.first as Map<String, dynamic>);
  }

  @override
  Future<Activity> createActivity({
    required String clientUid,
    required String title,
    required String description,
    required String category,
    required String vibe,
    required String zone,
    required DateTime startTime,
    required Duration duration,
    required int maxPeople,
    required double realLat,
    required double realLng,
    required double displayLat,
    required double displayLng,
    required String visibility,
  }) async {
    final data = await _rpcList('app_create_activity', {
      'p_client_uid': clientUid,
      'p_title': title,
      'p_description': description,
      'p_category': category,
      'p_vibe': vibe,
      'p_zone': zone,
      'p_start_time': startTime.toIso8601String(),
      'p_duration_minutes': duration.inMinutes,
      'p_max_people': maxPeople,
      'p_real_lat': realLat,
      'p_real_lng': realLng,
      'p_display_lat': displayLat,
      'p_display_lng': displayLng,
      'p_visibility': visibility,
    });

    if (data.isEmpty) {
      throw StateError('No activity returned.');
    }

    return _mapActivity(data.first as Map<String, dynamic>);
  }

  @override
  Future<Activity?> joinActivity({
    required String clientUid,
    required String activityId,
  }) async {
    final data = await _rpcList('app_join_activity', {
      'p_client_uid': clientUid,
      'p_activity_id': activityId,
    });

    if (data.isEmpty) {
      return null;
    }

    return _mapActivity(data.first as Map<String, dynamic>);
  }

  @override
  Future<Activity?> confirmAttendance({
    required String clientUid,
    required String activityId,
  }) async {
    final data = await _rpcList('app_confirm_attendance', {
      'p_client_uid': clientUid,
      'p_activity_id': activityId,
    });

    if (data.isEmpty) {
      return null;
    }

    return _mapActivity(data.first as Map<String, dynamic>);
  }

  @override
  Future<Activity?> cancelAttendance({
    required String clientUid,
    required String activityId,
  }) async {
    final data = await _rpcList('app_cancel_attendance', {
      'p_client_uid': clientUid,
      'p_activity_id': activityId,
    });

    if (data.isEmpty) {
      return null;
    }

    return _mapActivity(data.first as Map<String, dynamic>);
  }

  @override
  Future<Activity?> leaveActivity({
    required String clientUid,
    required String activityId,
  }) async {
    final data = await _rpcList('app_leave_activity', {
      'p_client_uid': clientUid,
      'p_activity_id': activityId,
    });

    if (data.isEmpty) {
      return null;
    }

    return _mapActivity(data.first as Map<String, dynamic>);
  }

  @override
  Future<List<ChatMessage>> getMessages({
    required String clientUid,
    required String activityId,
  }) async {
    final data = await _rpcList('app_get_messages', {
      'p_client_uid': clientUid,
      'p_activity_id': activityId,
    });

    return data
        .map((row) => _mapMessage(row as Map<String, dynamic>, clientUid))
        .toList(growable: false);
  }

  @override
  Future<String?> ensureChatId({
    required String clientUid,
    required String activityId,
  }) async {
    final response = await _client.rpc(
      'app_ensure_chat',
      params: {'p_client_uid': clientUid, 'p_activity_id': activityId},
    );

    if (response == null) {
      return null;
    }

    if (response is String) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      return response['chat_id']?.toString() ?? response['id']?.toString();
    }

    return response.toString();
  }

  @override
  Future<String?> resolveChatId(String activityId) {
    return _resolveChatId(activityId);
  }

  @override
  Stream<List<ChatMessage>> watchMessages({
    required String clientUid,
    required String activityId,
  }) async* {
    final chatId = await _resolveChatId(activityId);
    if (chatId == null) {
      yield const [];
      return;
    }

    yield* _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .map((rows) {
          final messages =
              rows
                  .map((row) => _mapMessage(row, clientUid))
                  .toList(growable: false)
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  @override
  Future<ChatMessage?> sendMessage({
    required String clientUid,
    required String activityId,
    required String content,
  }) async {
    final data = await _rpcList('app_send_message', {
      'p_client_uid': clientUid,
      'p_activity_id': activityId,
      'p_content': content,
    });

    if (data.isEmpty) {
      return null;
    }

    return _mapMessage(data.first as Map<String, dynamic>, clientUid);
  }

  @override
  Future<String> reportMessage({
    required String clientUid,
    required String messageId,
    required String chatId,
    required String activityId,
    required String senderId,
    required String reason,
    String? details,
    String? content,
    DateTime? timestamp,
  }) async {
    final response = await _client.rpc(
      'app_report_message',
      params: {
        'p_client_uid': clientUid,
        'p_message_id': messageId,
        'p_chat_id': chatId,
        'p_activity_id': activityId,
        'p_sender_id': senderId,
        'p_reason': reason,
        'p_details': details,
        'p_content': content,
        'p_timestamp': timestamp?.toIso8601String(),
      },
    );

    return response.toString();
  }

  Future<List<dynamic>> _rpcList(
    String function,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await _client.rpc(function, params: params);
      if (response == null) {
        return const [];
      }

      if (response is List) {
        return response;
      }

      if (response is Map<String, dynamic>) {
        return [response];
      }

      return [response];
    } catch (error, stackTrace) {
      AppLogger.error(
        'SUPABASE rpc_error function=$function params=$params',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<String?> _resolveChatId(String activityId) async {
    final response = await _client
        .from('activity_chats')
        .select('id')
        .eq('activity_id', activityId)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      return response['id']?.toString();
    }
    return null;
  }

  Activity _mapActivity(Map<String, dynamic> row) {
    return Activity(
      id: row['id'] as String,
      creatorId: row['creator_id'] as String? ?? '',
      creatorLabel: (row['creator_label'] as String?)?.trim().isNotEmpty == true
          ? row['creator_label'] as String
          : 'Anónimo',
      activityType: _mapActivityType(row['activity_type'] as String?),
      visibility: _mapActivityVisibility(row['visibility'] as String?),
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      category: row['category'] as String? ?? '',
      vibe: row['vibe'] as String? ?? '',
      zone: row['zone'] as String? ?? '',
      status: _mapActivityStatus(row['status'] as String?),
      realLat: _asDouble(row['real_lat']),
      realLng: _asDouble(row['real_lng']),
      displayLat: _asDouble(row['display_lat']),
      displayLng: _asDouble(row['display_lng']),
      locationPrivacyRadiusM:
          (row['location_privacy_radius_m'] as num?)?.toInt() ?? 100,
      exactLocationUnlockAt: _parseDateTime(row['exact_location_unlock_at']),
      startTime: _parseDateTime(row['start_time']),
      endTime: _parseDateTime(row['end_time']),
      maxPeople: (row['max_people'] as num?)?.toInt() ?? 4,
      confirmedCount: (row['confirmed_count'] as num?)?.toInt() ?? 0,
      pendingCount: (row['pending_count'] as num?)?.toInt() ?? 0,
      myStatus: _mapParticipantStatus(row['my_status'] as String?),
      isMine: row['is_mine'] as bool? ?? false,
      lastMessagePreview: row['last_message_preview'] as String? ?? '',
      lastMessageAt: row['last_message_at'] == null
          ? null
          : _parseDateTime(row['last_message_at']),
    );
  }

  AppUser _mapUser(Map<String, dynamic> row) {
    final languages = (row['languages'] as List<dynamic>? ?? const [])
        .cast<String>();
    final vibes = (row['vibes'] as List<dynamic>? ?? const []).cast<String>();
    final interests = (row['interests'] as List<dynamic>? ?? const [])
        .cast<String>();

    return AppUser(
      id: row['auth_uid'] as String? ?? row['id'] as String,
      phoneMasked: _maskLast4(row['phone_last4'] as String?),
      nickname: row['nickname'] as String? ?? '',
      avatarEmoji: row['avatar_emoji'] as String? ?? '🌙',
      photoUrl: row['avatar_url'] as String?,
      bio: row['bio'] as String? ?? '',
      languages: languages,
      vibes: vibes,
      interests: interests,
      status: _mapUserStatus(row['status'] as String?),
      profileComplete: (row['profile_complete'] as bool?) ?? false,
      createdActivityCount:
          (row['created_activity_count'] as num?)?.toInt() ?? 0,
      attendingActivityCount:
          (row['attending_activity_count'] as num?)?.toInt() ?? 0,
    );
  }

  ChatMessage _mapMessage(Map<String, dynamic> row, String clientUid) {
    return ChatMessage(
      id: row['id'] as String,
      chatId: row['chat_id'] as String,
      activityId: row['activity_id'] as String,
      senderId: row['sender_id'] as String,
      senderName: row['sender_name'] as String? ?? 'Usuario',
      senderEmoji: row['sender_emoji'] as String? ?? '🌙',
      content: row['content'] as String? ?? '',
      createdAt: _parseDateTime(row['created_at']),
      isMe: row['is_me'] as bool? ?? row['sender_id'] as String == clientUid,
    );
  }

  ActivityStatus _mapActivityStatus(String? value) {
    return switch (value) {
      'DRAFT' => ActivityStatus.draft,
      'PENDING_MODERATION' => ActivityStatus.pendingModeration,
      'OPEN' => ActivityStatus.open,
      'ACTIVE' => ActivityStatus.open,
      'FULL' => ActivityStatus.full,
      'ONGOING' => ActivityStatus.ongoing,
      'FINISHED' => ActivityStatus.finished,
      'ARCHIVED' => ActivityStatus.archived,
      'CANCELLED' => ActivityStatus.cancelled,
      'FLAGGED' => ActivityStatus.flagged,
      'REMOVED' => ActivityStatus.removed,
      'REJECTED_HIDDEN' => ActivityStatus.rejectedHidden,
      _ => ActivityStatus.open,
    };
  }

  ParticipantStatus? _mapParticipantStatus(String? value) {
    return switch (value) {
      'JOINED_PENDING_CONFIRMATION' =>
        ParticipantStatus.joinedPendingConfirmation,
      'CONFIRMED' => ParticipantStatus.confirmed,
      'LEFT' => ParticipantStatus.left,
      'CANCELLED' => ParticipantStatus.cancelled,
      'ATTENDED' => ParticipantStatus.attended,
      'NO_SHOW' => ParticipantStatus.noShow,
      'NOT_SURE' => ParticipantStatus.notSure,
      'REMOVED_BY_ADMIN' => ParticipantStatus.removedByAdmin,
      _ => null,
    };
  }

  ActivityType _mapActivityType(String? value) {
    return switch (value) {
      'PUBLIC_EVENT' => ActivityType.publicEvent,
      _ => ActivityType.userActivity,
    };
  }

  ActivityVisibility _mapActivityVisibility(String? value) {
    return switch (value) {
      'PRIVATE' => ActivityVisibility.privateActivity,
      _ => ActivityVisibility.publicActivity,
    };
  }

  UserStatus _mapUserStatus(String? value) {
    return switch (value) {
      'TRUSTED' => UserStatus.trusted,
      'WATCHLIST' => UserStatus.watchlist,
      'LIMITED' => UserStatus.limited,
      'SHADOWBANNED' => UserStatus.shadowbanned,
      'BANNED' => UserStatus.banned,
      _ => UserStatus.newUser,
    };
  }

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    return DateTime.parse(value.toString());
  }

  String _maskLast4(String? last4) {
    final value = (last4 ?? '').trim();
    if (value.isEmpty) {
      return '';
    }

    return '•••• $value';
  }
}
