// ui/input_bar.dart
import 'package:flutter/material.dart';

class InputBar extends StatefulWidget {
  final void Function(String text) onSend;

  const InputBar({super.key, required this.onSend});

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Следим за полем ввода чтобы активировать кнопку
    _controller.addListener(() {
      setState(() {
        _hasText = _controller.text.trim().isNotEmpty;
      });
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text); // передаём наверх
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          // Поле ввода занимает всё свободное место
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Сообщение',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Кнопка отправки — активна только если есть текст
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            child: CircleAvatar(
              backgroundColor: _hasText ? Colors.blue[600] : Colors.grey[300],
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _hasText ? _send : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

