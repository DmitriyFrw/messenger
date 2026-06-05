import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/user_profile.dart';
import '../providers/messenger_state.dart';
import '../theme/dialog_colors.dart';
import 'geometric_avatar.dart';

class ProfileSettingsPanel extends StatefulWidget {
  const ProfileSettingsPanel({super.key});

  @override
  State<ProfileSettingsPanel> createState() => _ProfileSettingsPanelState();
}

class _ProfileSettingsPanelState extends State<ProfileSettingsPanel> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _server = TextEditingController();
  bool _saving = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<MessengerState>().addListener(_load);
  }

  @override
  void dispose() {
    context.read<MessengerState>().removeListener(_load);
    _name.dispose();
    _bio.dispose();
    _server.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = context.read<MessengerState>();
    final user = state.session?.user;
    if (user == null) return;
    _name.text = user.displayName;
    _bio.text = state.profile.bio;
    _server.text = await ApiConfig.loadBaseUrl();
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = context.read<MessengerState>();
    try {
      await state.repo.updateDisplayName(_name.text.trim());
      await state.updateProfile(state.profile.copyWith(bio: _bio.text.trim()));
      await ApiConfig.saveBaseUrl(_server.text.trim());
      await state.repo.updateBaseUrl(await ApiConfig.loadBaseUrl());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль сохранён')),
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MessengerState>();
    final user = state.session?.user;
    if (user == null || !_ready) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Container(
      color: DialogColors.background,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => state.selectSection(AppSection.dialogs),
              ),
              Text('Настройка профиля', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: DialogColors.sage,
                  foregroundColor: DialogColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      GeometricAvatar(
                        label: user.displayName,
                        preset: state.profile.avatarPreset,
                        radius: 48,
                        backgroundColor: DialogColors.sageDark,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: DialogColors.card,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.photo_camera_outlined, size: 18),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _LabeledField(
                  label: 'Имя',
                  child: TextField(controller: _name),
                ),
                const SizedBox(height: 16),
                _LabeledField(
                  label: 'О себе',
                  child: TextField(
                    controller: _bio,
                    maxLines: 3,
                    maxLength: 120,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Статус', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserPresence>(
                  value: state.profile.presence,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.circle, color: DialogColors.online, size: 12),
                  ),
                  items: UserPresence.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(presenceLabel(p))))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    state.updateProfile(state.profile.copyWith(presence: v));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Имя пользователя', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: DialogColors.border),
                    borderRadius: BorderRadius.circular(14),
                    color: DialogColors.card,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('@${user.username}')),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Смена логина пока недоступна')),
                          );
                        },
                        child: const Text('Изменить'),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Ваш уникальный адрес в Диалоге.',
                  style: TextStyle(fontSize: 12, color: DialogColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Аватар', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final preset in AvatarPreset.values)
                      InkWell(
                        onTap: () => state.updateProfile(
                          state.profile.copyWith(avatarPreset: preset),
                        ),
                        child: GeometricAvatar(
                          label: user.displayName,
                          preset: preset,
                          userId: user.id,
                          radius: 22,
                          backgroundColor: state.profile.avatarPreset == preset
                              ? DialogColors.sageDark
                              : null,
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Загрузить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsRow(
            icon: Icons.palette_outlined,
            title: 'Тема оформления',
            value: state.profile.darkTheme ? 'Тёмная' : 'Светлая',
            onTap: () => state.updateProfile(
              state.profile.copyWith(darkTheme: !state.profile.darkTheme),
            ),
          ),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            title: 'Уведомления',
            value: state.profile.notificationsEnabled ? 'Вкл.' : 'Выкл.',
            onTap: () => state.updateProfile(
              state.profile.copyWith(
                notificationsEnabled: !state.profile.notificationsEnabled,
              ),
            ),
          ),
          _SettingsRow(
            icon: Icons.lock_outline,
            title: 'Конфиденциальность',
            onTap: () {},
          ),
          _SettingsRow(
            icon: Icons.language,
            title: 'Язык',
            value: 'Русский',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _Card(
            child: _LabeledField(
              label: 'Адрес сервера API',
              child: TextField(
                controller: _server,
                decoration: const InputDecoration(
                  helperText: 'Android эмулятор: http://10.0.2.2:8000',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => state.repo.logout(),
            icon: const Icon(Icons.logout, color: DialogColors.logout),
            label: const Text('Выйти из аккаунта', style: TextStyle(color: DialogColors.logout)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: DialogColors.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DialogColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DialogColors.border),
      ),
      child: child,
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: DialogColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: DialogColors.border),
          ),
          leading: Icon(icon, color: DialogColors.textSecondary),
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Text(value!, style: Theme.of(context).textTheme.bodySmall),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
