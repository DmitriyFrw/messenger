import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../data/profile_store.dart';
import '../providers/messenger_state.dart';
import '../theme/dialog_colors.dart';
import 'landscape_illustration.dart';
import 'dialog_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _isRegister = false;
  bool _rememberMe = true;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final store = ProfileStore();
    final remember = await store.loadRememberMe();
    final username = await store.loadRememberedUsername();
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (username != null) _login.text = username;
    });
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = context.read<MessengerState>();
    final username = _login.text.trim();
    try {
      if (_isRegister) {
        await state.repo.register(
          username: username,
          password: _password.text,
          displayName: _displayName.text.trim(),
        );
      } else {
        await state.repo.login(username, _password.text);
      }
      await ProfileStore().saveRememberMe(_rememberMe, username);
    } catch (e) {
      setState(() => _error = 'Не удалось войти. Проверьте данные и адрес сервера.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — скоро')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DialogColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: DialogColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Column(
                        children: [
                          const DialogLogo(size: 44),
                          const SizedBox(height: 12),
                          Text('Диалог', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 6),
                          const Text(
                            'Пространство для важных разговоров',
                            style: TextStyle(color: DialogColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const LandscapeIllustration(height: 120),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AuthTabs(
                              isRegister: _isRegister,
                              onChanged: (v) => setState(() => _isRegister = v),
                            ),
                            const SizedBox(height: 20),
                            if (_isRegister) ...[
                              _FieldBox(
                                top: TextFormField(
                                  controller: _displayName,
                                  decoration: const InputDecoration(
                                    hintText: 'Отображаемое имя',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                    border: InputBorder.none,
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _FieldBox(
                              top: TextFormField(
                                controller: _login,
                                decoration: const InputDecoration(
                                  hintText: 'Логин (email или телефон)',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: InputBorder.none,
                                ),
                                autocorrect: false,
                                validator: (v) {
                                  if (v == null || v.trim().length < 3) {
                                    return 'Минимум 3 символа';
                                  }
                                  return null;
                                },
                              ),
                              bottom: TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  hintText: 'Пароль',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.length < 6) ? 'Минимум 6 символов' : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                ),
                                const Text('Запомнить меня'),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => _showSoon('Восстановление пароля'),
                                  child: const Text('Забыли пароль?'),
                                ),
                              ],
                            ),
                            if (_error != null) ...[
                              Text(_error!, style: const TextStyle(color: DialogColors.logout)),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: DialogColors.sage,
                                foregroundColor: DialogColors.textPrimary,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_isRegister ? 'Создать аккаунт' : 'Войти'),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('или войти с помощью', style: TextStyle(fontSize: 12)),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _SocialBtn(
                                  icon: Icons.mail_outline,
                                  label: 'Почты',
                                  onTap: () => _showSoon('Вход через почту'),
                                ),
                                _SocialBtn(
                                  icon: Icons.phone_outlined,
                                  label: 'Телефона',
                                  onTap: () => _showSoon('Вход по телефону'),
                                ),
                                _SocialBtn(
                                  icon: Icons.qr_code_2,
                                  label: 'QR-кода',
                                  onTap: () => _showSoon('Вход по QR'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showSoon('Справка'),
                                  icon: const Icon(Icons.help_outline, size: 18),
                                  label: const Text('Нужна помощь?'),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.language, size: 18),
                                  label: const Text('Русский'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.isRegister, required this.onChanged});

  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DialogColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              label: 'Вход',
              icon: Icons.person_outline,
              selected: !isRegister,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _TabChip(
              label: 'Регистрация',
              icon: Icons.verified_user_outlined,
              selected: isRegister,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DialogColors.activeChat : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.top, this.bottom});

  final Widget top;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: DialogColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          top,
          if (bottom != null) const Divider(height: 1),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DialogColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DialogColors.border),
            ),
            child: Icon(icon, color: DialogColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
