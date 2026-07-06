import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../genui_llm_adapter.dart';

/// Streams from Google Gemini's generateContent endpoint using SSE.
///
/// Handles function calling via Gemini's `functionCall` / `functionResponse`
/// Part types. Because Gemini does not assign separate call IDs, the tool
/// name is used as the call ID (one call per tool name per turn).
class GeminiAdapter implements GenUiLlmAdapter {
  GeminiAdapter({
    required this.apiKey,
    this.model = 'gemini-2.0-flash',
    http.Client? client,
  }) : _injectedClient = client;

  final String apiKey;
  final String model;

  /// Optional injected client (tests / connection pooling). When null a
  /// client is created per call and closed when the stream ends. An injected
  /// client is owned by the caller and never closed here.
  final http.Client? _injectedClient;

  @override
  Stream<GenUiStreamEvent> stream(
    List<GenUiMessage> history,
    List<GenUiToolDef> tools,
  ) async* {
    final contents = <Map<String, dynamic>>[];
    String? systemInstruction;

    for (var i = 0; i < history.length; i++) {
      final msg = history[i];
      if (msg.role == 'system') {
        systemInstruction = msg.content;
      } else if (msg.role == 'assistant') {
        // Reconstruct the model turn with text and/or functionCall parts.
        final parts = <Map<String, dynamic>>[];
        if (msg.content != null && msg.content!.isNotEmpty) {
          parts.add({'text': msg.content!});
        }
        if (msg.toolCalls != null) {
          for (final tc in msg.toolCalls!) {
            parts.add({
              'functionCall': {
                'name': tc.name,
                'args': tc.args,
              }
            });
          }
        }
        if (parts.isNotEmpty) {
          contents.add({'role': 'model', 'parts': parts});
        }
      } else if (msg.role == 'tool') {
        // Gemini requires alternating user/model turns, and all function
        // responses for one model turn must arrive as ONE user turn. Group
        // every consecutive tool message into a single `contents` entry with
        // multiple functionResponse parts (mirrors the Anthropic adapter) —
        // otherwise parallel tool calls yield back-to-back user turns and a
        // 400 from the API. The field is `functionResponse` (not
        // `functionResult`).
        final parts = <Map<String, dynamic>>[];
        while (i < history.length && history[i].role == 'tool') {
          final tr = history[i].toolResult!;
          parts.add({
            'functionResponse': {
              'name': tr.toolName,
              'response': tr.result is Map
                  ? tr.result as Map<String, dynamic>
                  : {'result': tr.result},
            }
          });
          i++;
        }
        i--; // outer loop increments past the last grouped message
        contents.add({'role': 'user', 'parts': parts});
      } else {
        // 'user' role
        contents.add({
          'role': 'user',
          'parts': [
            {'text': msg.content ?? ''}
          ],
        });
      }
    }

    final body = <String, dynamic>{
      'contents': contents,
    };
    if (systemInstruction != null) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemInstruction}
        ],
      };
    }
    if (tools.isNotEmpty) {
      body['tools'] = [
        {
          'functionDeclarations': tools
              .map((t) => {
                    'name': t.name,
                    'description': t.description,
                    'parameters': t.parameters,
                  })
              .toList(),
        }
      ];
    }

    // The key goes in the x-goog-api-key HEADER, never the URL query string:
    // package:http's ClientException embeds the request Uri in its toString(),
    // so a key in the query leaks into logs/crash reporters on any transient
    // network failure.
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse',
    );
    final request = http.Request('POST', uri);
    request.headers['content-type'] = 'application/json';
    request.headers['x-goog-api-key'] = apiKey;
    request.body = jsonEncode(body);

    final client = _injectedClient ?? http.Client();
    final ownsClient = _injectedClient == null;
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Gemini API error ${response.statusCode}: $errorBody');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data.isEmpty) continue;

          final json = jsonDecode(data) as Map<String, dynamic>;
          final candidates = json['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) continue;

          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          for (final part in parts ?? []) {
            if (part['text'] != null) {
              yield GenUiTextChunk(part['text'] as String);
            } else if (part['functionCall'] != null) {
              final fc = part['functionCall'] as Map<String, dynamic>;
              final name = fc['name'] as String;
              yield GenUiToolCallEvent(
                // Gemini has no separate call ID — use the name as a stable
                // stand-in so GenUiToolCall.id is always non-null.
                id: name,
                name: name,
                args: (fc['args'] as Map<String, dynamic>?) ?? {},
              );
            }
          }

          final finishReason = candidates[0]['finishReason'] as String?;
          if (finishReason != null && finishReason != 'STOP') {
            yield GenUiStopEvent(stopReason: finishReason);
          }
        }
      }
      yield const GenUiStopEvent(stopReason: 'STOP');
    } finally {
      // Close on success, error, and early cancellation alike — a client per
      // call that is never closed leaks sockets for the app's lifetime. Only
      // close what we created; an injected client belongs to the caller.
      if (ownsClient) client.close();
    }
  }
}
