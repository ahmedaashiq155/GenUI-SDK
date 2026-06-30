import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../genui_llm_adapter.dart';

/// Streams from OpenAI's Chat Completions API using server-sent events (SSE).
///
/// Handles tool calls via the delta `tool_calls` field, accumulating streamed
/// argument chunks and emitting [GenUiToolCallEvent] on `[DONE]`.
class OpenAiAdapter implements GenUiLlmAdapter {
  OpenAiAdapter({
    required this.apiKey,
    this.model = 'gpt-4o',
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
    final messages = <Map<String, dynamic>>[];
    for (final msg in history) {
      if (msg.role == 'tool') {
        // tool_call_id must match the id on the preceding assistant tool_calls entry.
        final tr = msg.toolResult!;
        messages.add({
          'role': 'tool',
          'content': jsonEncode(tr.result),
          'tool_call_id': tr.toolCallId ?? tr.toolName,
        });
      } else if (msg.role == 'assistant' && msg.toolCall != null) {
        // Reconstruct the assistant message with a tool_calls array so OpenAI
        // can match the subsequent tool result. Without this, OpenAI returns 400.
        final tc = msg.toolCall!;
        final entry = <String, dynamic>{
          'role': 'assistant',
          'tool_calls': [
            {
              'id': tc.id ?? tc.name,
              'type': 'function',
              'function': {
                'name': tc.name,
                'arguments': jsonEncode(tc.args),
              },
            }
          ],
        };
        if (msg.content != null && msg.content!.isNotEmpty) {
          entry['content'] = msg.content;
        }
        messages.add(entry);
      } else {
        messages.add({'role': msg.role, 'content': msg.content ?? ''});
      }
    }

    final body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'stream': true,
      'messages': messages,
    };
    if (tools.isNotEmpty) {
      body['tools'] = tools
          .map((t) => {
                'type': 'function',
                'function': {
                  'name': t.name,
                  'description': t.description,
                  'parameters': t.parameters,
                },
              })
          .toList();
    }

    final request = http.Request(
        'POST', Uri.parse('https://api.openai.com/v1/chat/completions'));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['content-type'] = 'application/json';
    request.body = jsonEncode(body);

    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('OpenAI API error ${response.statusCode}: $errorBody');
    }

    String? pendingToolName;
    String? pendingToolId;
    final toolArgBuffer = StringBuffer();

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (data == '[DONE]') {
          if (pendingToolName != null) {
            final args =
                jsonDecode(toolArgBuffer.toString()) as Map<String, dynamic>;
            yield GenUiToolCallEvent(
                name: pendingToolName, args: args, id: pendingToolId);
          }
          yield const GenUiStopEvent(stopReason: 'stop');
          continue;
        }

        final json = jsonDecode(data) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;
        final delta = choices[0]['delta'] as Map<String, dynamic>?;
        if (delta == null) continue;

        if (delta['content'] != null) {
          yield GenUiTextChunk(delta['content'] as String);
        }
        if (delta['tool_calls'] != null) {
          final toolCalls = delta['tool_calls'] as List<dynamic>;
          for (final tc in toolCalls) {
            // Capture the tool-call id from the first chunk that includes it
            if (tc['id'] != null) {
              pendingToolId = tc['id'] as String?;
            }
            final fn = tc['function'] as Map<String, dynamic>?;
            if (fn?['name'] != null) {
              pendingToolName = fn!['name'] as String;
              toolArgBuffer.clear();
            }
            if (fn?['arguments'] != null) {
              toolArgBuffer.write(fn!['arguments'] as String);
            }
          }
        }
      }
    }
  }
}
