import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../genui_llm_adapter.dart';

/// Streams from Anthropic's Messages API using server-sent events (SSE).
///
/// Handles tool-use via Anthropic's content-block protocol:
/// `content_block_start` (type=tool_use) → `input_json_delta` chunks →
/// `content_block_stop` → emit [GenUiToolCallEvent].
class AnthropicAdapter implements GenUiLlmAdapter {
  AnthropicAdapter({
    required this.apiKey,
    this.model = 'claude-sonnet-4-6',
    this.maxTokens = 8192,
    http.Client? client,
  }) : _injectedClient = client;

  final String apiKey;
  final String model;
  final int maxTokens;

  /// Optional injected client (tests / connection pooling). When null a
  /// client is created per call and closed when the stream ends. An injected
  /// client is owned by the caller and never closed here.
  final http.Client? _injectedClient;

  @override
  Stream<GenUiStreamEvent> stream(
    List<GenUiMessage> history,
    List<GenUiToolDef> tools,
  ) async* {
    // Build Anthropic messages format; system message is handled separately.
    // Consecutive tool-result messages are grouped into a single user message.
    String? systemPrompt;
    final messages = <Map<String, dynamic>>[];

    int i = 0;
    while (i < history.length) {
      final msg = history[i];
      if (msg.role == 'system') {
        systemPrompt = msg.content;
        i++;
      } else if (msg.role == 'user') {
        messages.add({'role': 'user', 'content': msg.content ?? ''});
        i++;
      } else if (msg.role == 'assistant') {
        // Reconstruct Anthropic content array: optional text block + tool_use
        // blocks. Without the tool_use blocks, the subsequent tool_result has
        // no matching tool_use_id and Anthropic returns 400.
        if (msg.toolCalls != null && msg.toolCalls!.isNotEmpty) {
          final contentBlocks = <Map<String, dynamic>>[];
          if (msg.content != null && msg.content!.isNotEmpty) {
            contentBlocks.add({'type': 'text', 'text': msg.content});
          }
          for (final tc in msg.toolCalls!) {
            contentBlocks.add({
              'type': 'tool_use',
              'id': tc.id,
              'name': tc.name,
              'input': tc.args,
            });
          }
          messages.add({'role': 'assistant', 'content': contentBlocks});
        } else {
          messages.add({'role': 'assistant', 'content': msg.content ?? ''});
        }
        i++;
      } else if (msg.role == 'tool') {
        // Collect ALL consecutive tool messages into one user message with
        // multiple tool_result entries (required by Anthropic API).
        final toolResults = <Map<String, dynamic>>[];
        while (i < history.length && history[i].role == 'tool') {
          final tr = history[i].toolResult!;
          toolResults.add({
            'type': 'tool_result',
            'tool_use_id': tr.toolCallId,
            'content': jsonEncode(tr.result),
          });
          i++;
        }
        messages.add({'role': 'user', 'content': toolResults});
      } else {
        i++;
      }
    }

    final body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'stream': true,
      'messages': messages,
    };
    if (systemPrompt != null) body['system'] = systemPrompt;
    if (tools.isNotEmpty) {
      body['tools'] = tools
          .map((t) => {
                'name': t.name,
                'description': t.description,
                'input_schema': t.parameters,
              })
          .toList();
    }

    final request =
        http.Request('POST', Uri.parse('https://api.anthropic.com/v1/messages'));
    request.headers['x-api-key'] = apiKey;
    request.headers['anthropic-version'] = '2023-06-01';
    request.headers['content-type'] = 'application/json';
    request.body = jsonEncode(body);

    final client = _injectedClient ?? http.Client();
    final ownsClient = _injectedClient == null;
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception(
            'Anthropic API error ${response.statusCode}: $errorBody');
      }

      String? currentToolName;
      String? currentToolId;
      final toolInputBuffer = StringBuffer();

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]' || data.isEmpty) continue;

          final json = jsonDecode(data) as Map<String, dynamic>;
          final type = json['type'] as String?;

          if (type == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            if (delta?['type'] == 'text_delta') {
              yield GenUiTextChunk(delta!['text'] as String);
            } else if (delta?['type'] == 'input_json_delta') {
              toolInputBuffer.write(delta!['partial_json'] as String);
            }
          } else if (type == 'content_block_start') {
            final block = json['content_block'] as Map<String, dynamic>?;
            if (block?['type'] == 'tool_use') {
              currentToolName = block!['name'] as String;
              // Anthropic always provides an id for tool_use blocks (toolu_xxx).
              currentToolId = block['id'] as String;
              toolInputBuffer.clear();
            }
          } else if (type == 'content_block_stop') {
            if (currentToolName != null) {
              final rawInput = toolInputBuffer.toString();
              final args = rawInput.isEmpty
                  ? <String, dynamic>{}
                  : jsonDecode(rawInput) as Map<String, dynamic>;
              yield GenUiToolCallEvent(
                id: currentToolId!,
                name: currentToolName,
                args: args,
              );
              currentToolName = null;
              currentToolId = null;
            }
          } else if (type == 'message_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            yield GenUiStopEvent(stopReason: delta?['stop_reason'] as String?);
          }
        }
      }
    } finally {
      // Close on success, error, and early cancellation alike — a client per
      // call that is never closed leaks sockets for the app's lifetime. Only
      // close what we created; an injected client belongs to the caller.
      if (ownsClient) client.close();
    }
  }
}
