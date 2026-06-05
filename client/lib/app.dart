import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/messenger_state.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'theme/dialog_theme.dart';

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key, required this.state});

  final MessengerState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: Consumer<MessengerState>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Диалог',
            debugShowCheckedModeBanner: false,
            theme: DialogTheme.light(),
            darkTheme: DialogTheme.dark(),
            themeMode: appState.profile.darkTheme ? ThemeMode.dark : ThemeMode.light,
            home: appState.isLoggedIn ? const MainShell() : const AuthScreen(),
          );
        },
      ),
    );
  }
}
