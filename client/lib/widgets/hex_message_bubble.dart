import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/dialog_colors.dart';
import 'hex_clipper.dart';

class HexMessageBubble extends StatelessWidget {
  const HexMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.sentAt.toLocal());
    final bg = isMine ? DialogColors.outgoingBubble : DialogColors.incomingBubble;
    final fg = DialogColors.textPrimary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
        child: ClipPath(
          clipper: HexClipper(mine: isMine),
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.55),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: bg,
              border: isMine ? null : Border.all(color: DialogColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message.text,
                    style: TextStyle(color: fg, fontSize: 15, height: 1.35),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time, style: const TextStyle(fontSize: 11, color: DialogColors.textMuted)),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      _StatusTicks(status: message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTicks extends StatelessWidget {
  const _StatusTicks({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == MessageStatus.read
        ? DialogColors.online
        : DialogColors.textMuted;
    return Icon(Icons.done_all, size: 14, color: color);
  }
}
