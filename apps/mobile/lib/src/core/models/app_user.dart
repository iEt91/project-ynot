enum UserStatus { newUser, trusted, watchlist, limited, shadowbanned, banned }

class AppUser {
  const AppUser({
    required this.id,
    required this.phoneMasked,
    required this.nickname,
    required this.avatarEmoji,
    required this.languages,
    required this.vibes,
    required this.interests,
    required this.status,
    required this.profileComplete,
  });

  final String id;
  final String phoneMasked;
  final String nickname;
  final String avatarEmoji;
  final List<String> languages;
  final List<String> vibes;
  final List<String> interests;
  final UserStatus status;
  final bool profileComplete;

  AppUser copyWith({
    String? id,
    String? phoneMasked,
    String? nickname,
    String? avatarEmoji,
    List<String>? languages,
    List<String>? vibes,
    List<String>? interests,
    UserStatus? status,
    bool? profileComplete,
  }) {
    return AppUser(
      id: id ?? this.id,
      phoneMasked: phoneMasked ?? this.phoneMasked,
      nickname: nickname ?? this.nickname,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      languages: languages ?? this.languages,
      vibes: vibes ?? this.vibes,
      interests: interests ?? this.interests,
      status: status ?? this.status,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }
}
