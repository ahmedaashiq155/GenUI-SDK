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
    final messages = history.map((msg) {
      if (msg.role == 'tool') {
        return {
          'role': 'tool',
          'content': jsonEncode(msg.toolResult!.result),
          'tool_call_id': msg.toolResult!.toolName,
        };
      }
      return {'role': msg.role, 'content': msg.content ?? ''};
    }).toList();

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
            yield GenUiToolCallEvent(name: pendingToolName, args: args);
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
