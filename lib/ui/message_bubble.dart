import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      // Мои сообщения справа, чужие слева
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(
          // Пузырь не шире 75% экрана
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(message.isMe ? 18 : 4),
            bottomRight: Radius.circular(message.isMe ? 4  : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min, // Чтобы контейнер не растягивался по высоте
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            // Блок метаданных: время и статус
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.time),
                  style: TextStyle(
                    color: message.isMe ? Colors.white60 : Colors.black38,
                    fontSize: 11,
                  ),
                ),
                // Показываем статус только для своих сообщений
                if (message.isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Метод для выбора подходящей иконки статуса
  Widget _buildStatusIcon(MessageStatus? status) {
    IconData iconData;
    switch (status) {
      case MessageStatus.sending:
        iconData = Icons.access_time_rounded; // Иконка часиков
      case MessageStatus.delivered:
        iconData = Icons.done; // Одна галочка
      case MessageStatus.read:
        iconData = Icons.done_all; // Две галочки
      case null:
        return const SizedBox.shrink(); // На всякий случай, если статус null
    }

    return Icon(
      iconData,
      size: 14,
      color: Colors.white60, // Иконка будет в цвет текста времени
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
