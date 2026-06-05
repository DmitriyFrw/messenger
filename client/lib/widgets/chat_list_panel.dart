import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/messenger_state.dart';
import '../theme/dialog_colors.dart';
import 'geometric_avatar.dart';

class ChatListPanel extends StatefulWidget {
  const ChatListPanel({
    super.key,
    required this.conversations,
    required this.loading,
    required this.onRefresh,
    required this.selectedId,
    required this.onSelect,
    required this.onNewChat,
    this.fullWidth = false,
  });

  final List<Conversation> conversations;
  final bool loading;
  final Future<void> Function() onRefresh;
  final int? selectedId;
  final ValueChanged<Conversation> onSelect;
  final VoidCallback onNewChat;
  final bool fullWidth;

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Conversation> get _filtered {
    if (_query.isEmpty) return widget.conversations;
    final q = _query.toLowerCase();
    return widget.conversations
        .where((c) =>
            c.peer.displayName.toLowerCase().contains(q) ||
            c.peer.username.toLowerCase().contains(q))
        .toList();
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year &&
        local.month == yesterday.month &&
        local.day == yesterday.day) {
      return 'Вчера';
    }
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return weekdays[local.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final pinned = context.watch<MessengerState>().pinnedConversationIds;
    final sorted = [..._filtered]..sort((a, b) {
        final ap = pinned.contains(a.id);
        final bp = pinned.contains(b.id);
        if (ap != bp) return ap ? -1 : 1;
        final at = a.lastMessage?.sentAt;
        final bt = b.lastMessage?.sentAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    return Container(
      width: fullWidth ? double.infinity : 320,
      decoration: const BoxDecoration(
        color: DialogColors.surface,
        border: Border(right: BorderSide(color: DialogColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Row(
              children: [
                Text('Диалоги', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Material(
                  color: DialogColors.sageMuted,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onNewChat,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.add, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.loading && sorted.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : sorted.isEmpty
                    ? const Center(child: Text('Нет диалогов'))
                    : ListView.builder(
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final conv = sorted[index];
                          final selected = conv.id == widget.selectedId;
                          final last = conv.lastMessage;
                          return _ChatTile(
                            conv: conv,
                            selected: selected,
                            pinned: pinned.contains(conv.id),
                            time: last != null ? _formatTime(last.sentAt) : '',
                            preview: last?.text ?? 'Нет сообщений',
                            onTap: () => widget.onSelect(conv),
                            onPin: () =>
                                context.read<MessengerState>().togglePin(conv.id),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Поиск',
                prefixIcon: const Icon(Icons.search, color: DialogColors.textMuted),
                filled: true,
                fillColor: DialogColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.conv,
    required this.selected,
    required this.pinned,
    required this.time,
    required this.preview,
    required this.onTap,
    required this.onPin,
  });

  final Conversation conv;
  final bool selected;
  final bool pinned;
  final String time;
  final String preview;
  final VoidCallback onTap;
  final VoidCallback onPin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DialogColors.activeChat : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onPin,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GeometricAvatar(
                label: conv.peer.displayName,
                userId: conv.peer.id,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conv.peer.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(time, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (pinned)
                          const Icon(Icons.push_pin, size: 14, color: DialogColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
