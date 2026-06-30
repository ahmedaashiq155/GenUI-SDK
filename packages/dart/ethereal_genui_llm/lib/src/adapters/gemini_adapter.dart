import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../genui_llm_adapter.dart';

/// Streams from Google Gemini's generateContent endpoint using SSE.
///
/// Maps Gemini's `model` role to `assistant`, extracts text parts from
/// candidates, and emits [GenUiStopEvent] on non-null finishReason.
///
/// Note: Gemini tool-use support is basic (text-only at this stage).
/// Tool definitions are not sent to the API in this adapter; full function
/// calling support can be added in a future iteration.
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
      } else {
        final role = msg.role == 'assistant' ? 'model' : 'user';
        contents.add({
          'role': role,
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
