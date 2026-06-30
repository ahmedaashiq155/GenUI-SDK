/// AG-UI Native Transport — pure Dart, no Flutter dependency.
///
/// Maps AG-UI protocol events (`BaseEvent` subclasses from the `ag_ui` package)
/// onto Ethereal GenUI's data model:
///
///  - `STATE_SNAPSHOT` → extract `ui` key from snapshot into [AguiEventProcessor.uiSpec]
///  - `STATE_DELTA`    → apply RFC-6902 ops via [applyJsonPatch]
///  - `TEXT_MESSAGE_*` → streaming text accumulation, finalised via [parseSegments]
///  - `TOOL_CALL_*`    → tool-call state tracking
///  - `RUN_*`          → loading / error state
///  - `MESSAGES_SNAPSHOT` → full message history restore
///  - `CUSTOM`         → routed to registered handlers
///  - All other types  → accepted and ignored gracefully
library;

import 'package:ag_ui/ag_ui.dart';

import 'json_patch.dart';
import 'message_segments.dart';

// ---------------------------------------------------------------------------
// Public helpers
// ---------------------------------------------------------------------------

/// Extracts the GenUI spec map from a [StateSnapshotEvent].
///
/// Returns null if [event] is not a [StateSnapshotEvent] or if its snapshot
/// does not contain a top-level `'ui'` key mapping to a `Map`.
Map<String, dynamic>? stateSnapshotToSpec(BaseEvent event) {
  if (event is! StateSnapshotEvent) return null;
  final snapshot = event.snapshot;
  if (snapshot is Map) {
    final ui = snapshot['ui'];
    if (ui is Map<String, dynamic>) return ui;
    if (ui is Map) return Map<String, dynamic>.from(ui);
  }
  return null;
}

/// Extracts the widget state map from a [StateSnapshotEvent].
///
/// Returns an empty map if [event] is not a [StateSnapshotEvent] or if its
/// snapshot does not contain a top-level `'widgets'` key mapping to a `Map`.
Map<String, dynamic> stateSnapshotToWidgetState(BaseEvent event) {
  if (event is! StateSnapshotEvent) return {};
  final snapshot = event.snapshot;
  if (snapshot is Map) {
    final widgets = snapshot['widgets'];
    if (widgets is Map<String, dynamic>) return widgets;
    if (widgets is Map) return Map<String, dynamic>.from(widgets);
  }
  return {};
}

/// Applies a [StateDeltaEvent]'s RFC-6902 ops to [currentSpec].
///
/// Returns the patched document (a new map), or [currentSpec] unchanged if
/// [event] is not a [StateDeltaEvent].
Object? applyStateDelta(Object? currentSpec, BaseEvent event) {
  if (event is! StateDeltaEvent) return currentSpec;
  return applyJsonPatch(currentSpec, event.delta);
}

// ---------------------------------------------------------------------------
// Transport interface
// ---------------------------------------------------------------------------

/// Abstract transport interface for backend AG-UI agents.
///
/// Implementations connect to an actual agent endpoint (HTTP SSE, WebSocket,
/// in-process, etc.) and return a `Stream<BaseEvent>` of AG-UI protocol events.
///
/// Example usage:
/// ```dart
/// class MyHttpAgent extends EtherealAguiTransport {
///   @override
///   Stream<BaseEvent> run(RunAgentInput input) => _client.runAgent(input);
/// }
/// ```
abstract class EtherealAguiTransport {
  /// Start a new agent run for [input] and return the resulting event stream.
  ///
  /// The stream should emit AG-UI [BaseEvent] instances. The stream must
  /// complete (close) when the run finishes or errors. The caller is
  /// responsible for cancelling the subscription if an early abort is needed.
  Stream<BaseEvent> run(RunAgentInput input);
}

// ---------------------------------------------------------------------------
// Event processor
// ---------------------------------------------------------------------------

/// Processes a stream of AG-UI [BaseEvent]s into Ethereal GenUI state.
///
/// This class is the core state machine. Feed events in via [processEvent];
/// each call mutates the appropriate field(s) and notifies listeners when
/// state changes. All fields are readable at any time (safe for polling or
/// binding in a ChangeNotifier wrapper).
class AguiEventProcessor {
  /// The current GenUI spec map (extracted from STATE_SNAPSHOT / STATE_DELTA).
  Map<String, dynamic> uiSpec = {};

  /// The current widget-instance state (extracted from STATE_SNAPSHOT).
  Map<String, dynamic> widgetState = {};

