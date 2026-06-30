import 'package:flutter/material.dart';
import 'package:ethereal_genui_core/ethereal_genui_core.dart';
import 'package:ethereal_genui_llm/ethereal_genui_llm.dart';
import '../genui_actions.dart';
import '../genui_block.dart';

/// One widget that wires a [GenUiDirectConnection] to a streaming chat UI.
///
/// Handles sending user messages, accumulating streaming [MessageSegment] lists,
/// and rendering each assistant turn as a mix of text and live generative-UI
/// blocks. Each [UiSegment] is rendered via [GenUiBlock] (streaming-tolerant).
///
/// Usage:
/// ```dart
/// GenUiChat(
///   connection: GenUiDirectConnection(
///     adapter: AnthropicAdapter(apiKey: 'sk-ant-...'),
///   ),
/// )
/// ```
class GenUiChat extends StatefulWidget {
  const GenUiChat({
    super.key,
    required this.connection,
    this.onSendMessage,
    this.inputDecoration,
  });

  final GenUiDirectConnection connection;

  /// Optional callback invoked when the user sends a message (before streaming).
  final void Function(String)? onSendMessage;

  /// Optional decoration for the text input field.
  final InputDecoration? inputDecoration;

  @override
  State<GenUiChat> createState() => _GenUiChatState();
}

class _GenUiChatState extends State<GenUiChat> {
  final _controller = TextEditingController();
  final List<_ChatTurn> _turns = [];
  bool _sending = false;

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _sending = true;
      _turns.add(_ChatTurn(userText: text, segments: []));
    });

    widget.onSendMessage?.call(text);

    await for (final segs in widget.connection.sendMessage(text)) {
      setState(() {
        _turns.last = _ChatTurn(userText: text, segments: segs);
      });
    }

    setState(() => _sending = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GenUiActions wires interactive UI controls back into the conversation.
    final actions = GenUiActions(sendMessage: _send);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _turns.length,
            itemBuilder: (context, index) {
              final turn = _turns[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'You: ${turn.userText}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final seg in turn.segments)
                    if (seg is TextSegment)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(seg.markdown),
                      )
                    else if (seg is UiSegment)
                      GenUiBlock(raw: seg.json, actions: actions),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: widget.inputDecoration ??
                      const InputDecoration(hintText: 'Message...'),
                  onSubmitted: _sending ? null : _send,
                ),
              ),
              IconButton(
                onPressed: _sending ? null : () => _send(_controller.text),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatTurn {
  const _ChatTurn({required this.userText, required this.segments});
  final String userText;
  final List<MessageSegment> segments;
}
