import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/messenger_state.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.peer,
    this.conversationId,
  });

  final UserPublic peer;
  final int? conversationId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  int? _conversationId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _loadMessages();
    _markRead();
    context.read<MessengerState>().addListener(_onRepoUpdate);
  }

  @override
  void dispose() {
    context.read<MessengerState>().removeListener(_onRepoUpdate);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onRepoUpdate() => _loadMessages();

  Future<void> _loadMessages() async {
    final id = _conversationId;
    if (id == null || id <= 0) return;
    final list =
        await context.read<MessengerState>().repo.getLocalMessages(id);
    if (mounted) {
      setState(() => _messages = list);
      _scrollToEnd();
    }
  }

  Future<void> _markRead() async {
    final id = _conversationId;
    if (id != null && id > 0) {
      await context.read<MessengerState>().repo.markChatRead(id);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    final repo = context.read<MessengerState>().repo;
    try {
      final msg = await repo.sendMessage(
        recipientId: widget.peer.id,
        text: text,
      );
      if (_conversationId == null || _conversationId! <= 0) {
        _conversationId = msg.conversationId;
        await repo.refreshAll();
      }
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось отправить: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<MessengerState>().session?.user.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.peer.displayName)),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Напишите первое сообщение'))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return MessageBubble(
                        message: msg,
                        isMine: msg.senderId == myId,
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
