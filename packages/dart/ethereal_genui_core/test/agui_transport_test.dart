import 'package:ag_ui/ag_ui.dart';
import 'package:ethereal_genui_core/ethereal_genui_core.dart';
import 'package:test/test.dart';

void main() {
  group('stateSnapshotToSpec', () {
    test('extracts ui key from STATE_SNAPSHOT', () {
      final event = StateSnapshotEvent(
        snapshot: {
          'ui': {'type': 'choices', 'options': ['A', 'B']},
        },
      );
      final spec = stateSnapshotToSpec(event);
      expect(spec, isNotNull);
      expect(spec!['type'], equals('choices'));
      expect(spec['options'], equals(['A', 'B']));
    });

    test('returns null when snapshot has no ui key', () {
      final event = StateSnapshotEvent(snapshot: {'other': 'data'});
      expect(stateSnapshotToSpec(event), isNull);
    });

    test('returns null for non-StateSnapshotEvent', () {
      final event = RunStartedEvent(
        threadId: 't1',
        runId: 'r1',
      );
      expect(stateSnapshotToSpec(event), isNull);
    });
  });

  group('applyStateDelta (STATE_DELTA via applyJsonPatch)', () {
    test('applies RFC-6902 replace op to spec on map keys', () {
      final initial = <String, dynamic>{
        'type': 'choices',
        'label': 'Pick one',
      };
      final delta = StateDeltaEvent(delta: [
        {'op': 'replace', 'path': '/label', 'value': 'Choose'},
      ]);
      final result = applyStateDelta(initial, delta);
      expect(result, isA<Map>());
      final resultMap = result as Map;
      expect(resultMap['label'], equals('Choose'));
      expect(resultMap['type'], equals('choices'));
    });

    test('applies RFC-6902 replace op to list index (in-place, not insert)', () {
      // This is the scenario prescribed in the Task 3 brief:
      // replace at /options/0 must overwrite index 0, not insert a new element.
      final initial = <String, dynamic>{
        'type': 'choices',
        'options': ['A', 'B'],
      };
      final delta = StateDeltaEvent(delta: [
        {'op': 'replace', 'path': '/options/0', 'value': 'C'},
      ]);
      final result = applyStateDelta(initial, delta) as Map;
      expect(result['options'], equals(['C', 'B']));
    });

    test('applies add op', () {
      final initial = <String, dynamic>{'type': 'form'};
      final delta = StateDeltaEvent(delta: [
        {'op': 'add', 'path': '/title', 'value': 'My Form'},
      ]);
      final result = applyStateDelta(initial, delta) as Map;
      expect(result['title'], equals('My Form'));
    });

    test('applies remove op', () {
      final initial = <String, dynamic>{'type': 'form', 'title': 'Old'};
      final delta = StateDeltaEvent(delta: [
        {'op': 'remove', 'path': '/title'},
      ]);
      final result = applyStateDelta(initial, delta) as Map;
      expect(result.containsKey('title'), isFalse);
    });

    test('returns currentSpec unchanged for non-StateDeltaEvent', () {
      final initial = <String, dynamic>{'type': 'form'};
      final event = RunFinishedEvent(threadId: 't1', runId: 'r1');
      expect(applyStateDelta(initial, event), same(initial));
    });
  });

  group('AguiEventProcessor', () {
    late AguiEventProcessor processor;

    setUp(() {
      processor = AguiEventProcessor();
    });

    test('isRunning transitions on RUN_STARTED → RUN_FINISHED', () {
      expect(processor.isRunning, isFalse);

      processor.processEvent(RunStartedEvent(threadId: 't1', runId: 'r1'));
      expect(processor.isRunning, isTrue);

      processor.processEvent(RunFinishedEvent(threadId: 't1', runId: 'r1'));
      expect(processor.isRunning, isFalse);
    });

    test('uiSpec is populated after STATE_SNAPSHOT', () {
      processor.processEvent(RunStartedEvent(threadId: 't1', runId: 'r1'));
      processor.processEvent(StateSnapshotEvent(
        snapshot: {
          'ui': {'type': 'text', 'content': 'Hello'},
        },
      ));
      expect(processor.uiSpec['type'], equals('text'));
      expect(processor.uiSpec['content'], equals('Hello'));
    });

    test('streamingText accumulates and clears on MESSAGE sequence', () {
      processor.processEvent(TextMessageStartEvent(messageId: 'm1'));
      expect(processor.streamingText, equals(''));

      processor.processEvent(
          TextMessageContentEvent(messageId: 'm1', delta: 'Hello'));
      processor.processEvent(
          TextMessageContentEvent(messageId: 'm1', delta: ', world'));
      expect(processor.streamingText, equals('Hello, world'));

      processor.processEvent(TextMessageEndEvent(messageId: 'm1'));
      expect(processor.streamingText, isNull);
      // The text should have been archived to messages.
      expect(processor.messages.any((m) => m['raw'] == 'Hello, world'),
          isTrue);
    });

    test('full sequence RUN_STARTED → STATE_SNAPSHOT → TEXT → RUN_FINISHED', () {
      final events = [
        RunStartedEvent(threadId: 't1', runId: 'r1'),
        StateSnapshotEvent(
          snapshot: {
            'ui': {'type': 'choices', 'options': ['A', 'B']},
          },
        ),
        TextMessageStartEvent(messageId: 'm1'),
        TextMessageContentEvent(messageId: 'm1', delta: 'Pick one'),
        TextMessageEndEvent(messageId: 'm1'),
        RunFinishedEvent(threadId: 't1', runId: 'r1'),
      ];

      for (final e in events) {
        processor.processEvent(e);
      }

      expect(processor.isRunning, isFalse);
      expect(processor.uiSpec['type'], equals('choices'));
      expect(processor.streamingText, isNull);
    });

    test('RUN_ERROR sets errorMessage and clears isRunning', () {
      processor.processEvent(RunStartedEvent(threadId: 't1', runId: 'r1'));
      processor
          .processEvent(RunErrorEvent(message: 'Something went wrong'));
      expect(processor.isRunning, isFalse);
      expect(processor.errorMessage, equals('Something went wrong'));
    });

    test('STATE_DELTA patches uiSpec', () {
      processor.processEvent(StateSnapshotEvent(
        snapshot: {
          'ui': {'type': 'choices', 'label': 'Pick one'},
        },
      ));
      processor.processEvent(StateDeltaEvent(delta: [
        {'op': 'replace', 'path': '/label', 'value': 'Choose'},
      ]));
      expect(processor.uiSpec['label'], equals('Choose'));
      expect(processor.uiSpec['type'], equals('choices'));
    });

    test('listeners are notified on state change', () {
      var notifyCount = 0;
      processor.addListener(() => notifyCount++);

      processor.processEvent(RunStartedEvent(threadId: 't1', runId: 'r1'));
      processor.processEvent(RunFinishedEvent(threadId: 't1', runId: 'r1'));

      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('removeListener stops notifications', () {
      var count = 0;
      void listener() => count++;
      processor.addListener(listener);
      processor.processEvent(RunStartedEvent(threadId: 't1', runId: 'r1'));
      expect(count, equals(1));

      processor.removeListener(listener);
      processor.processEvent(RunFinishedEvent(threadId: 't1', runId: 'r1'));
      expect(count, equals(1)); // no further increments
    });

    test('CUSTOM event routes to registered handler', () {
      String? receivedName;
      processor.registerCustomHandler('my_event', (e) {
        receivedName = e.name;
      });
      processor.processEvent(
          CustomEvent(name: 'my_event', value: {'key': 'val'}));
      expect(receivedName, equals('my_event'));
    });

    test('unregistered CUSTOM event is ignored without error', () {
      expect(
        () => processor
            .processEvent(CustomEvent(name: 'unknown_event', value: null)),
        returnsNormally,
      );
    });

    test('tool call lifecycle stores result in messages', () {
      processor.processEvent(ToolCallStartEvent(
        toolCallId: 'tc1',
        toolCallName: 'search',
      ));
      processor
          .processEvent(ToolCallArgsEvent(toolCallId: 'tc1', delta: '{"q":'));
      processor
          .processEvent(ToolCallArgsEvent(toolCallId: 'tc1', delta: '"AI"}'));
      processor.processEvent(ToolCallEndEvent(toolCallId: 'tc1'));

      final toolMsg = processor.messages
          .firstWhere((m) => m['role'] == 'tool_call', orElse: () => {});
      expect(toolMsg['toolName'], equals('search'));
      expect(toolMsg['args'], equals('{"q":"AI"}'));
    });
  });

  group('stateChangedToDelta', () {
    test('returns null when states are identical', () {
      final state = {'toggle': true, 'count': 1};
      expect(stateChangedToDelta(state, Map.from(state)), isNull);
    });

    test('produces replace op for changed key', () {
      final delta = stateChangedToDelta(
        {'toggle': false, 'count': 1},
        {'toggle': true, 'count': 1},
      );
      expect(delta, isNotNull);
      expect(delta!.delta.length, equals(1));
      expect(delta.delta[0]['op'], equals('replace'));
      expect(delta.delta[0]['path'], equals('/toggle'));
      expect(delta.delta[0]['value'], isTrue);
    });

    test('produces add op for new key', () {
      final delta = stateChangedToDelta(
        {'a': 1},
        {'a': 1, 'b': 2},
      );
      expect(delta, isNotNull);
      expect(delta!.delta.any((op) => op['op'] == 'add' && op['path'] == '/b'),
          isTrue);
    });

    test('produces remove op for deleted key', () {
      final delta = stateChangedToDelta(
        {'a': 1, 'b': 2},
        {'a': 1},
      );
      expect(delta, isNotNull);
      expect(
        delta!.delta.any((op) => op['op'] == 'remove' && op['path'] == '/b'),
        isTrue,
      );
    });

    test('generated delta round-trips through applyStateDelta', () {
      final oldState = <String, dynamic>{'x': 10, 'y': 20};
      final newState = <String, dynamic>{'x': 99, 'z': 30};
      final delta = stateChangedToDelta(oldState, newState)!;
      final result = applyStateDelta(oldState, delta) as Map;
      expect(result['x'], equals(99));
      expect(result['z'], equals(30));
      expect(result.containsKey('y'), isFalse);
    });
  });
}
