// ui/home_screen.dart
import 'package:flutter/material.dart';

import "../models/contact.dart";
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String id;
  final List<Contact> contacts;

  const HomeScreen({
    required this.id,
    required this.contacts,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Контакты'),
      ),

      body: widget.contacts.isEmpty
          ? Center(
        child: Text(
          'Нет контактов',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: widget.contacts.length,
        itemBuilder: (context, index) {
          final contact = widget.contacts[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(contact.name),
            // стрелка справа — подсказывает что это кнопка
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ChatScreen(contact: contact),
                ),
              );
            },
          );
        },
      ),
    );
  }
}