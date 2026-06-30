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
          'tool_call_id': tr.toolCallId,
        });
      } else if (msg.role == 'assistant' &&
          msg.toolCalls != null &&
          msg.toolCalls!.isNotEmpty) {
        // Reconstruct the assistant message with a tool_calls array so OpenAI
        // can match the subsequent tool results. Without this, OpenAI returns 400.
        final entry = <String, dynamic>{
          'role': 'assistant',
          'content': msg.content, // may be null; OpenAI accepts null here
          'tool_calls': msg.toolCalls!
              .map((tc) => {
                    'id': tc.id,
                    'type': 'function',
                    'function': {
                      'name': tc.name,
                      'arguments': jsonEncode(tc.args),
                    },
                  })
              .toList(),
        };
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

    // Map from tool_calls[].index → (name, id, argsBuffer) for parallel calls.
    final toolCallsById =
        <int, ({String name, String? id, StringBuffer args})>{};

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.startsWith('data: ')) {
        final data = line.substring(6).trim();
        if (data == '[DONE]') {
          for (final entry in toolCallsById.entries) {
            final tc = entry.value;
            final rawArgs = tc.args.toString();
            final args = rawArgs.isEmpty
                ? <String, dynamic>{}
                : jsonDecode(rawArgs) as Map<String, dynamic>;
            // OpenAI always provides a tool call id; use the name as a
            // fallback only to be defensive (should not happen in practice).
            yield GenUiToolCallEvent(
              id: tc.id ?? tc.name,
              name: tc.name,
              args: args,
            );
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
            final index = (tc['index'] as num).toInt();
            final fn = tc['function'] as Map<String, dynamic>?;
            if (fn?['name'] != null) {
              // First chunk for this index carries the name (and possibly id).
              toolCallsById[index] = (
                name: fn!['name'] as String,
                id: tc['id'] as String?,
                args: StringBuffer(),
              );
            } else if (tc['id'] != null && toolCallsById.containsKey(index)) {
              // id may arrive in a subsequent chunk; update in place.
              final existing = toolCallsById[index]!;
              toolCallsById[index] =
                  (name: existing.name, id: tc['id'] as String?, args: existing.args);
            }
            if (fn?['arguments'] != null && toolCallsById.containsKey(index)) {
              toolCallsById[index]!.args.write(fn!['arguments'] as String);
            }
          }
        }
      }
    }
  }
}
