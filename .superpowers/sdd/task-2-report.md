# Task 2 Report: Phase 1b — Direct LLM Connection (`ethereal_genui_llm`)

## Status: DONE

## Commits

`39ed351` — feat(llm): add ethereal_genui_llm package with streaming LLM adapters and GenUiChat widget
`dcd7829` — fix(llm): thread tool-call IDs through history for correct Anthropic/OpenAI replay

## What Was Built

### New Package: `packages/dart/ethereal_genui_llm/`

**Files created:**
- `pubspec.yaml` — depends on `ethereal_genui_core` + `http: ^1.2.0`; dev dep `test: ^1.24.0`
- `lib/ethereal_genui_llm.dart` — barrel export
- `lib/src/genui_llm_adapter.dart` — `GenUiLlmAdapter` interface, sealed `GenUiStreamEvent` hierarchy (`GenUiTextChunk`, `GenUiToolCallEvent`, `GenUiStopEvent`), `GenUiMessage`, `GenUiToolResult`, `GenUiToolDef`
- `lib/src/genui_direct_connection.dart` — `GenUiDirectConnection` orchestrator: streaming tool-use loop, per-call system prompt (injecting `buildGenUiPromptCatalogue()` from core), history management
- `lib/src/adapters/anthropic_adapter.dart` — Anthropic Claude via SSE; handles `content_block_start/delta/stop` for tool-use
- `lib/src/adapters/openai_adapter.dart` — OpenAI GPT via SSE; accumulates `delta.tool_calls` args
- `lib/src/adapters/gemini_adapter.dart` — Google Gemini via SSE; text-only (tool-calling not wired, noted)
- `test/genui_direct_connection_test.dart` — 4 unit tests using a `MockAdapter`

### Modified: `packages/dart/ethereal_genui/`

- `pubspec.yaml` — added `ethereal_genui_llm: path: ../ethereal_genui_llm`
- `lib/ethereal_genui.dart` — exports new `src/widgets/genui_chat.dart`
- `lib/src/widgets/genui_chat.dart` — `GenUiChat` stateful widget: wires `GenUiDirectConnection` → streaming `MessageSegment` lists → `Text` (for `TextSegment.markdown`) + `GenUiBlock` (for `UiSegment.json`); constructs `GenUiActions(sendMessage: _send)` to wire interactive UI controls back into the conversation

## Brief vs. Reality Adaptations

1. `buildGenUiSpec` is positional (`BuildContext, Map, GenUiActions`), not named. `GenUiChat` uses `GenUiBlock(raw: seg.json, actions: actions)` instead — the streaming-tolerant wrapper that decodes JSON and shows a placeholder on partial JSON during streaming.
2. `TextSegment.markdown` (not `.text`) and `UiSegment.json` (not `.rawJson`) used.
3. `sealed class GenUiStreamEvent { const GenUiStreamEvent(); }` — const base constructor added so `yield const GenUiStopEvent(...)` compiles.
4. Three unnecessary `!` null-assertions removed after `dart analyze` caught them.

## Test Results

- `dart test packages/dart/ethereal_genui_llm` — **5/5 passing**
  - text-only response yields TextSegment list
  - tool-use loop calls handler once and produces correct history
  - system prompt injection includes buildGenUiPromptCatalogue()
  - tool-call id is stored on assistant turn and tool result (new)
  - reset() clears conversation history
- `flutter test packages/dart/ethereal_genui` — **39/39 passing** (no regressions)
- `dart analyze packages/dart/ethereal_genui_llm` — **0 issues**
- `flutter analyze packages/dart/ethereal_genui` — **0 issues**

## Known Limitations

**By design:** In the tool-use loop, `assistantBuffer` resets to `''` at the top of each iteration, so text emitted before a tool call is not included in the segments yielded after the tool returns. This matches the brief's design — the host receives the post-tool-result text as a fresh yield, which replaces the turn's segment list.

**Gemini tool-calling:** `GeminiAdapter` implements text-only streaming. Gemini function calling uses a different protocol (structured `functionCall` parts, not SSE text deltas) that was not specified in the brief. Full Gemini tool-use support is a follow-on task. Gemini also does not issue tool-call IDs, so `GenUiToolCall.id` will be null for Gemini-originated calls.

**Host import ergonomics:** `ethereal_genui` exports `GenUiChat` but does not re-export `ethereal_genui_llm`. A host importing only `ethereal_genui` cannot construct `GenUiDirectConnection` without a second import of `ethereal_genui_llm`. This is consistent with the brief's design (separate packages) but worth noting for downstream host documentation.

---

## Code-Review Fixes (commit `e9b0509`)

### Fix 1 — Anthropic adapter: empty tool input crash
**File:** `lib/src/adapters/anthropic_adapter.dart`

In the `content_block_stop` handler, `jsonDecode(toolInputBuffer.toString())` would throw `FormatException` when the LLM calls a tool with zero parameters (empty buffer). Fixed by guarding the decode:

```dart
final rawInput = toolInputBuffer.toString();
final args = rawInput.isEmpty
    ? <String, dynamic>{}
    : jsonDecode(rawInput) as Map<String, dynamic>;
```

### Fix 2 — OpenAI adapter: parallel tool calls silently overwriting each other
**File:** `lib/src/adapters/openai_adapter.dart`

Single `pendingToolName`/`toolArgBuffer` variables meant that when OpenAI streams parallel tool calls (distinct `index` values), only the last one was emitted. Replaced with a `Map<int, ({String name, String? id, StringBuffer args})>` keyed by `tool_calls[].index`. On `[DONE]`, all accumulated entries are emitted. The same empty-buffer guard from Fix 1 is applied here as well.

### Test Results
- `dart analyze packages/dart/ethereal_genui_llm` — **0 issues**
- `dart test packages/dart/ethereal_genui_llm` — **5/5 passing**
- `flutter test packages/dart/ethereal_genui` — **39/39 passing**
