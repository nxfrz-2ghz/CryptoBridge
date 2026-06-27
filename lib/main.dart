// main.dart
import "dart:math";
import "dart:convert";

import "modules/disk_control.dart";
import "modules/transport.dart";

import "models/user.dart";
import "models/contact.dart";

import "package:flutter/material.dart";
import "ui/home_screen.dart";
import "ui/create_user_screen.dart";

User? currentUser;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  currentUser = await loadUser();
  runApp(const MessengerApp());
}

Future<User?> loadUser() async {
  const key = "userlist";
  if (!await diskControl.has(key)) return null;

  final jsonStr  = await diskControl.get(key);
  final userList = (jsonDecode(jsonStr) as List).cast<String>();
  if (userList.isEmpty) return null;

  return User.load(userList[0]);
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
      home: currentUser != null
          ? HomeScreen(user: currentUser!)
          : const CreateUserScreen(),
    );
  }
}

