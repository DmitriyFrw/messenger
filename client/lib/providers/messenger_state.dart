import 'package:flutter/foundation.dart';

import '../data/messenger_repository.dart';
import '../models/models.dart';

class MessengerState extends ChangeNotifier {
  MessengerState(this._repo) {
    _repo.addListener(notifyListeners);
  }

  final MessengerRepository _repo;

  MessengerRepository get repo => _repo;

  AuthSession? get session => _repo.session;

  bool get isLoggedIn => session != null;

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
