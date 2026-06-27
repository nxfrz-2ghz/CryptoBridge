// ui/home_screen.dart
import "package:flutter/material.dart";

import "../models/user.dart";
import "chat_screen.dart";

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({
    required this.user,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Contacts"),
      ),

      body: widget.user.contacts.isEmpty
          ? Center(
        child: Text(
          "Empty",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: widget.user.contacts.length,
        itemBuilder: (context, index) {
          final contact = widget.user.contacts[index];
          return ListTile(
            
            leading: const Icon(Icons.person),
            title: Text(contact.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ChatScreen(
                    user: widget.user,
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