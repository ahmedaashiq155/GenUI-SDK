/// Ethereal GenUI LLM — zero-backend direct LLM connection.
///
/// Provides streaming adapters for Anthropic Claude, OpenAI GPT, and Google
/// Gemini, plus a [GenUiDirectConnection] orchestrator that handles message
/// history, system-prompt injection (including the GenUI block catalogue),
/// tool registration, and the full tool-use loop.
///
/// Typical use:
/// ```dart
/// final connection = GenUiDirectConnection(
///   adapter: AnthropicAdapter(apiKey: 'sk-ant-...'),
/// );
/// connection.registerTool(name: 'myTool', ...);
/// await for (final segments in connection.sendMessage('Hello')) {
///   // segments: List<MessageSegment> — render with GenUiBlock etc.
/// }
/// ```
library;

export 'src/genui_llm_adapter.dart';
export 'src/genui_direct_connection.dart';
export 'src/adapters/anthropic_adapter.dart';
export 'src/adapters/openai_adapter.dart';
export 'src/adapters/gemini_adapter.dart';
