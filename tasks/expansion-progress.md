# SDD Progress Ledger — Ethereal GenUI Expansion

## Plan: smooth-doodling-pnueli.md (8 phases)
## Branch: worktree-ethereal-expansion
## Start commit: 411ef35

## Tasks

- [x] Task 1: Phase 1 — Monorepo Foundation + Core Extraction
- [x] Task 2: Phase 1b — Direct LLM Connection (ethereal_genui_llm)
- [x] Task 3: Phase 2 — AG-UI Native Transport (Dart/Flutter)
- [x] Task 4: Phase 3 — TypeScript + React SDK
  - [x] Task 4a: @ethereal/genui-core (schema, options, json_patch, segments)
  - [x] Task 4b: @ethereal/genui-react foundation (store, provider, transport, ChoicesRenderer)
  - [x] Task 4c-1: 13 interactive renderers (actions, confirm, suggestions, input, multiselect, slider, form, rating, segmented, stepper, checklist, poll, quiz)
  - [x] Task 4c-2: 12 display + minitools renderers (card, callout, stat, table, timeline, progress, badges, gallery, divider, calculator, converter, timer)
  - [x] Task 4c-3: 6 container renderers (section, grid, columns, accordion, tabs, when)
  - [x] Task 4c-4: 12 primitives/chart/artifact/directive renderers (text, icon, spacer, button, box, row, column, stack, chart, artifact, theme, shortcuts) — completes all 44 block types
- [ ] Task 5: Phase 4 — Python SDK — **HELD** (deprioritized, see note below)
- [ ] Task 6: Phase 5 — Rust SDK — **HELD** (deprioritized, see note below)
- [ ] Task 7: Phase 6 — P1 Gap Closures (streaming parser + accessibility) — **IN PROGRESS**
  - [x] Task 6a: Dart streaming partial-JSON parser (ethereal_genui_core + genui_block/genui_chat wiring)
  - [x] Task 6b: Dart accessibility (Semantics) pass
  - [x] Task 6c: TS/JS streaming partial-JSON parser + useGenUiStream hook
  - [x] Task 6d: TS/JS shared Pressable primitive + Accordion/Checklist/Poll/Quiz native migration
  - [x] Task 6e: TS/JS remaining accessibility fixes (Slider, Rating, Tabs, Segmented, Progress, Chart, Form, Converter, Input)

## Phase 6 Design Decisions (feature-dev, resolved before implementation)

1. Closed-but-unparseable JSON gets a distinct "Couldn't render this block" placeholder (danger-tinted), separate from the "Preparing…" streaming placeholder. Both platforms.
2. React gets full streaming wiring (not just the utility): a new `useGenUiStream` hook giving React parity with Dart's `GenUiChat` — React cannot stream progressive UI blocks at all today.
3. React's AccordionRenderer/ChecklistRenderer migrate to native semantic elements (real `<button>`, `role="checkbox"`) rather than retrofitting ARIA onto `<div onClick>`. PollRenderer/QuizRenderer added to this scope too (found during a11y survey — same `<div onClick>` defect class).
4. A new shared `Pressable` React primitive is introduced now (not deferred) — reduces styling duplication and centralizes ARIA/keyboard passthrough.
5. **Cross-language repair-algorithm conflict resolved**: when a streaming JSON string value is cut off mid-word, the repaired output KEEPS the partial text (closes the string, e.g. `{"title":"Prep` → `{"title":"Prep"}`) rather than dropping the field. This is canonical for BOTH Dart and TS — the Dart architect's initial design (drop dangling string fields) is superseded; only a truly dangling key with no value token at all (nothing after `:`, or no `:` yet) gets truncated/dropped.
6. `GenUiBlock` in React changes its `default: return null` (unknown type) to render an "Unsupported block: {type}" placeholder — parity with Dart's `genUiPlaceholder`, intentional behavior change (breaks one existing test assertion, updated as part of the task).
7. Deferred (not this phase): Dart's Accordion/Tabs/ToolCall `expanded`/`selected` semantics refinements, GalleryRenderer alt-text (needs a schema change); React's full APG arrow-key roving-tabindex for Tabs/Segmented/Poll/Quiz/Rating, pure-display renderers (Card/Callout/Stat/Table/Timeline/Badges/Gallery/Divider — no interaction, already accessible), Calculator/Timer Pressable-routing (cosmetic only, no missing label/role).
- [ ] Task 8: Phase 7 — P2 Gap Closures (animation, multi-modal, devtools, voice)
- [ ] Task 9: Phase 8 — P3 Gap Closures (remote schema hot-reload)

## Priority Change (recorded during Phase 3 completion)

