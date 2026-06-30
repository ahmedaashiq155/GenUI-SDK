/// AG-UI Flutter Adapter — Flutter orchestrator for AG-UI agent integration.
///
/// Wraps [AguiEventProcessor] as a [ChangeNotifier] so it can be consumed by
/// `Provider`, `ListenableBuilder`, `AnimatedBuilder`, or any other Flutter
/// widget that listens to `Listenable` objects.
///
/// Typical usage:
/// ```dart
/// final adapter = AguiFlutterAdapter(agent: MyHttpAgent());
///
/// // In your widget tree:
/// ListenableBuilder(
///   listenable: adapter,
///   builder: (context, _) {
///     if (adapter.isRunning) return const CircularProgressIndicator();
///     return buildGenUiSpec(context, adapter.uiSpec, GenUiActions(...));
///   },
/// );
///
/// // Send a message:
/// await adapter.sendMessage('Hello');
/// ```
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ag_ui/ag_ui.dart';
import 'package:ethereal_genui_core/ethereal_genui_core.dart';

/// Flutter ChangeNotifier wrapper around [AguiEventProcessor].
///
/// Bridges the AG-UI [EtherealAguiTransport] with Flutter's reactive rebuild
/// machinery. All state fields are exposed as read-only getters that delegate
/// to the underlying [AguiEventProcessor].
class AguiFlutterAdapter extends ChangeNotifier {
  /// Creates an adapter backed by [agent].
  ///
  /// [agent] is called when [sendMessage] is invoked. Supply a custom
  /// [threadId] to maintain conversation continuity across sessions; if
  /// omitted a random UUID-style identifier is generated on first call.
  AguiFlutterAdapter({
    required this._agent,
    String? threadId,
  })  : _threadId = threadId ?? _generateId(),
        _processor = AguiEventProcessor() {
    _processor.addListener(_onProcessorChanged);
  }

  final EtherealAguiTransport _agent;
  final AguiEventProcessor _processor;
  final String _threadId;

  StreamSubscription<BaseEvent>? _subscription;
  int _runCounter = 0;

  // ---------------------------------------------------------------------------
  // Read-only state accessors (delegates to processor)
  // ---------------------------------------------------------------------------

  /// The current GenUI spec map. Feed this into [buildGenUiSpec].
  Map<String, dynamic> get uiSpec => _processor.uiSpec;

  /// The current widget-instance state (extracted from STATE_SNAPSHOT).
  Map<String, dynamic> get widgetState => _processor.widgetState;

  /// Streaming text delta buffer — non-null while a text message is in flight.
  String? get streamingText => _processor.streamingText;

  /// True while a run is active (between RUN_STARTED and RUN_FINISHED / RUN_ERROR).
  bool get isRunning => _processor.isRunning;

  /// Non-null when the most recent run terminated with an error.
  String? get errorMessage => _processor.errorMessage;

  /// Full message history, accumulated from MESSAGES_SNAPSHOT and streaming events.
  List<Map<String, dynamic>> get messages => _processor.messages;

  // ---------------------------------------------------------------------------
  // Outbound actions
  // ---------------------------------------------------------------------------

  /// Send a user text [message] to the agent.
  ///
  /// Constructs a [RunAgentInput] with the message as a [UserMessage],
  /// subscribes to the returned event stream, and pipes each event through
  /// [AguiEventProcessor.processEvent]. [notifyListeners] is called automatically
  /// whenever the processor state changes.
  ///
  /// If a previous run is still active its subscription is cancelled before
  /// starting the new one.
  Future<void> sendMessage(String text) async {
    // Cancel any in-flight run.
    await _subscription?.cancel();
    _subscription = null;

    _runCounter++;
    final runId = 'run-$_runCounter-${DateTime.now().millisecondsSinceEpoch}';

    final input = RunAgentInput(
      threadId: _threadId,
      runId: runId,
      messages: [
        UserMessage(id: 'msg-$_runCounter', content: text),
      ],
      tools: const [],
      context: const [],
    );

    final stream = _agent.run(input);
    _subscription = stream.listen(
      _processor.processEvent,
      onError: (Object err, StackTrace st) {
        _processor.processEvent(RunErrorEvent(
          message: err.toString(),
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      },
      onDone: () {
        // If the stream closes without a RUN_FINISHED the processor may still
        // be in isRunning == true; emit a synthetic RUN_FINISHED.
        if (_processor.isRunning) {
          _processor.processEvent(RunFinishedEvent(
            threadId: _threadId,
            runId: runId,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ));
        }
      },
      cancelOnError: false,
    );
  }

  /// Notify the agent that widget state has changed.
  ///
  /// Computes an RFC-6902 diff between [_processor.widgetState] and
  /// [newWidgetState] via [stateChangedToDelta], emits the resulting
  /// [StateDeltaEvent] upstream via [EtherealAguiTransport.sendEvent]
  /// (fire-and-forget), then applies the patch locally so the processor
  /// stays consistent.
  void onWidgetStateChanged(Map<String, dynamic> newWidgetState) {
    final delta = stateChangedToDelta(_processor.widgetState, newWidgetState);
    if (delta == null) return;
    // Forward delta upstream — fire-and-forget.
    _agent.sendEvent(delta);
    // Apply locally so the processor stays consistent.
    final patched = applyStateDelta(_processor.widgetState, delta);
    if (patched is Map<String, dynamic>) {
      _processor.widgetState = patched;
    } else if (patched is Map) {
      _processor.widgetState = Map<String, dynamic>.from(patched);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Custom event handler forwarding
  // ---------------------------------------------------------------------------

  /// Register a [handler] for a specific AG-UI `CUSTOM` event [name].
  void registerCustomHandler(
    String name,
    void Function(CustomEvent event) handler,
  ) {
    _processor.registerCustomHandler(name, handler);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _subscription?.cancel();
    _processor.removeListener(_onProcessorChanged);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _onProcessorChanged() {
    notifyListeners();
  }

  static String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'thread-$ts';
  }
}
