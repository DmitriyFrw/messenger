import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/messenger_state.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key, required this.state});

  final MessengerState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: 'Messenger',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B6EE1)),
          useMaterial3: true,
        ),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<MessengerState>().isLoggedIn;
    return loggedIn ? const HomeScreen() : const AuthScreen();
  }
}
