// ui/chat_screen.dart

import 'dart:typed_data';
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/user_store.dart";
import "../models/contact.dart";
import "../models/chat_state.dart";
import "../models/handshake.dart";
import "../modules/cryptography.dart";
import "message_bubble.dart";
import "input_bar.dart";


class ChatScreen extends StatefulWidget {
  final Contact contact;

  ChatScreen ({
    required this.contact,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatState? _chatState;
  bool _loading = true;

  // INIT
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    Contact contact = widget.contact;

    final transport = contact.createTransport();
    final handshake = Handshake(
      transport: transport,
      selfKeys: context.read<UserStore>().user!.keyPair,
    );
    final theirKey  = await handshake.perform();
    final fingerprint = await KeyFingerprint.compute(theirKey);

    if (!contact.hasKey) {
      // First Connection
      final confirmed = await _showFirstTimeDialog(theirKey, fingerprint);
      if (!confirmed) {
        Navigator.pop(context); // пользователь отказался
        return;
      }

      contact = contact.withPublicKey(theirKey, fingerprint);
      await context.read<UserStore>().updateContact(contact);
    }
    else {
      if (fingerprint != contact.trustedFingerprint) {
        final confirmed = await _showKeyChangedDialog(theirKey, fingerprint, contact);
        if (!confirmed) {
          Navigator.pop(context);
          return;
        }

        contact = contact.withPublicKey(theirKey, fingerprint);
        await context.read<UserStore>().updateContact(contact);
      }
    }

    setState(() {
      _chatState = ChatState(
        user: context.read<UserStore>().user!,
        contact: contact,
      );
      _loading   = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _showFirstTimeDialog(Uint8List key, String fingerprint) async {
    final short = await KeyFingerprint.short(key);

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Verify contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Compare this fingerprint with your contact:",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                short,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Trust & Connect"),
          ),
        ],
      ),
    ) ?? false;
  }

  // Диалог при изменении ключа
  Future<bool> _showKeyChangedDialog(
      Uint8List newKey,
      String newFingerprint,
      Contact contact,
      ) async {
    final oldShort = contact.trustedFingerprint!.substring(0, 6) +
        "..." +
        contact.trustedFingerprint!.substring(contact.trustedFingerprint!.length - 6);
    final newShort = await KeyFingerprint.short(newKey);

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text("Key changed!"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "The key for ${contact.name} has changed. "
                  "This could indicate a security issue.",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            _fingerprintRow("Old key:", oldShort, Colors.red),
            const SizedBox(height: 8),
            _fingerprintRow("New key:", newShort, Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Disconnect", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Trust new key"),
          ),
        ],
      ),
    ) ?? false;
  }

  Widget _fingerprintRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // SCROLLING
  final _scrollController = ScrollController();
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // WIDGET
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Performing Handshake...\nis other user online?.."),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _chatState!,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              widget.contact.name[0].toUpperCase(),
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contact.name,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              Row(
                children: [
                  Icon(Icons.lock, size: 12, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    "E2E ENCRYPTION",
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Consumer<ChatState>(
      builder: (context, chat, _) {
        if (chat.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.grey[300]),
                SizedBox(height: 12),
                Text(
                  "Messages encrypted",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Прокручиваем вниз при каждом новом сообщении
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: chat.messages.length,
          itemBuilder: (context, index) {
            return MessageBubble(message: chat.messages[index]);
          },
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Consumer<ChatState>(
      builder: (context, chat, _) {
        return InputBar(
          onSend: (text) => chat.sendMessage(text),
        );
      },
    );
  }
}

