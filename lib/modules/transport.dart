// modules/transport.dart
import 'dart:typed_data';
import 'dart:async';

abstract class Transport {
  Future<void> send(Uint8List bytes);

  // Stream автоматически вызывает receive
  final _streamController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> receive() => _streamController.stream;

  void push(Uint8List bytes) => _streamController.add(bytes);
  void dispose() => _streamController.close();
}

abstract class PollingTransport extends Transport {
  Timer? _timer;

  @override
  Future<void> send(Uint8List bytes) async {}

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final messages = await _fetchFromServer();
      for (final msg in messages) {
        push(msg);
      }
    });
  }

  Future<List<Uint8List>> _fetchFromServer() async => [];
}


class TestTransport extends Transport {
  @override
  Future<void> send(Uint8List bytes) async {
    print("Sending: ${bytes}");
    Future.delayed(Duration(milliseconds: 300 + bytes.length), (){
      push(bytes);
    });
  }

  @override
  void push(Uint8List bytes) {
    print("Received: $bytes");
    super.push(bytes);
  }
}
