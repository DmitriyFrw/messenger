import 'package:flutter/material.dart';

import '../providers/messenger_state.dart';
import '../theme/dialog_colors.dart';
import 'dialog_logo.dart';

class DialogSidebar extends StatelessWidget {
  const DialogSidebar({
    super.key,
    required this.section,
    required this.onSectionChanged,
  });

  final AppSection section;
  final ValueChanged<AppSection> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      color: DialogColors.sidebar,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const DialogLogo(size: 36),
          const SizedBox(height: 28),
          _NavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Диалоги',
            selected: section == AppSection.dialogs,
            onTap: () => onSectionChanged(AppSection.dialogs),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Контакты',
            selected: section == AppSection.contacts,
            onTap: () => onSectionChanged(AppSection.contacts),
          ),
          _NavItem(
            icon: Icons.menu_book_outlined,
            label: 'Заметки',
            selected: section == AppSection.notes,
            onTap: () => onSectionChanged(AppSection.notes),
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Настройки',
            selected: section == AppSection.settings,
            onTap: () => onSectionChanged(AppSection.settings),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? DialogColors.activeChat : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: DialogColors.textPrimary),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: DialogColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
