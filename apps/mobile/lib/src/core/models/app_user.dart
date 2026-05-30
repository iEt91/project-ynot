enum UserStatus { newUser, trusted, watchlist, limited, shadowbanned, banned }

class AppUser {
  const AppUser({
    required this.id,
    required this.phoneMasked,
    required this.nickname,
    required this.avatarEmoji,
    this.photoUrl,
    this.bio = '',
    required this.languages,
    required this.vibes,
    required this.interests,
    required this.status,
    required this.profileComplete,
    this.createdActivityCount = 0,
    this.attendingActivityCount = 0,
  });

  final String id;
  final String phoneMasked;
  final String nickname;
  final String avatarEmoji;
  final String? photoUrl;
  final String bio;
  final List<String> languages;
  final List<String> vibes;
  final List<String> interests;
  final UserStatus status;
  final bool profileComplete;
  final int createdActivityCount;
  final int attendingActivityCount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneMasked': phoneMasked,
      'nickname': nickname,
      'avatarEmoji': avatarEmoji,
      'photoUrl': photoUrl,
      'bio': bio,
      'languages': languages,
      'vibes': vibes,
      'interests': interests,
      'status': status.name,
      'profileComplete': profileComplete,
      'createdActivityCount': createdActivityCount,
      'attendingActivityCount': attendingActivityCount,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      phoneMasked: json['phoneMasked'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarEmoji: json['avatarEmoji'] as String? ?? '🌙',
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      languages: (json['languages'] as List<dynamic>? ?? const []).cast<String>(),
      vibes: (json['vibes'] as List<dynamic>? ?? const []).cast<String>(),
      interests: (json['interests'] as List<dynamic>? ?? const []).cast<String>(),
      status: UserStatus.values.byName(json['status'] as String? ?? UserStatus.newUser.name),
      profileComplete: json['profileComplete'] as bool? ?? false,
      createdActivityCount: json['createdActivityCount'] as int? ?? 0,
      attendingActivityCount: json['attendingActivityCount'] as int? ?? 0,
    );
  }

  AppUser copyWith({
    String? id,
    String? phoneMasked,
    String? nickname,
    String? avatarEmoji,
    String? photoUrl,
    String? bio,
    List<String>? languages,
    List<String>? vibes,
    List<String>? interests,
    UserStatus? status,
    bool? profileComplete,
    int? createdActivityCount,
    int? attendingActivityCount,
  }) {
    return AppUser(
      id: id ?? this.id,
      phoneMasked: phoneMasked ?? this.phoneMasked,
      nickname: nickname ?? this.nickname,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      vibes: vibes ?? this.vibes,
      interests: interests ?? this.interests,
      status: status ?? this.status,
      profileComplete: profileComplete ?? this.profileComplete,
      createdActivityCount: createdActivityCount ?? this.createdActivityCount,
      attendingActivityCount: attendingActivityCount ?? this.attendingActivityCount,
    );
  }
}
