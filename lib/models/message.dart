// models/message.dart

class Message {
  final String text;
  final bool isMe;
  final DateTime time;

  const Message({
    required this.text,
    required this.isMe,
    required this.time,
  });
}
