/// Ethereal GenUI LLM — zero-backend direct LLM connection.
///
/// Provides streaming adapters for Anthropic Claude, OpenAI GPT, and Google
/// Gemini, plus a [GenUiDirectConnection] orchestrator that handles message
/// history, system-prompt injection (including the GenUI block catalogue),
/// tool registration, and the full tool-use loop.
///
/// ## ⚠️ Security: this pattern ships your API key inside the app
///
/// The "direct" connection calls the provider from the client with a key you
/// pass in. Anything you compile into a mobile/web build is extractable — via
/// APK/IPA decompilation or a network proxy — so a shipped key can be pulled
/// and billed against. **This mode is for local prototyping and internal
/// tools only.** For anything user-facing, put the key on a server you control
/// and route requests through it (or use the AG-UI transport in
/// `ethereal_genui_core` against your own backend).
///
/// Typical use (prototyping):
/// ```dart
/// final connection = GenUiDirectConnection(
///   adapter: AnthropicAdapter(apiKey: 'sk-ant-...'), // dev key, not shipped
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
