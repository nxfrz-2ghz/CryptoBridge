// models/contact.dart
import "../modules/transport.dart";

enum TransportType {
  test,
}


class Contact {
  final String name;
  final TransportType transportType;

  const Contact ({
    required this.name,
    required this.transportType,
  });

  Transport createTransport() {
    switch (transportType) {
      case TransportType.test:
        return TestTransport();
    }
  }
}