User decision: after TS/JS (Phase 3) wraps, skip Python SDK (Task 5) and Rust
SDK (Task 6) for now. Go directly to P1/P2 gap closures (Tasks 7-8) instead.
Rationale: TS/JS + Flutter/Dart cover the majority of real usage — focus
improvement effort there before investing in additional language SDKs.
Python/Rust SDKs remain in the plan, just held until gap closures land.

## Completed Tasks

Task 1: complete (commits 411ef35..a1b8056, review clean — 39/39 tests, flutter analyze clean)
Task 2: complete (commits a1b8056..2c8fcfc, review clean — 6/6 llm tests, 39/39 flutter tests, all 3 adapters verified against real API specs)
Task 3: complete (commits 2c8fcfc..9cf2493 — 3 commits, re-review approved — 24/24 core tests, 48/48 flutter tests, all findings resolved incl. json_patch RFC-6902 fix)

Task 4a: complete (commit 3157321, review clean — 20/20 tests, tsc clean, tsup build ESM+CJS+DTS)
Task 4b: complete (commit 7c84333, review clean — 23/23 tests, tsc clean, tsup build ESM+CJS+DTS)
Task 4c-1: complete (commits 41183b2+5882112, re-review approved — 95/95 tests, tsc clean)
  Minor items: ConfirmRenderer cancel uses color-mix (no border); PollRenderer bypasses genUiOptions; SegmentedRenderer thin test coverage
Task 4c-2: complete (commit 1cdba85, review approved — 156/156 tests, tsc clean)
  Minor items: CalculatorRenderer dead ternary in formatResult (no behavioral impact); TimerRenderer Resume state unreachable in JSDOM
Task 4c-3: complete (commit 11565d6, review approved — 188/188 tests, tsc clean)
  Minor items: Weak toBeDefined assertions in 3 empty-container tests (not .not.toBeNull()); WhenRenderer single-child path drops className/style (faithful to brief)
Task 6a: complete (commit 8123606, review approved — Dart core 38/38, Flutter 22/22 (genui_test.dart isolated run, includes 3 new streaming/malformed-placeholder tests), analyze clean)
  Minor items: repairPartialJson exposed publicly beyond brief's literal API (justified — future TS parity testing); inline step-comments could be denser for the repair scan. Note: full-suite `flutter test` is unreliable in this sandbox (same Windows resource-exhaustion pattern as vitest) — verify via `flutter test test/<file>.dart` run individually per file when the full suite reports spurious "loading" failures.

Task 6b: complete (commit ae62c82, review approved — 28/28 genui_test.dart, 7/7 chart_semantics_test.dart, analyze clean)
  Minor items: implementer correctly deviated from brief's literal _phaseAnnouncement sample for 'running' state (brief's sample would have re-interpolated the ticking $_formatted string into the live-region label every second, violating the brief's own no-spam constraint — dropped it, added a regression test proving no per-tick announcement); chartSemanticLabel exported from package barrel (needed for external test import, matches existing convention).

Task 6c: complete (commits 84fa784+0ed9824, review approved — core 37/37, react 51/51 batched, tsc clean both packages)
  Reviewer independently hand-traced the TS repair algorithm side-by-side with Dart's on 4 trickiest cases (dangling colon, dangling key, nested close, escaped-quote-in-unterminated-string) — confirmed line-for-line equivalent control flow, not just output parity. Minor: useGenUiStream.test.ts crashes Windows Tinypool on every retry (known sandbox issue, verified correct via static trace instead); repairPartialJson exported publicly (sanctioned by brief, mirrors Dart).

