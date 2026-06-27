// main.dart
import "dart:math";
import "dart:convert";
import "package:provider/provider.dart";

import "modules/disk_control.dart";
import "modules/transport.dart";

import "models/user_store.dart";
import "models/user.dart";
import "models/contact.dart";

import "package:flutter/material.dart";
import "ui/home_screen.dart";
import "ui/create_user_screen.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = UserStore();
  await store.load();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const MessengerApp(),
    ),
  );
}

class MessengerApp extends StatelessWidget {
  const MessengerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CryptoBridge",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      // Стартовый экран
      home: context.read<UserStore>().user != null
       ? HomeScreen()
       : const CreateUserScreen(),
    );
  }
}

