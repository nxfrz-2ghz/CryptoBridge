// ui/chat_screen.dart

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import "../models/user.dart";
import "../models/contact.dart";
import "../models/chat_state.dart";
import "../models/handshake.dart";
import "message_bubble.dart";
import "input_bar.dart";


class ChatScreen extends StatefulWidget {
  final User user;
  final Contact contact;

  const ChatScreen ({
    required this.user,
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

    if (!contact.hasKey) {
      final transport = contact.createTransport();
      final handshake = Handshake(
        transport: transport,
        selfKeys: widget.user.keyPair,
      );

      final theirKey  = await handshake.perform();
      contact = contact.withPublicKey(theirKey);
      await widget.user.updateContact(contact);
    }

    setState(() {
      _chatState = ChatState(
        user: widget.user,
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

