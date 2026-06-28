// models/message.dart

enum MessageStatus { sending, delivered, read }

class Message {
  final int? packetID;        // привязка к пакету — null у входящих
  MessageStatus? status;
  final String text;
  final bool isMe;
  final DateTime time;

  Message({
    this.packetID,
    this.status = MessageStatus.sending,
    required this.text,
    required this.isMe,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    "id": packetID,
    "status": status?.name,
    'text': text,
    'isMe': isMe,
    'time': time.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    // Безопасно парсим статус из строки обратно в энум
    final statusStr = json["status"] as String?;
    final parsedStatus = statusStr != null
        ? MessageStatus.values.byName(statusStr)
        : null;

    return Message(
      packetID: json["id"] as int?, // Используем int?, так как может быть null
      status: parsedStatus,
      text: json['text'] as String,
      isMe: json['isMe'] as bool,
      time: DateTime.parse(json['time'] as String),
    );
  }
}
