// models/chat_state.dart
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import 'message.dart';
import "contact.dart";
import '../modules/transport.dart';
import '../modules/cryptography.dart';

class ChatState extends ChangeNotifier {
  final List<Message> _messages = [];
  final Contact contact;
  late final Transport transport;

  List<Message> get messages => List.unmodifiable(_messages);

  ChatState({
      required this.contact
    })
    {
      // Connecting transport from contact
      transport = contact.createTransport();
      transport.receive().listen((bytes) {
        _onReceive(bytes);
    });
  }

  void _onReceive(Uint8List bytes) {
    // TODO: расшифровать через CryptoBridge
    // Пока просто декодируем как текст
    final text = translator.decodeText(bytes);

    _messages.add(Message(
      text: text,
      isMe: false,
      time: DateTime.now(),
    ));

    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    _messages.add(Message(
      text: text,
      isMe: true,
      time: DateTime.now(),
    ));
    notifyListeners();

    // TODO: зашифровать через CryptoBridge
    // Пока просто отправляем как байты
    await transport.send(translator.encodeText(text));
  }

  @override
  void dispose() {
    transport.dispose();
    super.dispose();
  }
}