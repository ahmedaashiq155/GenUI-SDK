import 'package:ag_ui/ag_ui.dart';
import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter_test/flutter_test.dart';

/// A mock transport that replays a fixed list of events as a stream.
class MockAguiTransport extends EtherealAguiTransport {
  MockAguiTransport(this._events);

  final List<BaseEvent> _events;

  @override
  Stream<BaseEvent> run(RunAgentInput input) => Stream.fromIterable(_events);
}

void main() {
  group('AguiFlutterAdapter', () {
    test('isRunning is false before first sendMessage', () {
      final adapter = AguiFlutterAdapter(
        agent: MockAguiTransport(const []),
      );
      expect(adapter.isRunning, isFalse);
      adapter.dispose();
    });

    test('basic integration: isRunning transitions, uiSpec populated', () async {
      final events = [
        RunStartedEvent(threadId: 't1', runId: 'r1'),
        StateSnapshotEvent(
          snapshot: {
            'ui': {'type': 'text', 'content': 'Hello from agent'},
          },
        ),
        RunFinishedEvent(threadId: 't1', runId: 'r1'),
      ];

      final adapter = AguiFlutterAdapter(
        agent: MockAguiTransport(events),
        threadId: 't1',
      );

      final notifyCount = <int>[0];
      adapter.addListener(() => notifyCount[0]++);

      await adapter.sendMessage('hello');
      // Stream.fromIterable is sync; a microtask flush is enough.
      await Future<void>.delayed(Duration.zero);

      expect(adapter.isRunning, isFalse);
      expect(adapter.uiSpec['type'], equals('text'));
      expect(adapter.uiSpec['content'], equals('Hello from agent'));
      expect(notifyCount[0], greaterThan(0));

      adapter.dispose();
    });

    test('errorMessage is set on RUN_ERROR', () async {
      final events = [
        RunStartedEvent(threadId: 't1', runId: 'r1'),
        RunErrorEvent(message: 'Agent failed'),
      ];

      final adapter = AguiFlutterAdapter(
        agent: MockAguiTransport(events),
      );
      await adapter.sendMessage('trigger error');
      await Future<void>.delayed(Duration.zero);

      expect(adapter.isRunning, isFalse);
      expect(adapter.errorMessage, equals('Agent failed'));

      adapter.dispose();
    });

    test('streamingText accumulates and clears after message end', () async {
      final seenStreamingTexts = <String?>[];

      final events = [
        RunStartedEvent(threadId: 't1', runId: 'r1'),
        TextMessageStartEvent(messageId: 'm1'),
        TextMessageContentEvent(messageId: 'm1', delta: 'Hello'),
        TextMessageContentEvent(messageId: 'm1', delta: ', World'),
        TextMessageEndEvent(messageId: 'm1'),
        RunFinishedEvent(threadId: 't1', runId: 'r1'),
      ];

      final adapter = AguiFlutterAdapter(
        agent: MockAguiTransport(events),
      );
      adapter.addListener(() {
        seenStreamingTexts.add(adapter.streamingText);
      });

      await adapter.sendMessage('tell me something');
      await Future<void>.delayed(Duration.zero);

      // After RUN_FINISHED the streaming text should be null.
      expect(adapter.streamingText, isNull);
      // Some intermediate snapshot should have held partial text.
      expect(
        seenStreamingTexts.any((t) => t != null && t.contains('Hello')),
        isTrue,
      );

      adapter.dispose();
    });

    test('onWidgetStateChanged applies local RFC-6902 diff', () async {
      // Prime the adapter with a STATE_SNAPSHOT that sets widget state.
      final setupEvents = [
        StateSnapshotEvent(
          snapshot: {
            'ui': {'type': 'form'},
            'widgets': {'toggle1': false},
          },
        ),
        RunFinishedEvent(threadId: 't1', runId: 'r1'),
      ];

      final adapter = AguiFlutterAdapter(
        agent: MockAguiTransport(setupEvents),
      );
      await adapter.sendMessage('init');
      await Future<void>.delayed(Duration.zero);

      expect(adapter.widgetState['toggle1'], equals(false));

      adapter.onWidgetStateChanged({'toggle1': true});
      expect(adapter.widgetState['toggle1'], isTrue);

      adapter.dispose();
    });

    test('custom handler is invoked for matching CUSTOM events', () async {
      String? receivedValue;
      final events = [
        RunStartedEvent(threadId: 't1', runId: 'r1'),
        CustomEvent(name: 'my_action', value: 'ping'),
        RunFinishedEvent(threadId: 't1', runId: 'r1'),
      ];

      final adapter = AguiFlutterAdapter(
        agent: MockAguiTransport(events),
      );
      adapter.registerCustomHandler('my_action', (e) {
        receivedValue = e.value?.toString();
      });

      await adapter.sendMessage('go');
      await Future<void>.delayed(Duration.zero);

      expect(receivedValue, equals('ping'));

      adapter.dispose();
    });

    test('notifyListeners is called for each state-changing event', () async {
      final events = [
        RunStartedEvent(threadId: 't1', runId: 'r1'),
        StateSnapshotEvent(
          snapshot: {'ui': <String, dynamic>{}},
        ),
        RunFinishedEvent(threadId: 't1', runId: 'r1'),
      ];

      final adapter = AguiFlutterAdapter(
        agent: MockAguiTransport(events),
      );

      var count = 0;
      adapter.addListener(() => count++);

      await adapter.sendMessage('go');
      await Future<void>.delayed(Duration.zero);

      // At minimum: RUN_STARTED, STATE_SNAPSHOT, RUN_FINISHED = 3 notifications.
      expect(count, greaterThanOrEqualTo(3));

      adapter.dispose();
    });

    test('second sendMessage cancels previous subscription', () async {
      final eventCounts = [0, 0]; // index 0 = first run, 1 = second run

      final firstEvents = [
        RunStartedEvent(threadId: 't1', runId: 'r1'),
      ];

      final secondEvents = [
        RunStartedEvent(threadId: 't2', runId: 'r2'),
        RunFinishedEvent(threadId: 't2', runId: 'r2'),
      ];

      final adapter = AguiFlutterAdapter(
        agent: _CountingTransport([firstEvents, secondEvents],
            onCount: (run, _) {
          if (run < eventCounts.length) eventCounts[run]++;
        }),
      );

      await adapter.sendMessage('first');
      // Don't drain — immediately send second to cancel the first.
      await adapter.sendMessage('second');
      await Future<void>.delayed(Duration.zero);

      // After the second run finishes, the adapter should be idle.
      expect(adapter.isRunning, isFalse);
      // The second run must have processed its RUN_FINISHED.
      expect(eventCounts[1], greaterThan(0));

      adapter.dispose();
    });
  });
}

/// Helper transport that returns successive event lists for successive runs,
/// with an optional per-event callback.
class _CountingTransport extends EtherealAguiTransport {
  _CountingTransport(this._runs, {required this.onCount});

  final List<List<BaseEvent>> _runs;
  final void Function(int run, BaseEvent event) onCount;
  int _call = 0;

  @override
  Stream<BaseEvent> run(RunAgentInput input) {
    final idx = _call < _runs.length ? _call : _runs.length - 1;
    final currentCall = _call;
    _call++;
    return Stream.fromIterable(_runs[idx])
        .map((e) => e..asCountedBy(currentCall, onCount));
  }
}

extension _EventCountExt on BaseEvent {
  // ignore: avoid_returning_this
  BaseEvent asCountedBy(
      int run, void Function(int run, BaseEvent event) cb) {
    cb(run, this);
    return this;
  }
}