Task 4c-4: complete (commits 313097a+7d44d4a, feature-dev audit found + fixed 2 Important + 1 Minor — 267/267 tests, tsc clean, build clean)
  All 44 block types now implemented. Audit findings fixed: (1) ButtonRenderer leading icon used wrong size/color (22px accent instead of 18px text-color-matched) — fixed + regression test added. (2) ShortcutsDirectiveRenderer called setShortcuts([]) unconditionally on mount, wiping host-stored shortcuts when spec.items was empty — fixed with Dart-matching guard + regression test added. (3, Minor) BoxRenderer rendered both spec.child and spec.children simultaneously instead of child taking precedence (Dart's _resolveChildren) — fixed.
  Note: full-suite `npm test` crashes the Windows Tinypool thread pool (0xC0000005) — a local sandbox resource limit, not a code defect. Verified all 267 tests pass by running test files in batches with --pool=forks --poolOptions.forks.singleFork=true or individually.

Task 6d: complete — new shared `Pressable` primitive (src/components/Pressable.tsx: always a real
`<button type="button">`, browser chrome reset, ARIA/role passthrough, `:focus-visible` accent ring
via `.ethereal-pressable` class added to theme.css, exported from barrel). Migrated the four
`<div onClick>` renderers: Accordion (header button, aria-expanded/aria-controls + region panel,
useId), Checklist (rows role="checkbox" aria-checked, glyph aria-hidden), Poll (option buttons,
disabled after vote, aria-pressed on voted option, inner divs → spans for valid button content),
Quiz (option buttons, disabled after answer, outcome in aria-label, data-correct/data-wrong kept).
New test/Pressable.test.tsx (6 tests) + 4 a11y regression tests appended to the migrated renderers'
test files.

Task 6e: complete — Slider (label htmlFor + id, aria-label fallback), Rating (role=group,
per-star aria-label "Rate N out of M" + aria-pressed, glyph aria-hidden), Tabs (tablist/tab/
tabpanel, aria-selected, aria-controls on active tab only, aria-labelledby, useId), Segmented
(radiogroup + role=radio aria-checked), Progress (role=progressbar valuenow/min/max + label),
Chart (new exported `chartSemanticLabel()` — wording/format parity with Dart's, chart wrapped in
role="img" with the summary, SVG aria-hidden), Form (label htmlFor for text/number/toggle fields,
select-pill group role=group + aria-pressed), Converter (aria-labels on value input + both unit
selects, aria-live=polite result, swap glyph aria-hidden), Input (label htmlFor textarea,
placeholder as fallback accessible name). New test/a11y.test.tsx (12 tests).
Verification: tsc clean, full suite 306/306 pass (--pool=threads; forks pool crashes in this
sandbox, known issue), tsup build clean (CJS+ESM+DTS). Deferred items per design decision 7
unchanged (no roving tabindex, display-only renderers untouched).

## Final Whole-Branch Review (Phase 3 complete)

Dispatched 3 parallel opus-model reviewers scoped to genui-core, genui-react
foundation (store/provider/transport/dispatcher), and all 44 renderers —
covering the full branch diff (9cf2493..7d44d4a, 117 files, 14k lines).
Findings fixed in commit 4fbad7d:

- **Important**: `json_patch.ts` out-of-bounds/non-integer array `replace`
  wrote through unconditionally instead of being skipped (Dart parity —
  data corruption risk on malformed AI deltas). Fixed + 2 regression tests.
- **Important**: `GenUiBlock.tsx` dispatcher silently dropped 4
  schema-sanctioned alias types (`kpi`→stat, `steps`→timeline,
  `chips`→badges, `container`→box) that `validateGenUiSpec` accepts and
  Dart's registry renders — cross-client parity break. Fixed + new
  `test/GenUiBlock.test.tsx` (6 tests) covering all 4 aliases.
- **Important**: `ChartRenderer` pie/donut slice spanning exactly 360°
  produced a degenerate SVG arc (coincident endpoints) that silently
  fails to render — hits any pie with one dominant/sole category. Fixed
  (clamp sweep to 359.999°) + undefined `--ethereal-bg` CSS var also
  fixed (now `--ethereal-on-accent`).
- **Important**: `PollRenderer` persists `votedIndex` but not the vote
  tally itself, so a reloaded poll showed 0% for the user's own vote.
  Fixed by re-applying the increment on hydration (mirrors Dart).
- **Minor** (fixed): `WhenRenderer` no-op subscribe recreated every
  render; `transport.ts` `TEXT_MESSAGE_START` didn't reset
  `streamingText`/notify (Dart parity); `StepperRenderer` sent a leading
  `": "` with no label.
- **Minor** (left as-is, judged not worth fixing): ConfirmRenderer
  borderless cancel button (matches convention elsewhere); PollRenderer's
  own label-parsing bypass of `genUiOptions` (correct — poll options carry
  a `votes` field `genUiOptions` would strip); SegmentedRenderer thin test
  coverage; CalculatorRenderer dead ternary (verified zero impact);
  TimerRenderer Resume state (JSDOM test-env limitation, component logic
  verified correct); weak `toBeDefined` assertions in 3 container tests;
  WhenRenderer single-child path not forwarding className/style (mirrors
  Dart, pre-authorized exception).

Core-package json_patch fix + alias-type fix + pie-chart fix + poll fix
are the highest-value catches — each is a real silent-corruption or
silent-blank-render bug that unit tests didn't happen to exercise.

**Phase 3 (Task 4) is now fully complete**: all 44 block types + 4
aliases, TS/JS SDK ships with `@ethereal/genui-core` + `@ethereal/genui-react`,
~280 tests, tsc clean, builds clean on both packages.

## Follow-up Items (Minor, non-blocking for current tasks)

- json_patch.dart array-index `replace` op is RFC-6902 non-compliant (treats replace as insert on list). Will corrupt uiSpec if agent emits STATE_DELTA with array-index replace. Fix in a later task or dedicated patch.
- agui_transport.dart `runFinished` handler has redundant if/else branches both calling `_notifyListeners()`. Cleanup opportunity.
