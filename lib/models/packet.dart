// models/packet.dart
import "dart:math";
import "dart:typed_data";

enum PacketType {
  hello,    // handshake — публичный ключ
  ack,      // подтверждение получателя о приходе сообщения
  message,  // обычное сообщение
}

class Packet {
  final PacketType type;
  final int id;
  final int timeStamp;
  final Uint8List payload;

  const Packet({
    required this.type,
    required this.id,
    required this.timeStamp,
    required this.payload
  });

  factory Packet.create({
    required PacketType type,
    required Uint8List payload,
  }) {
    return Packet(
      type:      type,
      id:        Random().nextInt(0x7FFFFFFF),
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      payload:   payload,
    );
  }

  Uint8List toBytes() {
    // Формат: [1 байт тип][4 байта id][8 байт timestamp][payload]
    final buffer = ByteData(13);
    buffer.setUint8(0,  type.index);
    buffer.setUint32(1, id,        Endian.big);
    buffer.setInt64(5,  timeStamp, Endian.big);

    return Uint8List.fromList([
      ...buffer.buffer.asUint8List(),
      ...payload,
    ]);
  }

  static Packet fromBytes(Uint8List bytes) {
    final buffer    = ByteData.sublistView(bytes, 0, 13);
    final type      = PacketType.values[buffer.getUint8(0)];
    final id        = buffer.getUint32(1, Endian.big);
    final timeStamp = buffer.getInt64(5,  Endian.big);
    final payload   = bytes.sublist(13);

    return Packet(type: type, id: id, timeStamp: timeStamp, payload: payload);
  }
}