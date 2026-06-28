// ui/create_contact_screen.dart
import "package:flutter/material.dart";
import 'package:provider/provider.dart';

import "../models/user_store.dart";
import "../models/contact.dart";
import "home_screen.dart";

class CreateContactScreen extends StatefulWidget {
  const CreateContactScreen ({super.key});

  @override
  State<CreateContactScreen> createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<CreateContactScreen> {
  final _name_controller = TextEditingController();
  final _id_controller = TextEditingController();
  TransportType _transport = TransportType.test;
  bool _loading = false;

  Future<void> _create() async {
    if (
      _name_controller.text.trim().isEmpty
      || _id_controller.text.trim().isEmpty
    ) return;
    setState(() => _loading = true);

    final contact = await Contact(
        name: _name_controller.text.trim(),
        nodeID: _id_controller.text.trim(),
        transportType: _transport);

    await context.read<UserStore>().addContact(contact);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text("Add new user", style: Theme.of(context).textTheme.headlineMedium),

              const SizedBox(height: 32),
              TextField(
                controller: _name_controller,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _create(),
              ),

              const SizedBox(height: 32),
              TextField(
                controller: _id_controller,
                decoration: const InputDecoration(
                  labelText: "UserID",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _create(),
              ),

              const SizedBox(height: 16),
              // Выпадающий список транспортов
              DropdownButtonFormField<TransportType>(
                value: _transport,
                decoration: const InputDecoration(
                  labelText: "Transport",
                  border: OutlineInputBorder(),
                ),
                items: TransportType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(type.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _transport = value);
                },
              ),

              const SizedBox(height: 16),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _create,
                child: const Text("Create"),
              ),

            ],
          ),
        ),
      ),
    );
  }
}