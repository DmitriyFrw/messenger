import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/messenger_state.dart';
import '../theme/dialog_colors.dart';
import 'geometric_avatar.dart';
import 'hex_message_bubble.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    this.conversation,
    this.composePeer,
  });

  final Conversation? conversation;
  final UserPublic? composePeer;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  int? _conversationId;
  bool _sending = false;

  UserPublic? get _peer => widget.conversation?.peer ?? widget.composePeer;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversation?.id;
    _reload();
    _markRead();
    context.read<MessengerState>().addListener(_reload);
  }

  @override
  void didUpdateWidget(covariant ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation?.id != widget.conversation?.id ||
        oldWidget.composePeer?.id != widget.composePeer?.id) {
      _conversationId = widget.conversation?.id;
      _reload();
      _markRead();
    }
  }

  @override
  void dispose() {
    context.read<MessengerState>().removeListener(_reload);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final id = _conversationId;
    if (id == null || id <= 0) {
      if (mounted) setState(() => _messages = []);
      return;
    }
    final list = await context.read<MessengerState>().repo.getLocalMessages(id);
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
    final peer = _peer;
    final text = _input.text.trim();
    if (peer == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final msg = await context.read<MessengerState>().repo.sendMessage(
            recipientId: peer.id,
            text: text,
          );
      if (_conversationId == null || _conversationId! <= 0) {
        setState(() => _conversationId = msg.conversationId);
        await context.read<MessengerState>().repo.refreshAll();
        context.read<MessengerState>().selectConversation(
              Conversation(id: msg.conversationId, peer: peer, lastMessage: msg),
            );
      }
      await _reload();
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
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final peer = _peer;
    if (peer == null) {
      return Container(
        color: DialogColors.background,
        child: const Center(
          child: Text(
            'Выберите диалог\nили начните новый',
            textAlign: TextAlign.center,
            style: TextStyle(color: DialogColors.textMuted, fontSize: 16),
          ),
        ),
      );
    }

    final myId = context.watch<MessengerState>().session?.user.id;
    final wsOnline = context.watch<MessengerState>().repo.wsConnected;

    return Container(
      color: DialogColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: DialogColors.border)),
            ),
            child: Row(
              children: [
                GeometricAvatar(label: peer.displayName, userId: peer.id, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(peer.displayName, style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: wsOnline ? DialogColors.online : DialogColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            wsOnline ? 'Онлайн' : 'Не в сети',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Сегодня',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Text(
                              'Сегодня',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        );
                      }
                      final msg = _messages[index - 1];
                      return HexMessageBubble(
                        message: msg,
                        isMine: msg.senderId == myId,
                      );
                    },
                  ),
          ),
          _InputBar(
            controller: _input,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: DialogColors.surface,
        border: Border(top: BorderSide(color: DialogColors.border)),
      ),
      child: Row(
        children: [
          _RoundBtn(icon: Icons.add, onTap: () {}),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Сообщение...',
                filled: true,
                fillColor: DialogColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          _RoundBtn(
            icon: Icons.graphic_eq,
            highlighted: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Голосовые сообщения — скоро')),
              );
            },
          ),
          const SizedBox(width: 8),
          _RoundBtn(icon: Icons.sentiment_satisfied_alt_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? DialogColors.sage : DialogColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: DialogColors.textPrimary),
        ),
      ),
    );
  }
}
