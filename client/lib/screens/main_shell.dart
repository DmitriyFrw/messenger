import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/messenger_state.dart';
import '../theme/dialog_colors.dart';
import '../widgets/chat_list_panel.dart';
import '../widgets/chat_panel.dart';
import '../widgets/contacts_panel.dart';
import '../widgets/dialog_sidebar.dart';
import '../widgets/notes_panel.dart';
import '../widgets/profile_settings_panel.dart';
import 'new_chat_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    context.read<MessengerState>().addListener(_onStateChanged);
  }

  @override
  void dispose() {
    context.read<MessengerState>().removeListener(_onStateChanged);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await context.read<MessengerState>().repo.refreshAll();
    } catch (_) {}
    await _loadLocal();
    if (mounted) setState(() => _loading = false);
  }

  void _onStateChanged() => _loadLocal();

  Future<void> _loadLocal() async {
    final list = await context.read<MessengerState>().repo.getLocalConversations();
    if (mounted) setState(() => _conversations = list);
  }

  Future<void> _openNewChat() async {
    final peer = await Navigator.push<UserPublic>(
      context,
      MaterialPageRoute(builder: (_) => const NewChatScreen()),
    );
    if (peer != null && mounted) {
      context.read<MessengerState>().startComposeWith(peer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MessengerState>();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    if (!isWide) {
      return _MobileShell(
        state: state,
        conversations: _conversations,
        loading: _loading,
        onRefresh: _bootstrap,
        onNewChat: _openNewChat,
      );
    }

    return Scaffold(
      backgroundColor: DialogColors.background,
      body: Row(
        children: [
          DialogSidebar(
            section: state.section,
            onSectionChanged: state.selectSection,
          ),
          if (state.section == AppSection.dialogs) ...[
            ChatListPanel(
              conversations: _conversations,
              loading: _loading,
              onRefresh: _bootstrap,
              selectedId: state.selectedConversation?.id,
              onSelect: state.selectConversation,
              onNewChat: _openNewChat,
            ),
            Expanded(
              child: ChatPanel(
                conversation: state.selectedConversation,
                composePeer: state.composePeer,
              ),
            ),
          ] else if (state.section == AppSection.contacts)
            const Expanded(child: ContactsPanel())
          else if (state.section == AppSection.notes)
            const Expanded(child: NotesPanel())
          else
            const Expanded(child: ProfileSettingsPanel()),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.state,
    required this.conversations,
    required this.loading,
    required this.onRefresh,
    required this.onNewChat,
  });

  final MessengerState state;
  final List<Conversation> conversations;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (state.section) {
      case AppSection.dialogs:
        if (state.selectedConversation != null || state.composePeer != null) {
          body = ChatPanel(
            conversation: state.selectedConversation,
            composePeer: state.composePeer,
          );
        } else {
          body = ChatListPanel(
            conversations: conversations,
            loading: loading,
            onRefresh: onRefresh,
            selectedId: null,
            onSelect: state.selectConversation,
            onNewChat: onNewChat,
            fullWidth: true,
          );
        }
      case AppSection.contacts:
        body = const ContactsPanel();
      case AppSection.notes:
        body = const NotesPanel();
      case AppSection.settings:
        body = const ProfileSettingsPanel();
    }

    return Scaffold(
      backgroundColor: DialogColors.background,
      appBar: (state.section == AppSection.dialogs &&
              (state.selectedConversation != null || state.composePeer != null))
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: state.clearChatSelection,
              ),
              title: Text(
                state.selectedConversation?.peer.displayName ??
                    state.composePeer?.displayName ??
                    'Чат',
              ),
            )
          : null,
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.section.index,
        onDestinationSelected: (i) => state.selectSection(AppSection.values[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Диалоги'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Контакты'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Заметки'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Настройки'),
        ],
      ),
    );
  }
}
