import 'package:ethereal_genui_core/ethereal_genui_core.dart';
import 'genui_llm_adapter.dart';

/// Internal tool registration entry.
class _GenUiTool {
  _GenUiTool({required this.def, required this.handler});
  final GenUiToolDef def;
  final Future<dynamic> Function(Map<String, dynamic> args) handler;
}

/// Orchestrates a zero-backend LLM conversation with streaming, message history,
/// system-prompt injection, tool registration, and the full tool-use loop.
///
/// Supports any LLM provider via the [GenUiLlmAdapter] interface. By default,
/// injects the Ethereal GenUI block catalogue into the system prompt so the
/// model knows how to emit structured UI blocks.
///
/// Known limitation: in the tool-use loop, text emitted before a tool call
/// is discarded from the next yield (assistantBuffer resets each loop
/// iteration). This is by design — the host receives segments per-iteration.
class GenUiDirectConnection {
  GenUiDirectConnection({
    required GenUiLlmAdapter adapter,
    String? systemPrompt,
    bool injectGenUiCatalogue = true,
  })  : _adapter = adapter,
        _userSystemPrompt = systemPrompt,
        _injectCatalogue = injectGenUiCatalogue;

  final GenUiLlmAdapter _adapter;
  final String? _userSystemPrompt;
  final bool _injectCatalogue;
  final List<_GenUiTool> _tools = [];
  final List<GenUiMessage> _history = [];

  /// Register a function the LLM can call as a tool.
  void registerTool({
    required String name,
    required String description,
    required Map<String, dynamic> parameters,
    required Future<dynamic> Function(Map<String, dynamic> args) handler,
  }) {
    _tools.add(_GenUiTool(
      def: GenUiToolDef(
          name: name, description: description, parameters: parameters),
      handler: handler,
    ));
  }

  /// Send a user message, returns a stream of parsed [MessageSegment] lists.
  /// Automatically handles the tool-use loop — tool calls are executed and
  /// results fed back to the LLM transparently.
  Stream<List<MessageSegment>> sendMessage(String text) async* {
    _history.add(GenUiMessage(role: 'user', content: text));

    // Build system prompt parts
    final systemParts = <String>[];
    if (_injectCatalogue) {
      systemParts.add(buildGenUiPromptCatalogue());
    }
    if (_userSystemPrompt != null) {
      systemParts.add(_userSystemPrompt);
    }

    // Build history with system message prepended (not stored in _history)
    final historyWithSystem = <GenUiMessage>[];
    if (systemParts.isNotEmpty) {
      historyWithSystem.add(GenUiMessage(
        role: 'system',
        content: systemParts.join('\n\n'),
      ));
    }
    historyWithSystem.addAll(_history);

    // Tool-use loop
    String assistantBuffer = '';
    bool looping = true;

    while (looping) {
      looping = false;
      assistantBuffer = '';

      // Collect ALL tool calls emitted during this turn before executing any,
      // since a single turn may contain multiple parallel tool calls.
      final pendingCalls = <GenUiToolCallEvent>[];

      await for (final event
          in _adapter.stream(historyWithSystem, _tools.map((t) => t.def).toList())) {
        if (event is GenUiTextChunk) {
          assistantBuffer += event.delta;
          yield parseSegments(assistantBuffer);
        } else if (event is GenUiToolCallEvent) {
          pendingCalls.add(event);
        }
        // GenUiStopEvent: nothing to do; we check pendingCalls after stream ends.
      }

      if (pendingCalls.isNotEmpty) {
        // Store assistant turn with all structured tool calls.
        final assistantMsg = GenUiMessage(
          role: 'assistant',
          content: assistantBuffer.isEmpty ? null : assistantBuffer,
          toolCalls: pendingCalls
              .map((e) => GenUiToolCall(id: e.id, name: e.name, args: e.args))
              .toList(),
        );
        _history.add(assistantMsg);
        historyWithSystem.add(assistantMsg);

        // Execute all tool handlers and store results.
        for (final call in pendingCalls) {
          final tool = _tools.firstWhere(
            (t) => t.def.name == call.name,
            orElse: () => throw StateError('Tool not found: ${call.name}'),
          );
          final result = await tool.handler(call.args);
          final toolMsg = GenUiMessage(
            role: 'tool',
            toolResult: GenUiToolResult(
              toolName: call.name,
              result: result,
              toolCallId: call.id,
            ),
          );
          _history.add(toolMsg);
          historyWithSystem.add(toolMsg);
        }

        looping = true; // re-prompt after tool results
      }
    }

    // Record final assistant turn (text-only response with no tool calls).
    if (assistantBuffer.isNotEmpty) {
      _history.add(GenUiMessage(role: 'assistant', content: assistantBuffer));
    }
  }

  /// Full conversation history (user/assistant/tool turns only, no system).
  List<GenUiMessage> get history => List.unmodifiable(_history);

  /// Clear history (start a new conversation).
  void reset() => _history.clear();
}
