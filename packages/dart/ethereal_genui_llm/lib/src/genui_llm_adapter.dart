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
    required this.name,
    required this.args,
    this.id,
  });
  final String name;
  final Map<String, dynamic> args;

  /// Provider-assigned tool-call ID. Required by Anthropic and OpenAI when
  /// replaying the assistant turn that contained the tool call. Null for
  /// providers that do not assign IDs (e.g. Gemini).
  final String? id;
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
    this.toolCall,
  });

  /// Role: 'user' | 'assistant' | 'tool' | 'system'
  final String role;
  final String? content;

  /// Present on role='tool' messages — the result to feed back to the LLM.
  final GenUiToolResult? toolResult;

  /// Present on role='assistant' messages that triggered a tool call.
  /// Carried so adapters can reconstruct the provider-specific tool-call block
  /// (Anthropic tool_use block, OpenAI tool_calls array) on message replay,
  /// which is required for multi-turn tool use to succeed.
  final GenUiToolCall? toolCall;
}

/// Tool-call metadata stored on the assistant turn that triggered the call.
/// Enables correct replay of the assistant message with the provider's
/// required tool-call structure (tool_use id for Anthropic, tool_calls id
/// for OpenAI).
class GenUiToolCall {
  const GenUiToolCall({
    required this.name,
    required this.args,
    this.id,
  });
  final String name;
  final Map<String, dynamic> args;

  /// Provider-assigned call ID (null for providers that don't issue IDs).
  final String? id;
}

/// Result of a tool invocation to feed back to the LLM.
class GenUiToolResult {
  const GenUiToolResult({
    required this.toolName,
    required this.result,
    this.toolCallId,
  });
  final String toolName;
  final dynamic result;

  /// The provider-assigned ID of the tool call this result corresponds to.
  /// Must match [GenUiToolCall.id] on the preceding assistant message for
  /// Anthropic (tool_result.tool_use_id) and OpenAI (tool message.tool_call_id).
  final String? toolCallId;
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
