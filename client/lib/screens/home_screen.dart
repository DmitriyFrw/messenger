import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/messenger_state.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    final state = context.read<MessengerState>();
    state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    context.read<MessengerState>().removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => _loadLocal();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await context.read<MessengerState>().repo.refreshAll();
    } catch (_) {}
    await _loadLocal();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadLocal() async {
    final list = await context.read<MessengerState>().repo.getLocalConversations();
    if (mounted) setState(() => _conversations = list);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<MessengerState>().session?.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.displayName ?? 'Мессенджер'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final peer = await Navigator.push<UserPublic>(
            context,
            MaterialPageRoute(builder: (_) => const NewChatScreen()),
          );
          if (peer != null && mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(peer: peer),
              ),
            );
            _loadLocal();
          }
        },
        child: const Icon(Icons.edit),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _conversations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Нет диалогов\nНажмите + чтобы написать')),
                    ],
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      final last = conv.lastMessage;
                      final subtitle = last?.text ?? 'Нет сообщений';
                      final time = last != null
                          ? DateFormat('dd.MM HH:mm').format(last.sentAt.toLocal())
                          : '';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            conv.peer.displayName.isNotEmpty
                                ? conv.peer.displayName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(conv.peer.displayName),
                        subtitle: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(time, style: Theme.of(context).textTheme.bodySmall),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChatScreen(
                                peer: conv.peer,
                                conversationId: conv.id > 0 ? conv.id : null,
                              ),
                            ),
                          );
                          _loadLocal();
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
