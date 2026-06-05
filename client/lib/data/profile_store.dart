import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class ProfileStore {
  static const _bio = 'profile_bio';
  static const _presence = 'profile_presence';
  static const _avatar = 'profile_avatar';
  static const _dark = 'profile_dark';
  static const _notifications = 'profile_notifications';
  static const _language = 'profile_language';
  static const _notes = 'local_notes';
  static const _pinned = 'pinned_conversations';
  static const _rememberMe = 'remember_me';
  static const _rememberUsername = 'remember_username';

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      bio: prefs.getString(_bio) ?? '',
      presence: UserPresence.values[prefs.getInt(_presence) ?? 0],
      avatarPreset: AvatarPreset.values[prefs.getInt(_avatar) ?? 0],
      darkTheme: prefs.getBool(_dark) ?? false,
      notificationsEnabled: prefs.getBool(_notifications) ?? true,
      language: prefs.getString(_language) ?? 'ru',
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bio, profile.bio);
    await prefs.setInt(_presence, profile.presence.index);
    await prefs.setInt(_avatar, profile.avatarPreset.index);
    await prefs.setBool(_dark, profile.darkTheme);
    await prefs.setBool(_notifications, profile.notificationsEnabled);
    await prefs.setString(_language, profile.language);
  }

  Future<List<LocalNote>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notes);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => LocalNote.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveNotes(List<LocalNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notes,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<Set<int>> loadPinnedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_pinned) ?? []).map(int.parse).toSet();
  }

  Future<void> savePinnedIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pinned, ids.map((e) => e.toString()).toList());
  }

  Future<bool> loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMe) ?? false;
  }

  Future<String?> loadRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rememberUsername);
  }

  Future<void> saveRememberMe(bool value, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMe, value);
    if (value) {
      await prefs.setString(_rememberUsername, username);
    } else {
      await prefs.remove(_rememberUsername);
    }
  }
}
