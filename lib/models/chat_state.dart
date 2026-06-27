// models/chat_state.dart
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "dart:typed_data";
import "dart:io";
import "dart:convert";

import "message.dart";
import "user.dart";
import "contact.dart";
import "../modules/transport.dart";
import "../modules/cryptography.dart";
import "../modules/text_encoder.dart";
import "../modules/disk_control.dart";

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
    _loadHistory();

    // Connecting transport from contact
    transport = contact.createTransport();
    transport.receive().listen((encryptedText) {
      _onReceive(encryptedText);
    });

    // Starting chat
    cryptoBridge = CryptoBridge.fromBytes(
      selfKeyPair: user.keyPair,
      theirPublicKeyBytes: contact.publicKey!,
    );
  }

  @override
  void dispose() {
    transport.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    _addMessage(text, true);

    // Sending
    final encodedBytes = await byteCoder.encodeText(text);
    final compressedBytes = Uint8List.fromList(gzip.encode(encodedBytes));
    final encryptedBytes = await cryptoBridge.encrypt(compressedBytes);
    final encryptedText = await wordCoder.toWords(encryptedBytes);

    await transport.send(encryptedText);
  }

  void _onReceive(String encryptedText) async {
    _addMessage("Raw: ${encryptedText}", false);

    // Decrypting
    final encryptedBytes = await wordCoder.toBytes(encryptedText);
    final decryptedBytes = await cryptoBridge.decrypt(encryptedBytes);
    final decompressedBytes = Uint8List.fromList(gzip.decode(decryptedBytes));
    final text = await byteCoder.decodeText(decompressedBytes);

    _addMessage(text, false);
  }

  void _addMessage(String text, bool isMe) {
    _messages.add(Message(
      text: text,
      isMe: isMe,
      time: DateTime.now(),
    ));
    // TODO: sound effect
    notifyListeners();
    _saveHistory();
  }

  Future<void> _loadHistory() async {
    final hasHistory = await diskControl.has("${user.nodeID}_history_${contact.nodeID}");
    if (!hasHistory) return;

    final jsonStr = await diskControl.get("${user.nodeID}_history_${contact.nodeID}");
    final list    = jsonDecode(jsonStr) as List;
    _messages.addAll(list.map((e) => Message.fromJson(e)));
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final jsonStr = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await diskControl.set("${user.nodeID}_history_${contact.nodeID}", jsonStr);
  }

}