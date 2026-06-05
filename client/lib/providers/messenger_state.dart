import 'package:flutter/foundation.dart';

import '../data/messenger_repository.dart';
import '../data/profile_store.dart';
import '../models/models.dart';
import '../models/user_profile.dart';

enum AppSection { dialogs, contacts, notes, settings }

class MessengerState extends ChangeNotifier {
  MessengerState(this._repo) {
    _repo.addListener(notifyListeners);
    _loadProfile();
  }

  final MessengerRepository _repo;
  final ProfileStore profileStore = ProfileStore();

  AppSection section = AppSection.dialogs;
  Conversation? selectedConversation;
  UserPublic? composePeer;
  UserProfile profile = UserProfile.defaults;
  Set<int> pinnedConversationIds = {};
  bool wsConnected = false;

  MessengerRepository get repo => _repo;
  AuthSession? get session => _repo.session;
  bool get isLoggedIn => session != null;

  Future<void> _loadProfile() async {
    profile = await profileStore.loadProfile();
    pinnedConversationIds = await profileStore.loadPinnedIds();
    wsConnected = _repo.wsConnected;
    notifyListeners();
  }

  void setWsConnected(bool value) {
    if (wsConnected == value) return;
    wsConnected = value;
    notifyListeners();
  }

  void selectSection(AppSection value) {
    section = value;
    if (value != AppSection.dialogs) {
      selectedConversation = null;
      composePeer = null;
    }
    notifyListeners();
  }

  void selectConversation(Conversation? conv) {
    selectedConversation = conv;
    if (conv != null) composePeer = null;
    section = AppSection.dialogs;
    notifyListeners();
  }

  void startComposeWith(UserPublic peer) {
    composePeer = peer;
    selectedConversation = null;
    section = AppSection.dialogs;
    notifyListeners();
  }

  void clearChatSelection() {
    selectedConversation = null;
    composePeer = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile next) async {
    profile = next;
    await profileStore.saveProfile(next);
    notifyListeners();
  }

  Future<void> togglePin(int conversationId) async {
    if (pinnedConversationIds.contains(conversationId)) {
      pinnedConversationIds.remove(conversationId);
    } else {
      pinnedConversationIds.add(conversationId);
    }
    await profileStore.savePinnedIds(pinnedConversationIds);
    notifyListeners();
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
