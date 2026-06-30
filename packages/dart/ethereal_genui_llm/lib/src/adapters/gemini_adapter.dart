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
  });

  final String apiKey;
  final String model;

  @override
  Stream<GenUiStreamEvent> stream(
    List<GenUiMessage> history,
    List<GenUiToolDef> tools,
  ) async* {
    final contents = <Map<String, dynamic>>[];
    String? systemInstruction;

    for (final msg in history) {
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
        // Each tool result goes as a user message with a functionResponse part.
        // The Gemini API field is `functionResponse` (not `functionResult`).
        final tr = msg.toolResult!;
        contents.add({
          'role': 'user',
          'parts': [
            {
              'functionResponse': {
                'name': tr.toolName,
                'response': tr.result is Map
                    ? tr.result as Map<String, dynamic>
                    : {'result': tr.result},
              }
            }
          ],
        });
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

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey',
    );
    final request = http.Request('POST', uri);
    request.headers['content-type'] = 'application/json';
    request.body = jsonEncode(body);

    final response = await http.Client().send(request);
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
  }
}
