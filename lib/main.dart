// main.dart
import 'dart:math';
import 'dart:convert';

import "modules/disk_control.dart";
import "modules/transport.dart";
import "models/contact.dart";

import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

String nodeID = "";
List<Contact> contacts = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await generateNodeID();
  await findContacts();
  runApp(const MessengerApp());
}

Future<void> generateNodeID() async {
  const key = "node-id";

  if (await diskControl.has(key)) {
    nodeID = await diskControl.get(key);
  } else {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    nodeID = base64Url.encode(values).replaceAll('=', '').substring(0, 16);
    await diskControl.set(key, nodeID);
  }
}

Future<void> findContacts() async {
  for (int i = 0; i < 5; i++){
    int randomInt = Random().nextInt(10);
    String name = "Test Contact ${randomInt.toString()}";

    Contact testContact = Contact(
        name: name,
        transportType: TransportType.test,
    );
    contacts.add(testContact);
  }
}

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CryptoBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // Стартовый экран
      home: HomeScreen(
        id: nodeID,
        contacts: contacts,
      ),

    );
  }
}

