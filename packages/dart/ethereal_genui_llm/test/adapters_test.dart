import 'dart:async';
import 'dart:convert';

import 'package:ethereal_genui_llm/ethereal_genui_llm.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// A MockClient.streaming that records the last request it saw and replays a
/// canned SSE body as a byte stream (optionally split across chunks to exercise
/// the UTF-8 decoder / LineSplitter boundary handling).
class _Recorder {
  http.BaseRequest? request;
  String? body;

  MockClient client(List<String> sseChunks, {int status = 200}) {
    return MockClient.streaming((req, bodyStream) async {
      request = req;
      body = await utf8.decodeStream(bodyStream);
      final stream = Stream<List<int>>.fromIterable(
          sseChunks.map((c) => utf8.encode(c)));
      return http.StreamedResponse(stream, status);
    });
  }
}

void main() {
  group('GeminiAdapter', () {
    test('sends the API key in the x-goog-api-key header, never the URL', () async {
      final rec = _Recorder();
      final adapter = GeminiAdapter(
        apiKey: 'SECRET_KEY',
        client: rec.client(['data: {"candidates":[{"content":{"parts":[{"text":"hi"}]},"finishReason":"STOP"}]}\n']),
      );
      await adapter.stream([
        const GenUiMessage(role: 'user', content: 'hello'),
      ], const []).toList();

      expect(rec.request!.url.toString(), isNot(contains('SECRET_KEY')));
      expect(rec.request!.url.query, isNot(contains('key=')));
      expect(rec.request!.headers['x-goog-api-key'], 'SECRET_KEY');
    });

    test('groups consecutive tool results into ONE user turn (parallel calls)',
        () async {
      final rec = _Recorder();
      final adapter = GeminiAdapter(
        apiKey: 'k',
        client: rec.client(['data: {"candidates":[{"content":{"parts":[{"text":"ok"}]},"finishReason":"STOP"}]}\n']),
      );
      await adapter.stream([
        const GenUiMessage(role: 'user', content: 'weather in 2 cities'),
        const GenUiMessage(role: 'assistant', toolCalls: [
          GenUiToolCall(id: 'getWeather', name: 'getWeather', args: {'city': 'A'}),
          GenUiToolCall(id: 'getTime', name: 'getTime', args: {'city': 'A'}),
        ]),
        const GenUiMessage(
            role: 'tool',
            toolResult: GenUiToolResult(
                toolName: 'getWeather', result: {'t': 20}, toolCallId: 'getWeather')),
        const GenUiMessage(
            role: 'tool',
            toolResult: GenUiToolResult(
                toolName: 'getTime', result: {'h': 9}, toolCallId: 'getTime')),
      ], const []).toList();

      final decoded = jsonDecode(rec.body!) as Map<String, dynamic>;
      final contents = decoded['contents'] as List<dynamic>;
      // user turn, model turn, then ONE grouped user turn with both responses —
      // not two back-to-back user turns (which Gemini rejects with a 400).
      final toolTurns = contents
          .where((c) => (c['role'] == 'user') &&
              (c['parts'] as List).any((p) => (p as Map).containsKey('functionResponse')))
          .toList();
      expect(toolTurns, hasLength(1));
      expect((toolTurns.single['parts'] as List), hasLength(2));
    });

    test('parses text and functionCall parts across split SSE chunks', () async {
      final rec = _Recorder();
      // The same JSON line delivered in two network chunks split mid-token.
      const line =
          'data: {"candidates":[{"content":{"parts":[{"text":"Hi "},{"functionCall":{"name":"go","args":{"x":1}}}]}}]}\n';
      final split = line.length ~/ 2;
      final adapter = GeminiAdapter(
        apiKey: 'k',
        client: rec.client([line.substring(0, split), line.substring(split)]),
      );

      final events = await adapter.stream([
        const GenUiMessage(role: 'user', content: 'go'),
      ], const []).toList();

      final text = events.whereType<GenUiTextChunk>().map((e) => e.delta).join();
      final calls = events.whereType<GenUiToolCallEvent>().toList();
      expect(text, 'Hi ');
      expect(calls, hasLength(1));
      expect(calls.single.name, 'go');
      expect(calls.single.args, {'x': 1});
    });

    test('throws (not silently) on a non-200 status', () async {
      final rec = _Recorder();
      final adapter = GeminiAdapter(
        apiKey: 'k',
        client: rec.client(['bad request'], status: 400),
      );
      expect(
        adapter.stream([const GenUiMessage(role: 'user', content: 'x')], const []).toList(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AnthropicAdapter', () {
    test('key goes in the x-api-key header; SSE tool_use is parsed', () async {
      final rec = _Recorder();
      final adapter = AnthropicAdapter(
        apiKey: 'ANTH',
        client: rec.client([
          'data: {"type":"content_block_start","content_block":{"type":"tool_use","id":"toolu_1","name":"go"}}\n',
          'data: {"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":"{\\"x\\":"}}\n',
          'data: {"type":"content_block_delta","delta":{"type":"input_json_delta","partial_json":"1}"}}\n',
          'data: {"type":"content_block_stop"}\n',
          'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}\n',
        ]),
      );

      final events = await adapter.stream([
        const GenUiMessage(role: 'user', content: 'go'),
      ], const []).toList();

      expect(rec.request!.headers['x-api-key'], 'ANTH');
      final calls = events.whereType<GenUiToolCallEvent>().toList();
      expect(calls, hasLength(1));
      expect(calls.single.id, 'toolu_1');
      expect(calls.single.args, {'x': 1});
    });
  });

  group('OpenAiAdapter', () {
    test('key goes in the Authorization header; parallel tool_calls parse on [DONE]',
        () async {
      final rec = _Recorder();
      final adapter = OpenAiAdapter(
        apiKey: 'OA',
        client: rec.client([
          'data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"c0","function":{"name":"a","arguments":"{}"}}]}}]}\n',
          'data: {"choices":[{"delta":{"tool_calls":[{"index":1,"id":"c1","function":{"name":"b","arguments":"{}"}}]}}]}\n',
          'data: [DONE]\n',
        ]),
      );

      final events = await adapter.stream([
        const GenUiMessage(role: 'user', content: 'go'),
      ], const []).toList();

      expect(rec.request!.headers['Authorization'], 'Bearer OA');
      final calls = events.whereType<GenUiToolCallEvent>().toList();
      expect(calls.map((c) => c.name).toSet(), {'a', 'b'});
    });
  });
}
