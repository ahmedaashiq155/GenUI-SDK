import 'package:ethereal_genui_core/ethereal_genui_core.dart';
import 'package:ethereal_genui_llm/ethereal_genui_llm.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mock adapter
// ---------------------------------------------------------------------------

/// Controls what the adapter emits on each call to [stream].
class MockAdapter implements GenUiLlmAdapter {
  /// Queue of event lists, one per [stream] call.
  final List<List<GenUiStreamEvent>> _responses = [];
  final List<List<GenUiMessage>> capturedHistories = [];
  int callCount = 0;

  void addResponse(List<GenUiStreamEvent> events) {
    _responses.add(events);
  }

  @override
  Stream<GenUiStreamEvent> stream(
    List<GenUiMessage> history,
    List<GenUiToolDef> tools,
  ) async* {
    capturedHistories.add(List.unmodifiable(history));
    final events = _responses[callCount++];
    for (final event in events) {
      yield event;
    }
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GenUiDirectConnection', () {
    // -----------------------------------------------------------------------
    // 1. Text-only response
    // -----------------------------------------------------------------------
    test('text-only response yields TextSegment list', () async {
      final adapter = MockAdapter();
      adapter.addResponse([
        const GenUiTextChunk('Hello '),
        const GenUiTextChunk('world'),
        const GenUiStopEvent(stopReason: 'end_turn'),
      ]);

      final connection = GenUiDirectConnection(
        adapter: adapter,
        injectGenUiCatalogue: false,
      );

      final allYields = <List<MessageSegment>>[];
      await for (final segs in connection.sendMessage('Hi')) {
        allYields.add(segs);
      }

      expect(allYields, isNotEmpty);
      final lastYield = allYields.last;
      expect(lastYield, isNotEmpty);
      expect(lastYield.first, isA<TextSegment>());
      final text = (lastYield.first as TextSegment).markdown;
      expect(text, contains('Hello'));
      expect(text, contains('world'));
    });

    // -----------------------------------------------------------------------
    // 2. Tool-use loop
    // -----------------------------------------------------------------------
    test('tool-use loop calls handler once and produces correct history',
        () async {
      final adapter = MockAdapter();

      // First adapter call: tool invocation
      adapter.addResponse([
        const GenUiToolCallEvent(
            name: 'get_weather', args: {'city': 'Sydney'}),
        const GenUiStopEvent(stopReason: 'tool_use'),
      ]);

      // Second adapter call: final text after tool result
      adapter.addResponse([
        const GenUiTextChunk('The weather in Sydney is sunny.'),
        const GenUiStopEvent(stopReason: 'end_turn'),
      ]);

      final connection = GenUiDirectConnection(
        adapter: adapter,
        injectGenUiCatalogue: false,
      );

      int handlerCallCount = 0;
      Map<String, dynamic>? capturedArgs;

      connection.registerTool(
        name: 'get_weather',
        description: 'Get weather for a city',
        parameters: {
          'type': 'object',
          'properties': {
            'city': {'type': 'string'},
          },
          'required': ['city'],
        },
        handler: (args) async {
          handlerCallCount++;
          capturedArgs = args;
          return {'condition': 'sunny', 'temp': 24};
        },
      );

      final allYields = <List<MessageSegment>>[];
      await for (final segs in connection.sendMessage('What is the weather?')) {
        allYields.add(segs);
      }

      // Tool handler called exactly once with correct args
      expect(handlerCallCount, equals(1));
      expect(capturedArgs, equals({'city': 'Sydney'}));

      // History: user + assistant (empty, tool call) + tool + assistant (final)
      final history = connection.history;
      expect(history.length, equals(4));
      expect(history[0].role, equals('user'));
      expect(history[1].role, equals('assistant'));
      expect(history[2].role, equals('tool'));
      expect(history[2].toolResult!.toolName, equals('get_weather'));
      expect(history[3].role, equals('assistant'));
      expect(history[3].content, contains('Sydney'));
    });

    // -----------------------------------------------------------------------
    // 3. System prompt injection
    // -----------------------------------------------------------------------
    test('system prompt injection includes buildGenUiPromptCatalogue()',
        () async {
      final adapter = MockAdapter();
      adapter.addResponse([
        const GenUiTextChunk('OK'),
        const GenUiStopEvent(stopReason: 'end_turn'),
      ]);

      final connection = GenUiDirectConnection(
        adapter: adapter,
        injectGenUiCatalogue: true,
        systemPrompt: 'Be helpful.',
      );

      await for (final _ in connection.sendMessage('Hello')) {
        // consume stream
      }

      expect(adapter.capturedHistories, isNotEmpty);
      final history = adapter.capturedHistories.first;

      // First message should be the system message
      expect(history.first.role, equals('system'));
      final systemContent = history.first.content ?? '';

      // Should contain the catalogue
      expect(systemContent, contains(buildGenUiPromptCatalogue()));

      // Should also contain the user-supplied system prompt
      expect(systemContent, contains('Be helpful.'));
    });

    // -----------------------------------------------------------------------
    // 4. reset()
    // -----------------------------------------------------------------------
    test('reset() clears conversation history', () async {
      final adapter = MockAdapter();
      adapter.addResponse([
        const GenUiTextChunk('Hi there'),
        const GenUiStopEvent(stopReason: 'end_turn'),
      ]);

      final connection = GenUiDirectConnection(
        adapter: adapter,
        injectGenUiCatalogue: false,
      );

      await for (final _ in connection.sendMessage('Hello')) {
        // consume stream
      }

      expect(connection.history, isNotEmpty);

      connection.reset();

      expect(connection.history, isEmpty);
    });
  });
}
