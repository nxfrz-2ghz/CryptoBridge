// models/chat_state.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:typed_data';

import 'message.dart';
import "user.dart";
import "contact.dart";
import '../modules/transport.dart';
import '../modules/cryptography.dart';

class ChatState extends ChangeNotifier {
  final List<Message> _messages = [];
  final Contact contact;
  final User user;

  late final Transport transport;
  late final CryptoBridge cryptoBridge;

  List<Message> get messages => List.unmodifiable(_messages);

  ChatState({
    required this.user,
    required this.contact,
  }) {
    // Connecting transport from contact
    transport = contact.createTransport();
    transport.receive().listen((bytes) {
      _onReceive(bytes);
    });

    // Starting chat
    cryptoBridge = CryptoBridge.fromBytes(
      selfKeyPair: user.keyPair,
      theirPublicKeyBytes: contact.publicKey!,
    );
  }

  Future<void> sendMessage(String text) async {
    _messages.add(Message(
      text: text,
      isMe: true,
      time: DateTime.now(),
    ));
    notifyListeners();

    await transport.send(
        await cryptoBridge.encrypt(
            await translator.encodeText(text)
        )
    );
  }

  void _onReceive(Uint8List bytes) async {
    final text = await translator.decodeText(
      await cryptoBridge.decrypt(bytes)
    );

    _messages.add(Message(
      text: text,
      isMe: false,
      time: DateTime.now(),
    ));

    notifyListeners();
  }

  @override
  void dispose() {
    transport.dispose();
    super.dispose();
  }
}