// ui/home_screen.dart
import 'package:provider/provider.dart';
import "package:flutter/material.dart";

import "../models/user_store.dart";
import "../models/user.dart";

import "create_user_screen.dart";
import "create_contact_screen.dart";
import "chat_screen.dart";

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserStore>().user!;
    final users = context.watch<UserStore>().users;

    return Scaffold(
      appBar: AppBar(title: const Text("Contacts")),

      // Add Contact
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateContactScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            // Шапка с инфо пользователя
            UserAccountsDrawerHeader(
              accountName: Text(user.name),
              accountEmail: Text(user.nodeID),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32, color: Colors.blue),
                ),
              ),
            ),

            // Список пользователей (если их несколько)
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(u.name),
                    selected: u.nodeID == user.nodeID,
                    onTap: () {
                      // TODO: переключение пользователя
                      Navigator.pop(context); // закрываем drawer
                    },
                  );
                },
              ),
            ),

            const Divider(),

            // Кнопка добавления пользователя
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("Add account"),
              onTap: () {
                Navigator.pop(context); // закрываем drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),

      // Contact list
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