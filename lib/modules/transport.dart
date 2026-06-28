// modules/transport.dart
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class Transport {
  Future<void> init() async {}
  Future<void> send(String bytes);

  // Stream автоматически вызывает receive
  final _streamController = StreamController<String>.broadcast();
  Stream<String> receive() => _streamController.stream;

  void push(String bytes) => _streamController.add(bytes);
  void dispose() => _streamController.close();
}

abstract class PollingTransport extends Transport {
  Timer? _timer;

  @override
  Future<void> send(String bytes) async {}

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final messages = await _fetchFromServer();
      for (final msg in messages) {
        push(msg);
      }
    });
  }

  Future<List<String>> _fetchFromServer() async => [];
}


class TestTransport extends Transport {
  @override
  Future<void> send(String bytes) async {
    print("Sending: ${bytes}");
    Future.delayed(Duration(milliseconds: 300 + bytes.length), (){
      push(bytes);
    });
  }

  @override
  void push(String bytes) {
    print("Received: $bytes");
    super.push(bytes);
  }
}


class LanBroadcastTransport extends Transport {
  final int port;
  RawDatagramSocket? _socket;
  bool _isListening = false;

  LanBroadcastTransport({required this.port});

  @override
  Future<void> init() async {
    if (_isListening) return;

    // Сязываем сокет со всеми адресами на указанном порту
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);

    // Разрешаем отправку broadcast-пакетов
    _socket!.broadcastEnabled = true;
    _isListening = true;

    // Слушаем входящие UDP-пакеты
    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          // Декодируем байты в строку и пушим в поток
          final message = utf8.decode(datagram.data);
          push(message);
        }
      }
    });
  }

  @override
  Future<void> send(String bytes) async {
    if (_socket == null || !_isListening) {
      throw StateError("Транспорт не инициализирован. Сначала вызовите init().");
    }

    final dataToSend = utf8.encode(bytes);

    // Отправляем на специальный broadcast-адрес локальной сети
    _socket!.send(dataToSend, InternetAddress.loopbackIPv4, port); // Для тестов на одном устройстве
    _socket!.send(dataToSend, InternetAddress.anyIPv4, port);     // Для реальной локальной сети
  }

  @override
  void dispose() {
    _isListening = false;
    _socket?.close();
    super.dispose();
  }
}

