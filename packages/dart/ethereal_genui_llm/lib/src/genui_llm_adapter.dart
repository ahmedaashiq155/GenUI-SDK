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
  const GenUiToolCallEvent({
    required this.id,
    required this.name,
    required this.args,
  });

  /// Provider-assigned tool-call ID. For providers without native IDs (Gemini),
  /// use the tool name as a stable stand-in.
  final String id;
  final String name;
  final Map<String, dynamic> args;
}

class GenUiStopEvent extends GenUiStreamEvent {
  const GenUiStopEvent({this.stopReason});
  final String? stopReason;
}

/// Message in the conversation history.
class GenUiMessage {
  const GenUiMessage({
    required this.role,
    this.content,
    this.toolResult,
    this.toolCalls,
  });

  /// Role: 'user' | 'assistant' | 'tool' | 'system'
  final String role;
  final String? content;

  /// Present on role='tool' messages — the result to feed back to the LLM.
  final GenUiToolResult? toolResult;

  /// Present on role='assistant' messages that triggered tool calls.
  /// A single turn may invoke multiple tools in parallel (non-null, non-empty
  /// list). Adapters use this to reconstruct the provider-specific tool-call
  /// block (Anthropic tool_use block, OpenAI tool_calls array) on replay.
  final List<GenUiToolCall>? toolCalls;
}

/// Tool-call metadata stored on the assistant turn that triggered the call.
/// Enables correct replay of the assistant message with the provider's
/// required tool-call structure (tool_use id for Anthropic, tool_calls id
/// for OpenAI).
class GenUiToolCall {
  const GenUiToolCall({
    required this.id,
    required this.name,
    required this.args,
  });

  /// Provider-assigned call ID. For Gemini (no native ID), the tool name is
  /// used as a stable stand-in.
  final String id;
  final String name;
  final Map<String, dynamic> args;
}

/// Result of a tool invocation to feed back to the LLM.
class GenUiToolResult {
  const GenUiToolResult({
    required this.toolName,
    required this.result,
    required this.toolCallId,
  });
  final String toolName;
  final dynamic result;

  /// The provider-assigned ID of the tool call this result corresponds to.
  /// Must match [GenUiToolCall.id] on the preceding assistant message for
  /// Anthropic (tool_result.tool_use_id) and OpenAI (tool message.tool_call_id).
  final String toolCallId;
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
