// ui/create_user_screen.dart
import "package:flutter/material.dart";
import 'package:provider/provider.dart';

import "../models/user_store.dart";
import "../models/user.dart";
import "home_screen.dart";

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _create() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final user = await User.create(_controller.text.trim());

    await context.read<UserStore>().setUser(user);


    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUsers = context.watch<UserStore>().users.isNotEmpty;

    return Scaffold(
      appBar: hasUsers
          ? AppBar(
        title: const Text("Create account"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      )
          : null,

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Text("Create new account", style: Theme.of(context).textTheme.headlineMedium),

              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _create(),
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