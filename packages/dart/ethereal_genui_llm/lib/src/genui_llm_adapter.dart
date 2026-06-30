/// Abstract LLM adapter interface and sealed event hierarchy for Ethereal GenUI.
///
/// All LLM adapters implement [GenUiLlmAdapter] and emit [GenUiStreamEvent]
/// subclasses. The [GenUiDirectConnection] consumes these and handles the
/// tool-use loop transparently.
library;

/// Abstract interface all LLM adapters implement.
abstract class GenUiLlmAdapter {
  /// Streams response events for one conversation turn.
  /// [history] includes the full message history including the new user turn.
  /// [tools] are the currently registered tool definitions.
  Stream<GenUiStreamEvent> stream(
    List<GenUiMessage> history,
    List<GenUiToolDef> tools,
  );
}

/// Sealed event hierarchy — the adapter emits these, the connection handles them.
sealed class GenUiStreamEvent {
  const GenUiStreamEvent();
}

class GenUiTextChunk extends GenUiStreamEvent {
  const GenUiTextChunk(this.delta);
  final String delta;
}

class GenUiToolCallEvent extends GenUiStreamEvent {
  const GenUiToolCallEvent({required this.name, required this.args});
  final String name;
  final Map<String, dynamic> args;
}

class GenUiStopEvent extends GenUiStreamEvent {
  const GenUiStopEvent({this.stopReason});
  final String? stopReason;
}

/// Message in the conversation history.
class GenUiMessage {
  const GenUiMessage({required this.role, this.content, this.toolResult});

  /// Role: 'user' | 'assistant' | 'tool' | 'system'
  final String role;
  final String? content;
  final GenUiToolResult? toolResult;
}

/// Result of a tool invocation to feed back to the LLM.
class GenUiToolResult {
  const GenUiToolResult({required this.toolName, required this.result});
  final String toolName;
  final dynamic result;
}

/// Tool definition exposed to the LLM.
class GenUiToolDef {
  const GenUiToolDef({
    required this.name,
    required this.description,
    required this.parameters,
  });
  final String name;
  final String description;

  /// JSON Schema describing the tool's parameters.
  final Map<String, dynamic> parameters;
}
