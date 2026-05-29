import 'package:flutter/material.dart';

import '../models/models.dart';

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.status, this.color});

  final MessageStatus status;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    switch (status) {
      case MessageStatus.notDelivered:
        return Tooltip(
          message: 'Не доставлено',
          child: Icon(Icons.schedule, size: 14, color: c),
        );
      case MessageStatus.delivered:
        return Tooltip(
          message: 'Доставлено',
          child: Icon(Icons.done_all, size: 14, color: c),
        );
      case MessageStatus.read:
        return Tooltip(
          message: 'Прочитано',
          child: Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent),
        );
    }
  }
}
