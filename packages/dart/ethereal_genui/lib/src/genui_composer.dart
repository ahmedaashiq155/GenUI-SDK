import 'dart:async';

import 'package:flutter/material.dart';

import 'genui_actions.dart';
import 'genui_input.dart';
import 'genui_localizations.dart';
import 'genui_theme.dart';
import 'genui_voice.dart';

/// Dependency-free multimodal composer. Picking, permission prompts, malware
/// scanning, upload and transport remain explicit host responsibilities.
class GenUiComposer extends StatefulWidget {
  const GenUiComposer({
    super.key,
    required this.actions,
    this.pickAttachments,
    this.voiceController,
    this.decoration,
    this.maxAttachments = 8,
  });

  final GenUiActions actions;
  final GenUiAttachmentPicker? pickAttachments;
  final GenUiVoiceController? voiceController;
  final InputDecoration? decoration;
  final int maxAttachments;

  @override
  State<GenUiComposer> createState() => _GenUiComposerState();
}

class _GenUiComposerState extends State<GenUiComposer> {
  final _controller = TextEditingController();
  final _attachments = <GenUiAttachment>[];
  bool _sending = false;

  bool get _canSend {
    if (_sending || !widget.actions.enabled) return false;
    if (_controller.text.trim().isEmpty && _attachments.isEmpty) return false;
    return _attachments.isEmpty || widget.actions.sendInput != null;
  }

  Future<void> _pick() async {
    final picker = widget.pickAttachments;
    if (picker == null || widget.actions.sendInput == null) return;
    final picked = await picker();
    if (!mounted) return;
    final remaining = widget.maxAttachments.clamp(0, 100) - _attachments.length;
    if (remaining <= 0) return;
    setState(() => _attachments.addAll(picked.take(remaining)));
  }

  Future<void> _send() async {
    if (!_canSend) return;
    final input = GenUiMessageInput(
      text: _controller.text.trim(),
      attachments: List.unmodifiable(_attachments),
    );
    setState(() => _sending = true);
    try {
      if (input.attachments.isNotEmpty) {
        await widget.actions.sendInput!.call(input);
      } else {
        widget.actions.sendMessage(input.text);
      }
      if (!mounted) return;
      _controller.clear();
      _attachments.clear();
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
    final canAttach =
        widget.pickAttachments != null &&
        widget.actions.sendInput != null &&
        _attachments.length < widget.maxAttachments.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_attachments.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: theme.spacing.sm),
            child: Wrap(
              spacing: theme.spacing.sm,
              runSpacing: theme.spacing.sm,
              children: [
                for (final attachment in _attachments)
                  InputChip(
                    label: Text(attachment.name),
                    onDeleted: widget.actions.enabled && !_sending
                        ? () => setState(() => _attachments.remove(attachment))
                        : null,
                    deleteButtonTooltipMessage: strings.text(
                      GenUiStringKey.removeAttachment,
                      'Remove attachment',
                    ),
                  ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.pickAttachments != null)
              IconButton(
                onPressed: canAttach ? _pick : null,
                tooltip: strings.text(
                  GenUiStringKey.addAttachment,
                  'Add attachment',
                ),
                icon: const Icon(Icons.attach_file_rounded),
              ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.actions.enabled && !_sending,
                minLines: 1,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _send(),
                decoration:
                    widget.decoration ??
                    InputDecoration(
                      hintText: strings.text(
                        GenUiStringKey.messageHint,
                        'Message…',
                      ),
                    ),
              ),
            ),
            if (widget.voiceController != null)
              GenUiVoiceButton(
                controller: widget.voiceController!,
                onTranscript: (text) {
                  _controller.text = text;
                  _controller.selection = TextSelection.collapsed(
                    offset: text.length,
                  );
                  setState(() {});
                },
              ),
            IconButton(
              onPressed: _canSend ? _send : null,
              tooltip: strings.text(GenUiStringKey.send, 'Send'),
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
