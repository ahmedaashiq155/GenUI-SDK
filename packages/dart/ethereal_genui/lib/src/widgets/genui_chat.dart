import 'package:flutter/material.dart';
import 'package:ethereal_genui_core/ethereal_genui_core.dart';
import 'package:ethereal_genui_llm/ethereal_genui_llm.dart';
import '../genui_actions.dart';
import '../genui_block.dart';
import '../genui_localizations.dart';
import '../genui_theme.dart';

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
///
/// ⚠️ A [GenUiDirectConnection] built with a raw provider key ships that key
/// inside the app and is unsafe for production — prototyping/internal only.
/// See the security note on `GenUiDirectConnection` for the proxy pattern.
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
    if (_sending || text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _sending = true;
      _turns.add(_ChatTurn(userText: text, segments: []));
    });

    widget.onSendMessage?.call(text);

    // The stream can outlive this State (user navigates away mid-response) —
    // guard every setState after an await, or the next chunk throws
    // "setState() called after dispose()".
    try {
      await for (final segs in widget.connection.sendMessage(text)) {
        if (!mounted) return;
        setState(() {
          _turns.last = _ChatTurn(userText: text, segments: segs);
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = GenUiLocalizations.of(context);
    final theme = GenUiTheme.of(context);
    // GenUiActions wires interactive UI controls back into the conversation.
    final actions = GenUiActions(sendMessage: _send, enabled: !_sending);

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
                    padding: const EdgeInsets.all(GenUiSpace.sm),
                    child: Text(
                      'You: ${turn.userText}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final seg in turn.segments)
                    if (seg is TextSegment)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: GenUiSpace.sm,
                        ),
                        child: Text(seg.markdown),
                      )
                    else if (seg is UiSegment)
                      GenUiBlock(
                        raw: seg.json,
                        actions: actions,
                        closed: seg.closed,
                      ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(theme.spacing.sm),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_sending,
                  decoration:
                      widget.inputDecoration ??
                      InputDecoration(
                        hintText: strings.text(
                          GenUiStringKey.messageHint,
                          'Message…',
                        ),
                      ),
                  onSubmitted: _sending ? null : _send,
                ),
              ),
              IconButton(
                onPressed: _sending ? null : () => _send(_controller.text),
                tooltip: strings.text(GenUiStringKey.send, 'Send'),
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
