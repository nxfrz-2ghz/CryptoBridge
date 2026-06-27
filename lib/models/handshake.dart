// models/handhsake.dart
import "dart:typed_data";
import "dart:async";

import "../modules/transport.dart";
import "../modules/cryptography.dart";
import "packet.dart";

class Handshake {
  final Transport transport;
  final CryptoKeys selfKeys;

  const Handshake({
    required this.transport,
    required this.selfKeys
  });

  Future<Uint8List> perform() async {
    await _sendHello();
    return await _waitForHello();
  }

  Future<void> _sendHello() async {
    final packet = Packet(
      type: PacketType.hello,
      payload: selfKeys.exportPublicKey(),
    );
    await transport.send(packet.toBytes());
  }

  Future<Uint8List> _waitForHello() async {
    try {
      await for (final bytes in transport.receive().timeout(const Duration(seconds: 5))) {
        final packet = Packet.fromBytes(bytes);
        if (packet.type == PacketType.hello) {
          return packet.payload;
        }
      }

      throw Exception('Connection closed before HELLO received');
    } on TimeoutException {
      throw Exception('Handshake timeout: HELLO packet not received');
    }
  }
}