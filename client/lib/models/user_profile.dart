enum UserPresence { online, away, busy, offline }

enum AvatarPreset { letter, mountain, wave, lavender, leaf }

class LocalNote {
  const LocalNote({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;

  factory LocalNote.fromJson(Map<String, dynamic> json) => LocalNote(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updated_at': updatedAt.toIso8601String(),
      };
}

class UserProfile {
  const UserProfile({
    this.bio = '',
    this.presence = UserPresence.online,
    this.avatarPreset = AvatarPreset.letter,
    this.darkTheme = false,
    this.notificationsEnabled = true,
    this.language = 'ru',
  });

  final String bio;
  final UserPresence presence;
  final AvatarPreset avatarPreset;
  final bool darkTheme;
  final bool notificationsEnabled;
  final String language;

  UserProfile copyWith({
    String? bio,
    UserPresence? presence,
    AvatarPreset? avatarPreset,
    bool? darkTheme,
    bool? notificationsEnabled,
    String? language,
  }) =>
      UserProfile(
        bio: bio ?? this.bio,
        presence: presence ?? this.presence,
        avatarPreset: avatarPreset ?? this.avatarPreset,
        darkTheme: darkTheme ?? this.darkTheme,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        language: language ?? this.language,
      );

  static const defaults = UserProfile();
}

String presenceLabel(UserPresence p) {
  switch (p) {
    case UserPresence.online:
      return 'Онлайн';
    case UserPresence.away:
      return 'Отошёл';
    case UserPresence.busy:
      return 'Занят';
    case UserPresence.offline:
      return 'Не в сети';
  }
}
