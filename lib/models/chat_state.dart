// models/chat_state.dart
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import 'package:audioplayers/audioplayers.dart';
import "dart:typed_data";
import "dart:io";
import "dart:convert";

import "message.dart";
import "packet.dart";
import "user.dart";
import "contact.dart";
import "../modules/transport.dart";
import "../modules/cryptography.dart";
import "../modules/text_encoder.dart";
import "../modules/disk_control.dart";

class ChatState extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<Message> _messages = [];
  final Map<int, Message> _pendingAcks = {};
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
    _audioPlayer.dispose();
    transport.dispose();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {

    // Sending
    final encodedBytes = await byteCoder.encodeText(text);
    final packet = Packet.create(
      type: PacketType.message,
      payload: encodedBytes,
    );

    final message = _addMessage(text, true, packetID: packet.id);
    _pendingAcks[packet.id] = message;

    final compressedBytes = Uint8List.fromList(gzip.encode(packet.toBytes()));
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
    final packet = Packet.fromBytes(decompressedBytes);

    switch (packet.type) {
      case PacketType.hello:
        _addMessage("Unexpected hello in ChatState!!!", false);
      case PacketType.ack:
        final ackedID = ByteData.sublistView(packet.payload).getUint32(0);
        _markDelivered(ackedID);
      case PacketType.message:
        // Receiving Message
        final text = await byteCoder.decodeText(packet.payload);
        _addMessage(
            text,
            false,
            time: DateTime.fromMillisecondsSinceEpoch(packet.timeStamp)
        );

        // Sending ack packet
        final ackPacket = Packet.create(
          type: PacketType.ack,
          payload: Uint8List(4)..buffer.asByteData().setUint32(0, packet.id),
        );
        final compressedBytes = Uint8List.fromList(gzip.encode(ackPacket.toBytes()));
        final encryptedBytes = await cryptoBridge.encrypt(compressedBytes);
        final encryptedText = await wordCoder.toWords(encryptedBytes);
        await transport.send(encryptedText);
    }
  }

  Message _addMessage(
      final String text, final bool isMe,
      {int? packetID, MessageStatus? status, DateTime? time}
    ) {

    time ??= DateTime.now();
    status ??= isMe ? MessageStatus.sending : null;

    final message = Message(
      packetID: packetID,
      status: status,
      text: text,
      isMe: isMe,
      time: time,
    );
    _messages.add(message);

    _playChatSound(isMe);
    notifyListeners();
    _saveHistory();

    return message;
  }

  Future<void> _playChatSound(bool isMe) async {
    try {
      final soundPath = isMe ? 'sounds/sent.mp3' : 'sounds/received.mp3';

      await _audioPlayer.stop();

      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      return;
    }
  }

  void _markDelivered(final int messageID) {
    final message = _pendingAcks.remove(messageID);

    if (message != null) {
      message.status = MessageStatus.delivered;

      notifyListeners();
      _saveHistory();
    }
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