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

  Map<String, dynamic> toJson() => {
    'text': text,
    'isMe': isMe,
    'time': time.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    text: json['text'] as String,
    isMe: json['isMe'] as bool,
    time: DateTime.parse(json['time'] as String),
  );
}
