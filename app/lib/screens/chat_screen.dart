import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import '../session.dart';
import '../theme.dart';
import '../widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.other,
  });

  final String conversationId;
  final Profile other;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _body = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final repo = SessionScope.of(context).repo;
    try {
      _messages = await repo.messages(widget.conversationId);
      _channel = repo.watchMessages(widget.conversationId, (message) {
        if (!mounted) return;
        if (_messages.any((item) => item.id == message.id)) return;
        setState(() => _messages = [..._messages, message]);
      });
      setState(() {});
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    if (text.isEmpty) return;
    _body.clear();
    try {
      await SessionScope.of(context).repo.sendMessage(widget.conversationId, text);
    } catch (error) {
      if (mounted) await showError(context, error);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _body.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).user!.id;
    return Scaffold(
      appBar: AppBar(title: Text(widget.other.displayName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final mine = message.senderId == me;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: mine ? PulseTheme.lime : PulseTheme.leaf,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.body,
                      style: TextStyle(color: mine ? PulseTheme.ink : PulseTheme.cream),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _body,
                    decoration: const InputDecoration(hintText: 'Message'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
