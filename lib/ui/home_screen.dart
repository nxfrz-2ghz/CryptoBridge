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
                    onTap: () async {
                      await context.read<UserStore>().changeUser(u.nodeID);
                      Navigator.pop(context);
                    },
                    onLongPress: () async {
                      final delete = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete user"),
                          content: Text("Delete ${u.name}?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (delete == true) {
                        await context.read<UserStore>().removeUser(u.nodeID);

                        if (!mounted) return;

                        if (context.read<UserStore>().user == null) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const CreateUserScreen(),
                            ),
                                (route) => false,
                          );
                        }
                      }
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

          return Dismissible(
            key: ValueKey(contact.nodeID),
            direction: DismissDirection.endToStart,

            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),

            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete contact"),
                  content: Text("Delete ${contact.name}?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              ) ??
                  false;
            },

            onDismissed: (_) {
              context.read<UserStore>().removeContact(contact.nodeID);
            },

            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(contact.name),

              subtitle: Row(
                mainAxisSize: MainAxisSize.min,
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
                    builder: (_) => ChatScreen(contact: contact),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}