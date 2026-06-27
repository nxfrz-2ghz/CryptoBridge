// models/packet.dart
import "dart:typed_data";

enum PacketType {
  hello,    // handshake — публичный ключ
  message,  // обычное сообщение
}

class Packet {
  final PacketType type;
  final Uint8List payload;

  const Packet({required this.type, required this.payload});

  Uint8List toBytes() {
    return Uint8List.fromList([type.index, ...payload]);
  }

  static Packet fromBytes(Uint8List bytes) {
    final type    = PacketType.values[bytes[0]];
    final payload = bytes.sublist(1);
    return Packet(type: type, payload: payload);
  }
}