  /// Streaming text buffer — non-null while a text message is in flight.
  String? streamingText;

  /// True while a `RUN_STARTED` has been received but `RUN_FINISHED` /
  /// `RUN_ERROR` has not yet arrived.
  bool isRunning = false;

  /// Non-null when the most recent run terminated with a `RUN_ERROR`.
  String? errorMessage;

  /// Full message history, restored from `MESSAGES_SNAPSHOT` events.
  List<Map<String, dynamic>> messages = [];

  // Tool-call accumulation (keyed by toolCallId).
  final Map<String, _ToolCallBuffer> _toolCalls = {};

  // Custom event handlers registered by the host.
  final Map<String, void Function(CustomEvent)> _customHandlers = {};

  final List<void Function()> _listeners = [];

  // ---------------------------------------------------------------------------
  // Listener management
  // ---------------------------------------------------------------------------

  /// Register a [listener] that is called whenever state changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Unregister a previously added [listener].
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  // ---------------------------------------------------------------------------
  // Custom handler registration
  // ---------------------------------------------------------------------------

  /// Register a handler for a specific [CustomEvent.name].
  ///
  /// When a `CUSTOM` event arrives with a matching [name], [handler] is called
  /// with the full event. Multiple registrations for the same [name] overwrite
  /// the previous handler.
  void registerCustomHandler(
    String name,
    void Function(CustomEvent event) handler,
  ) {
    _customHandlers[name] = handler;
  }

  // ---------------------------------------------------------------------------
  // Core processing
  // ---------------------------------------------------------------------------

  /// Process one AG-UI [event]. Returns `true` if any state field changed.
  ///
  /// This method is deliberately tolerant: an unrecognised event type is
  /// accepted and ignored without throwing. Internal exceptions are swallowed
  /// so a single malformed event does not crash the stream.
  bool processEvent(BaseEvent event) {
    try {
      return _dispatch(event);
    } catch (_) {
      // Tolerant: keep processing subsequent events.
      return false;
    }
  }

