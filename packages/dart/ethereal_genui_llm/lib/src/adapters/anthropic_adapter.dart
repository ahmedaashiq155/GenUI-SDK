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
  });

  final String apiKey;
  final String model;
  final int maxTokens;

  @override
  Stream<GenUiStreamEvent> stream(
    List<GenUiMessage> history,
    List<GenUiToolDef> tools,
  ) async* {
    // Build Anthropic messages format; system message is handled separately
    String? systemPrompt;
    final messages = <Map<String, dynamic>>[];

    for (final msg in history) {
      if (msg.role == 'system') {
        systemPrompt = msg.content;
      } else if (msg.role == 'user') {
        messages.add({'role': 'user', 'content': msg.content ?? ''});
      } else if (msg.role == 'assistant') {
        messages.add({'role': 'assistant', 'content': msg.content ?? ''});
      } else if (msg.role == 'tool') {
        // Tool results go as user messages in Anthropic format
        messages.add({
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': msg.toolResult!.toolName,
              'content': jsonEncode(msg.toolResult!.result),
            }
          ],
        });
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

    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
          'Anthropic API error ${response.statusCode}: $errorBody');
    }

    String? currentToolName;
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
            toolInputBuffer.clear();
          }
        } else if (type == 'content_block_stop') {
          if (currentToolName != null) {
            final args =
                jsonDecode(toolInputBuffer.toString()) as Map<String, dynamic>;
            yield GenUiToolCallEvent(name: currentToolName, args: args);
            currentToolName = null;
          }
        } else if (type == 'message_delta') {
          final delta = json['delta'] as Map<String, dynamic>?;
          yield GenUiStopEvent(stopReason: delta?['stop_reason'] as String?);
        }
      }
    }
  }
}
