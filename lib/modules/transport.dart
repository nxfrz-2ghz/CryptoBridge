// modules/transport.dart
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';

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
  final String _appInstanceId = const Uuid().v4();
  RawDatagramSocket? _socket;
  bool _isListening = false;

  LanBroadcastTransport({required this.port});

  @override
  Future<void> init() async {
    if (_isListening) return;

    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket!.broadcastEnabled = true;
    _isListening = true;

    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket!.receive();
        if (datagram != null) {
          try {
            final rawMessage = utf8.decode(datagram.data);
            final Map<String, dynamic> packet = jsonDecode(rawMessage);

            if (packet[0] == _appInstanceId) {
              return;
            }

            final String message = packet[1];
            push(message);
          } catch (e) {
          }
        }
      }
    });
  }

  @override
  Future<void> send(String bytes) async {
    if (_socket == null || !_isListening) {
      throw StateError("Transport not initialized");
    }

    final List<dynamic> packet = [
      _appInstanceId,
      bytes,
    ];

    final dataToSend = utf8.encode(jsonEncode(packet));

    _socket!.send(dataToSend, InternetAddress.loopbackIPv4, port);
    _socket!.send(dataToSend, InternetAddress("255.255.255.255"), port);
  }

  @override
  void dispose() {
    _isListening = false;
    _socket?.close();
    super.dispose();
  }
}