  bool _dispatch(BaseEvent event) {
    switch (event.eventType) {
      // -----------------------------------------------------------------------
      // Lifecycle
      // -----------------------------------------------------------------------
      case EventType.runStarted:
        isRunning = true;
        errorMessage = null;
        _notifyListeners();
        return true;

      case EventType.runFinished:
        isRunning = false;
        // Finalise any dangling streaming text.
        if (streamingText != null) {
          streamingText = null;
          _notifyListeners();
        } else {
          _notifyListeners();
        }
        return true;

      case EventType.runError:
        isRunning = false;
        errorMessage = (event as RunErrorEvent).message;
        _notifyListeners();
        return true;

      // -----------------------------------------------------------------------
      // State
      // -----------------------------------------------------------------------
      case EventType.stateSnapshot:
        final specFromSnapshot = stateSnapshotToSpec(event);
        final widgetsFromSnapshot = stateSnapshotToWidgetState(event);
        if (specFromSnapshot != null) uiSpec = specFromSnapshot;
        widgetState = widgetsFromSnapshot;
        _notifyListeners();
        return true;

      case EventType.stateDelta:
        final patched = applyStateDelta(uiSpec, event);
        if (patched is Map<String, dynamic>) {
          uiSpec = patched;
        } else if (patched is Map) {
          uiSpec = Map<String, dynamic>.from(patched);
        }
        _notifyListeners();
        return true;

      // -----------------------------------------------------------------------
      // Text message streaming
      // -----------------------------------------------------------------------
      case EventType.textMessageStart:
        streamingText = '';
        _notifyListeners();
        return true;

      case EventType.textMessageContent:
        final delta = (event as TextMessageContentEvent).delta;
        streamingText = (streamingText ?? '') + delta;
        _notifyListeners();
        return true;

      case EventType.textMessageEnd:
        // parseSegments finalises the accumulated buffer.
        final text = streamingText ?? '';
        // We keep streamingText non-null so callers can access the final value;
        // the host (AguiFlutterAdapter) clears it after consuming.
        if (text.isNotEmpty) {
          // Store the segments-parsed result in messages for history.
          final segs = parseSegments(text);
          messages.add({
            'role': 'assistant',
            'segments': segs.map(_segmentToMap).toList(),
            'raw': text,
          });
        }
        streamingText = null;
        _notifyListeners();
        return true;

      // TEXT_MESSAGE_CHUNK is the unified streaming type — treat like content.
      case EventType.textMessageChunk:
        final chunk = event as TextMessageChunkEvent;
        if (chunk.delta != null && chunk.delta!.isNotEmpty) {
          streamingText = (streamingText ?? '') + chunk.delta!;
          _notifyListeners();
          return true;
        }
        return false;

      // -----------------------------------------------------------------------
      // Tool calls
      // -----------------------------------------------------------------------
      case EventType.toolCallStart:
        final e = event as ToolCallStartEvent;
        _toolCalls[e.toolCallId] = _ToolCallBuffer(name: e.toolCallName);
        _notifyListeners();
        return true;

      case EventType.toolCallArgs:
        final e = event as ToolCallArgsEvent;
        _toolCalls[e.toolCallId]?.appendArgs(e.delta);
        _notifyListeners();
        return true;

      case EventType.toolCallEnd:
        final e = event as ToolCallEndEvent;
        final buf = _toolCalls.remove(e.toolCallId);
        if (buf != null) {
          messages.add({
            'role': 'tool_call',
            'toolCallId': e.toolCallId,
            'toolName': buf.name,
            'args': buf.argsBuffer,
          });
          _notifyListeners();
          return true;
        }
        return false;

      // TOOL_CALL_CHUNK — treat like args delta.
      case EventType.toolCallChunk:
        final e = event as ToolCallChunkEvent;
        if (e.toolCallId != null && e.delta != null) {
          _toolCalls[e.toolCallId!]?.appendArgs(e.delta!);
          _notifyListeners();
          return true;
        }
        return false;

      case EventType.toolCallResult:
        // Tool result is informational; add to message history.
        final e = event as ToolCallResultEvent;
        messages.add({
          'role': 'tool_result',
          'toolCallId': e.toolCallId,
          'content': e.content,
        });
        _notifyListeners();
        return true;

      // -----------------------------------------------------------------------
      // Messages snapshot
      // -----------------------------------------------------------------------
      case EventType.messagesSnapshot:
        final e = event as MessagesSnapshotEvent;
        messages = e.messages
            .map((m) => {'role': m.role.value, 'content': m.content})
            .toList();
        _notifyListeners();
        return true;

      // -----------------------------------------------------------------------
      // Step tracking (informational)
      // -----------------------------------------------------------------------
      case EventType.stepStarted:
      case EventType.stepFinished:
        // No state mutation; inform listeners for progress UI.
        _notifyListeners();
        return true;

      // -----------------------------------------------------------------------
      // Activity events
      // -----------------------------------------------------------------------
      case EventType.activitySnapshot:
      case EventType.activityDelta:
        // Pass through — no Ethereal state mapping defined.
        return false;

      // -----------------------------------------------------------------------
      // Raw / custom
      // -----------------------------------------------------------------------
      case EventType.raw:
        // No Ethereal state mapping; accepted and ignored.
        return false;

      case EventType.custom:
        final e = event as CustomEvent;
        final handler = _customHandlers[e.name];
        if (handler != null) {
          handler(e);
          return true;
        }
        return false;

      // -----------------------------------------------------------------------
      // Reasoning / thinking events — accepted, ignored gracefully
      // -----------------------------------------------------------------------
      case EventType.thinkingStart:
      case EventType.thinkingEnd:
      case EventType.reasoningStart:
      case EventType.reasoningMessageStart:
      case EventType.reasoningMessageContent:
      case EventType.reasoningMessageEnd:
      case EventType.reasoningMessageChunk:
      case EventType.reasoningEnd:
      case EventType.reasoningEncryptedValue:
        return false;

      // ignore: deprecated_member_use
      case EventType.thinkingTextMessageStart:
      // ignore: deprecated_member_use
      case EventType.thinkingTextMessageContent:
      // ignore: deprecated_member_use
      case EventType.thinkingTextMessageEnd:
      // ignore: deprecated_member_use
      case EventType.thinkingContent:
        return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _ToolCallBuffer {
  _ToolCallBuffer({required this.name});
  final String name;
  final StringBuffer _args = StringBuffer();

  String get argsBuffer => _args.toString();

  void appendArgs(String delta) => _args.write(delta);
}

Map<String, dynamic> _segmentToMap(MessageSegment seg) {
  return switch (seg) {
    TextSegment() => {'type': 'text', 'markdown': seg.markdown},
    CodeSegment() => {
        'type': 'code',
        'language': seg.language,
        'code': seg.code,
        'closed': seg.closed,
      },
    UiSegment() => {'type': 'ui', 'json': seg.json, 'closed': seg.closed},
  };
}
