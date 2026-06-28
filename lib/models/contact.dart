// models/contact.dart
import "dart:typed_data";
import "dart:convert";
import 'package:flutter/material.dart';

import "../modules/transport.dart";

enum TransportType {
  test,
  LANBroadcast;

  IconData get icon {
    switch (this) {
      case TransportType.test:
        return Icons.science;
      case TransportType.LANBroadcast:
        return Icons.wifi;
    }
  }
}


class Contact {
  final String name;
  final String nodeID;
  final TransportType transportType;
  final Uint8List? publicKey;

  const Contact ({
    required this.name,
    required this.nodeID,
    required this.transportType,
    this.publicKey,
  });

  Transport createTransport() {
    final Transport transport;
    switch (transportType) {
      case TransportType.test:
        transport = TestTransport();
      case TransportType.LANBroadcast:
        transport = LanBroadcastTransport(port: 5678);
        transport.init();
    }
    return transport;
  }

  Contact withPublicKey(Uint8List key) => Contact(
    name: name,
    nodeID: nodeID,
    transportType: transportType,
    publicKey: key,
  );

  bool get hasKey => publicKey != null;

  // JSON SAVING/LOADING
  // ToJSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'nodeID': nodeID,
    'transportType': transportType.name,
    'publicKey': publicKey != null ? base64Encode(publicKey!) : null,
  };

  // FromJSON
  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    name: json['name'] as String,
    nodeID: json['nodeID'] as String,
    transportType: TransportType.values.byName(json['transportType'] as String),
    publicKey: json['publicKey'] != null
        ? base64Decode(json['publicKey'] as String)
        : null,
  );
}