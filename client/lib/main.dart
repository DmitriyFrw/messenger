import 'package:flutter/material.dart';

import 'app.dart';
import 'data/messenger_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await MessengerRepository.create();
  final state = MessengerState(repo);
  runApp(MessengerApp(state: state));
}
