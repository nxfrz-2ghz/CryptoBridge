// ui/home_screen.dart
import 'package:provider/provider.dart';
import "package:flutter/material.dart";

import "../models/user_store.dart";
import "chat_screen.dart";

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserStore>().user!;

    return Scaffold(
      appBar: AppBar(title: const Text("Contacts")),

      body: user.contacts.isEmpty
          ? const Center(child: Text("Empty", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        itemCount: user.contacts.length,
        itemBuilder: (context, index) {

          final contact = user.contacts[index];

          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(contact.name),

            subtitle: Row(
              children: [
                Icon(
                  contact.hasKey ? Icons.lock : Icons.lock_open,
                  size: 12,
                  color: contact.hasKey ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Icon(
                  contact.transportType.icon,
                  size: 12,
                  color: Colors.blue,
                ),
              ],
            ),

            trailing: const Icon(Icons.chevron_right),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ChatScreen(
                    contact: contact,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}