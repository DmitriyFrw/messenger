import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../providers/messenger_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrl = TextEditingController();
  final _displayName = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final url = await ApiConfig.loadBaseUrl();
    final user = context.read<MessengerState>().session?.user;
    setState(() {
      _serverUrl.text = url;
      _displayName.text = user?.displayName ?? '';
    });
  }

  @override
  void dispose() {
    _serverUrl.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _saveServer() async {
    setState(() => _saving = true);
    try {
      await ApiConfig.saveBaseUrl(_serverUrl.text.trim());
      await context.read<MessengerState>().repo.updateBaseUrl(
            await ApiConfig.loadBaseUrl(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Адрес сервера сохранён')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveName() async {
    setState(() => _saving = true);
    try {
      await context.read<MessengerState>().repo.updateDisplayName(
            _displayName.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Имя обновлено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await context.read<MessengerState>().repo.logout();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Сервер API', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _serverUrl,
            decoration: const InputDecoration(
              hintText: 'http://127.0.0.1:8000',
              border: OutlineInputBorder(),
              helperText:
                  'Android эмулятор: http://10.0.2.2:8000\nФизическое устройство: IP компьютера в LAN',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _saveServer,
            child: const Text('Сохранить адрес'),
          ),
          const Divider(height: 32),
          Text('Профиль', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _displayName,
            decoration: const InputDecoration(
              labelText: 'Отображаемое имя',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _saveName,
            child: const Text('Сохранить имя'),
          ),
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
