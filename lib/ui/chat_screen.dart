// ui/chat_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import "../models/contact.dart";
import '../models/chat_state.dart';
import 'message_bubble.dart';
import 'input_bar.dart';


class ChatScreen extends StatefulWidget {
  final Contact contact;

  const ChatScreen ({
    required this.contact
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Автопрокрутка вниз при новом сообщении
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Небольшая задержка — ждём пока Flutter отрисует новый виджет
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatState(contact: widget.contact),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Column(
          children: [
            // Список сообщений занимает всё место кроме поля ввода
            Expanded(child: _buildMessageList()),
            // Поле ввода прибито к низу
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
                    'Сквозное шифрование',
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
    // Consumer перерисовывается когда ChatState вызывает notifyListeners()
    // Аналог подписки на сигнал в Godot
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
                  'Сообщения защищены\nсквозным шифрованием',
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
          // Подключаем отправку из ChatState к UI кнопке
          // Аналог connect("pressed", self, "_on_send") в Godot
          onSend: (text) => chat.sendMessage(text),
        );
      },
    );
  }
}

