# Ethereal GenUI — Audit Findings & Fix Plan (2026-07-04)

Source: 5 parallel review agents (core, schema/theme, interactive renderers, display renderers, security) + manual verification of all critical/high findings against source.

## Critical (verified in source)

> NOTE (2026-07-07): C1-C4 and all of Batch 1 below are FIXED and MERGED TO MAIN (commits cbad1d5 dart, c691e16 react, 1a11dd2 llm). Checkboxes below are historical (point at the old root `lib/` paths pre-monorepo-move) — see "Round 2" and "FIX SPEC" sections for what actually shipped, in `packages/dart/...` and `packages/js/...`.

- [x] **C1. `parseHexColor` mis-parses 8-digit hex** — `lib/src/renderers/directives.dart:7-14`. 8-digit input (`RRGGBBAA`, the convention the schema itself teaches at `genui_schema.dart:387` with `"border":"#ffffff22"`) is fed to `Color()` as-is, which reads `AARRGGBB` → `#ffffff22` renders opaque yellow instead of faint white. Fix: reorder `AA` prefix when length == 8.
- [x] **C2. JSON Patch op with missing `path` wipes the whole document** — `lib/src/json_patch.dart:28,78,97`. `(op['path'] ?? '')` makes a missing path identical to the RFC "whole document" pointer, so `{"op":"replace","value":X}` replaces the entire app spec and `{"op":"remove"}` nulls it — contradicting the module's own "tolerant, never wipes the app" guarantee. Fix: skip ops that lack a `path` key (and `from` for move/copy).
- [x] **C3. Unbounded recursion + fan-out in `buildGenUiSpec`** — `lib/src/genui_block.dart` + all container renderers. Deeply nested spec → StackOverflowError; wide fan-out → OOM. Fix: depth counter (cap ~24) + children-per-node cap, degrade to placeholder.
- [x] **C4. Directive blocks fire host actions with zero user consent** — `lib/src/renderers/directives.dart:28-36,78-93`. `theme`/`shortcuts` invoke `setAccent`/`setShortcuts` from `initState` on mere render; `shortcuts` persists attacker-authored strings that are later sent as user messages (durable prompt-injection). Fix: require a user gesture/confirmation before invoking host callbacks.

## High (verified)

- [x] **H1. Slider crashes on inverted min/max** — `inputs.dart:205` `_value.clamp(min, max)` throws `ArgumentError` when min > max (all build modes). Also `divisions` can round to 0 (`inputs.dart:180`) → assertion failure. Fix: normalize lo/hi, floor divisions to ≥1 or null.
- [x] **H2. 29 unchecked `as String?` / `as List<dynamic>?` casts across 9 renderer files** — crash on type-confused LLM output (e.g. numeric `title`, object instead of list). Fix: replace with `is` checks / `?.toString()` (`display.dart`, `primitives.dart`, `containers.dart`, `charts.dart`, `inputs.dart`, `interactive.dart`, `decisions.dart`, `minitools.dart`).
- [ ] **H3. Stale state on Live-App delta updates (no `didUpdateWidget`)** — `PollRenderer` (`interactive.dart:372`), `ConverterRenderer`/`TimerRenderer` (`minitools.dart`), `StepperRenderer`. JSON-Patch updates to the same widget position are silently ignored because derived fields are seeded once in `initState`. Fix: implement `didUpdateWidget` reconciliation.
- [x] **H4. Unbounded counts → UI-thread hang/OOM** (rating clamped ≤20; table/list caps still open — see M-items below, not fully done) — `rating.max` (`interactive.dart:47`), table rows/columns (not virtualized), option lists uncapped. Fix: clamp count fields (rating ≤ 20ish) and cap list-derived children (~200).
- [x] **H5. Gallery loads arbitrary `http(s)` images automatically** — https-only + cacheWidth now enforced BOTH platforms (2026-07-07: Dart's GalleryRenderer was actually still accepting plain `http://` until this date, contradicting an earlier incorrect note here — corrected). Alt-text still open, see A6. — `display.dart:354-390`. Tracking-pixel/IP-exfil vector; accepts plaintext `http`; no `cacheWidth` bound. Fix: require https, set cacheWidth/cacheHeight, consider opt-in.
- [x] **H6. Stepper +/- overshoots min/max when step > 1** — `interactive.dart:205-227`. Guard on post-step value and clamp.
- [x] **H7. Schema advertises `chart:"area"` but renderer falls back to bar** — `genui_schema.dart:268` vs `charts.dart:32-36`. Implement area variant or drop from enum.

## Medium

- [x] **M1. Grid `columns` unclamped** — `containers.dart:70-88`: negative/huge values → negative width → layout assertion. Clamp 1..12, width ≥ 0.
- [x] **M2. Negative `gap`/`width`/`height`/`size` unclamped** — `primitives.dart` (row/column gap, spacer, box dims). Clamp ≥ 0.
- [x] **M3. Table with rows but no columns violates `DataTable` invariant** — `display.dart:172-204`. Early-return when columns empty.
- [x] **M4. Validator never recurses into singular `child` field** — `genui_schema.dart:620-667` misses `when.child`. Add branch.
- [x] **M5. Form toggle unsafe cast on shared/persisted key** — `inputs.dart:312` `_values[key] as bool?`. Use `is bool` check.
- [ ] **M6. Checklist checked-state keyed by index, breaks on item reorder/insert** (STILL OPEN) — `interactive.dart:270-336`. Key by stable value.
- [x] **M7. `GenUiOption`/`genUiOptions` not exported** — CORRECTION: this was already fine before any fix work; the core barrel exports it unrestricted and `ethereal_genui.dart` re-exports the whole core package. Verified 2026-07-07 by `public_api_test.dart`. Original audit finding was a false positive.

## Security posture / design notes (for docs, not immediate code fixes)

> DONE 2026-07-07 — see `SECURITY.md` (repo root), which covers all three items below plus the direct-LLM-connection key-exposure warning.

- ~~Label/value decoupling on tappable options lets a spec show "Yes" but send arbitrary text as the user (`genui_common.dart:18-34`). Document; consider showing outgoing text for sensitive gates.~~
- ~~`set` on button/box can write any widget's state key (unscoped `GenUiStateScope.merge`). Document as trust consideration.~~
- ~~`artifact.kind:"html"` schema note promises a "sandboxed WebView" the package never implements — document mandatory host-side sandboxing requirements (no JS bridges, srcdoc/CSP, block file://).~~

---

# Round 2 — UX audits + TS/JS layer + LLM adapters (2026-07-04)

NOTE: the ACTIVE code lives in `.claude\worktrees\ethereal-expansion\packages\` — the root `lib/` is an older copy. All Round-1 critical bugs (C1 hex, C2 json_patch wipe, C4 auto-directives) exist in the worktree Dart copy too (C2 in `ethereal_genui_core/lib/src/json_patch.dart`). Apply fixes in the worktree.

## UX — Interaction (Flutter)

- [x] **U1. No double-submit guard anywhere** — FIXED 2026-07-07 via a centralized dispatch boundary (`_GenUiDispatchBoundary` in `genui_block.dart`, wraps the whole rendered spec tree once — better than the per-renderer plan here, one choke point instead of ~15 renderer edits) + `GenUiPressable` now dims (`AnimatedOpacity` to 0.55) when disabled.
- [ ] **U2. Form has zero validation** — can submit all-empty (`sendMessage('')`); no required-field support. Mirror InputRenderer's disable-until-content pattern; add `required` flag.
- [ ] **U3. Broken blocks stuck at "Preparing…" forever** — `GenUiBlock` can't distinguish streaming from terminally-unparseable. Add `isFinal` flag → error state. (React port already solved this via `ui-error` — port that design back.)
- [ ] **U4. Stepper send icon is a bare GestureDetector** (no GenUiPressable, ~22px hit target).
- [ ] **U5. Artifact card false affordance** when host hasn't wired `openArtifact` (both Flutter and React).
- [ ] **U6. No MouseRegion/hover cursor on GenUiPressable** — desktop/web feels dead.
- [ ] **U7. Missing animations at high-stakes moments** — poll bar fill, accordion expand, quiz reveal all snap instantly (use existing GenUiMotion.quick convention).
- [ ] **U8. Inconsistent empty states** — chart/gallery vanish silently, badges renders empty card.

## UX — Visual/theming (Flutter)

- [x] **V1. Dark-only default** — FIXED 2026-07-07: `GenUiColors.fromTheme(context)` derives all 13 roles from `Theme.of(context).colorScheme`, is now the default (`GenUiColors.of` = `resolver ?? fromTheme`), `fallback` renamed to `nocturne` (kept as `@Deprecated` alias) and is an explicit opt-in preset. Example app now uses `ThemeMode.system` to prove it.
- [ ] **V2. Replace global `genUiColorResolver` with `ThemeExtension<GenUiTheme>`** — NOT done (V1 landed via a simpler `fromTheme` factory instead; the ThemeExtension idea was optional/idiomatic-nice-to-have, not required for V1's actual goal of "light hosts get light cards"). Still open if wanted for subtree-scoped overrides.
- [ ] **V3. Inconsistent elevation language** — half the renderers bypass `GenUi.frame` with ad hoc translucent boxes (artifact, tool_call, accordion, callout, placeholder). Unify via frame variants.
- [ ] **V4. Buttons/pills/chart labels use raw TextStyle** (platform font) instead of `textTheme` — font mismatch with branded hosts.
- [ ] **V5. Pills overflow on long LLM labels in Wrap** — add Flexible + ellipsis.
- [ ] **V6. Boxes-in-boxes clutter** — every block self-frames; nested frames inside accordion/section. Add GenUiFrameScope suppression.
- [ ] **V7. RTL: physical EdgeInsets/Alignment** → use Directional variants.
- [ ] **V8. Off-scale magic spacing numbers** scattered (2,3,5,6px...) — normalize to GenUiSpace.

## UX — Accessibility (Flutter) — zero Semantics in entire package

- [ ] **A1. GenUiPressable not keyboard-focusable** (bare GestureDetector — WCAG 2.1.1). Add FocusableActionDetector + focus ring.
- [ ] **A2. Icon-only controls unlabeled** (rating stars, stepper +/-, send icons) — add Semantics labels.
- [ ] **A3. Selection state invisible to screen readers** (pill/checklist/poll/quiz selected state is color-only) — Semantics(selected/checked).
- [ ] **A4. Charts invisible to screen readers** — wrap in Semantics(label: generated data summary) + ExcludeSemantics.
- [ ] **A5. No contrast guard on spec-provided colors**; textPrimary near-white assumes dark bg → white-on-white when spec sets light bg. Luminance-based default text color.
- [ ] **A6. Gallery images: no alt text** (schema lacks the field) — accept {url,alt} objects.
- [ ] **A7. Touch targets < 44dp** (stepper 38px, send icon 22px).
- [ ] **A8. Timer: no SemanticsService.announce on completion.**
- [ ] **A9. Fixed heights clip at large text scale** (poll bar 40px, calc keys 46px, chart reservedSize).
- [ ] **A10. Hardcoded English strings** — add GenUiLocalizations hook.

## TS/JS layer (worktree packages/js) — reviewed directly

**Core (`ethereal-genui-core`): solid.** json_patch delegates to fast-json-patch with banPrototypeModifications + OOB-replace guard; missing `path` throws→skipped (Dart wipe bug NOT ported). Stream-repair parser correct. 37/37 tests pass.

- [x] **J1. Schema still advertises `chart:"area"`** (`genui_schema.ts:233`) but React ChartRenderer falls back to bar — same drift as Dart.

**React (`ethereal-genui-react`): 284/284 tests pass, no XSS sinks found. Issues:**

- [x] **J2 (CRITICAL). No ErrorBoundary anywhere** — any renderer crash (e.g. `gallery.images` as string → `.map` TypeError; object rendered as React child via `label as string`) unmounts the host's entire React tree. Wrap GenUiBlock in an error boundary rendering GenUiBlockError.
- [x] **J3 (CRITICAL, parity with C4).** Theme/Shortcuts directives auto-fire `setAccent`/`setShortcuts` in mount useEffect (eslint-disabled deps) — same prompt-injection persistence vector as Flutter.
- [x] **J4 (HIGH, parity with C3).** No recursion depth cap — Box/When/Grid/etc recurse via GenUiBlock; deep spec → RangeError; huge children → DOM explosion.
- [x] **J5. Chart: `Number(d.value)` lets NaN poison SVG** (NaN maxValue → all bars NaN); negative values → invalid rect heights. Sanitize with Number.isFinite + clamp ≥0.
- [x] **J6. Gallery: same tracking-pixel/plaintext-http issue** (https-only + array guard done; alt-text still open) as Flutter (`startsWith('http')`); `alt=""` always; `spec.images` non-array crashes (see J2).
- [x] **J7. Box: `spec.bg` passed raw into CSS `background`** — allows `url(https://evil/pixel)` remote-fetch exfil via CSS. Validate against a color/gradient whitelist regex.
- [ ] **J8. useGenUiStream: unmemoized `subscribe`** → resubscribes every render; and segments come only from `streamingText`, which nulls on TEXT_MESSAGE_END → rendered blocks vanish when the turn completes (consumer must re-derive from `messages` — API gap; verify intended usage and document or fix).
- [ ] **J9. Timer/state renderers don't resync when spec changes via patch** (useState initializer only) — same stale-state class as Flutter H3. Also `spec.seconds` unclamped (negative → "-1:-5" display).
- [x] **J10. Slider/most inputs ignore `actions.enabled`** — FIXED 2026-07-07 via `GenUiInteractionBoundary` (new `GenUiInteraction.tsx`), React parity with U1's Dart fix — same reset-on-enabled-transition semantics.
- [ ] **J11. Artifact/clickable divs are `<div onClick>`** not `<button>` — keyboard/a11y gap (parity with A1); artifact always shows "tap to open" even with no openArtifact wired (U5).

## LLM adapter package (worktree packages/dart/ethereal_genui_llm)

- [x] **L1 (CRITICAL). Gemini API key in URL query string** — leaks into ClientException.toString() → crash reporters/logs. Use `x-goog-api-key` header.
- [x] **L2 (CRITICAL, docs).** Direct-connection examples embed `sk-ant-...` keys in client code with no production warning — document as prototype-only, point to proxy pattern.
- [x] **L3 (HIGH). `http.Client()` never closed** in all 3 adapters — socket/client leak per request. try/finally close.
- [x] **L4 (HIGH). Gemini adapter breaks on parallel tool calls** — doesn't merge consecutive tool-result messages into one `contents` entry (Anthropic adapter does; copy that grouping).
- [x] **L5 (HIGH). GenUiChat: setState after await with no mounted guard**; stream not cancelled on dispose.
- [x] **L6. Zero test coverage for real SSE adapters** — add canned-SSE-fixture tests (split chunks, multi-tool-call).

## Test evidence

- Root repo: `flutter analyze` clean. TS core: 37/37 pass. React: 284/284 pass.
- Existing tests don't cover: malformed-spec inputs, streaming patch updates to stateful widgets, security scenarios — add regression tests alongside fixes.

---

# FIX SPEC — per-file implementation guide (plan-only, written 2026-07-04)

All paths below are in the ACTIVE worktree: `.claude\worktrees\ethereal-expansion\` unless marked ROOT. Apply nothing to root `lib/` until you decide whether to keep it (recommend: delete root copy or make it a git subtree of the worktree package to end the drift).

## Batch 1 — Critical bugs & security (pre-publish blockers)

### 1.1 json_patch missing-path wipe (C2)
**File:** `packages/dart/ethereal_genui_core/lib/src/json_patch.dart`, `_applyOne`
Missing `path`/`from` keys must invalidate the op (throw → caught → skipped), while an explicit `""` stays valid RFC whole-doc pointer:
```dart
Object? _applyOne(Object? doc, Map op) {
  final type = (op['op'] ?? '').toString();
  if (!op.containsKey('path')) throw const FormatException('op missing path');
  final path = op['path'].toString();
  // in 'move'/'copy' branches:
  if (!op.containsKey('from')) throw const FormatException('op missing from');
```
**Tests** (`test/json_patch_test.dart`): `{"op":"replace","value":X}` leaves doc unchanged; `{"op":"remove"}` leaves doc unchanged; explicit `{"op":"replace","path":"","value":X}` still replaces whole doc.
TS core needs no change (verified: fast-json-patch throws on undefined path).

### 1.2 8-digit hex color (C1)
**File:** `packages/dart/ethereal_genui/lib/src/renderers/directives.dart`, `parseHexColor`
Input convention is `RRGGBBAA` (schema example `#ffffff22`); `Color()` wants `AARRGGBB`:
```dart
if (h.length == 8) h = h.substring(6, 8) + h.substring(0, 6);
if (h.length == 6) h = 'FF$h';
if (h.length != 8) return null;
```
Also accept 3-digit shorthand (`#fff` → expand) since the React port's regex accepts 3-8 digits — keeps platforms consistent.
**React parity check:** anywhere the React/CSS side passes hex straight to CSS is fine (CSS is RRGGBBAA natively) — do NOT "fix" the TS side; add a cross-language fixture test documenting that both render `#ffffff22` as translucent white.
**Tests:** `parseHexColor('#ffffff22')` → `Color(0x22FFFFFF)`; 6-digit unchanged; garbage → null.

### 1.3 Directive consent gate (C4 / J3)
**Flutter:** `packages/dart/ethereal_genui/lib/src/renderers/directives.dart`
Delete both `initState` auto-fire blocks. Render the existing card with a confirm affordance instead:
- theme: swatch + "Apply accent?" → `GenUi.pill(context, 'Apply', () => actions.setAccent?.call(hex))`
- shortcuts: list preview + "Save shortcuts?" pill → `actions.setShortcuts?.call(items)`
After tap, swap pill for a checkmark row (local `_applied` bool).
**React:** `packages/js/ethereal-genui-react/src/components/renderers/ThemeDirectiveRenderer.tsx` + `ShortcutsDirectiveRenderer.tsx` — delete both `useEffect` blocks (and the eslint-disable lines), add the same Apply button pattern with `useState(applied)`.
**Tests:** rendering the directive does NOT call setAccent/setShortcuts; tapping Apply calls it once. Update `ShortcutsDirectiveRenderer.test.tsx` + `ThemeDirectiveRenderer.test.tsx` which currently assert auto-fire.

### 1.4 Recursion depth cap + child count cap (C3 / J4)
**Flutter:** `packages/dart/ethereal_genui/lib/src/genui_block.dart`
Zone-free approach — an InheritedWidget depth counter:
```dart
class _GenUiDepth extends InheritedWidget { final int depth; ... }
Widget buildGenUiSpec(BuildContext context, Map<String, dynamic> spec, GenUiActions actions) {
  final depth = _GenUiDepth.of(context); // 0 if absent
  if (depth > 24) return genUiPlaceholder(context, type: 'too-deep');
  ... return _GenUiDepth(depth: depth + 1, child: builder(...));
}
```
Child caps: in `genUiOptions` (core `genui_options.dart`) `.take(100)`; in `_kids/_children/_maps` helpers `.take(200)`; `rating.max` clamp to 1..20 in `interactive.dart`; table rows `.take(200)`.
**React:** `packages/js/ethereal-genui-react/src/components/GenUiBlock.tsx`
```tsx
const DepthCtx = createContext(0)
export function GenUiBlock(...) {
  const depth = useContext(DepthCtx)
  if (depth > 24) return <GenUiPlaceholder type="too-deep" .../>
  return <DepthCtx.Provider value={depth + 1}>{renderSwitch()}</DepthCtx.Provider>
}
```
(Every container already recurses via GenUiBlock, so one gate covers all.)
**Tests:** 30-deep nested box renders placeholder not crash; rating max=1e9 renders 20 stars.

### 1.5 React ErrorBoundary (J2)
**New file:** `packages/js/ethereal-genui-react/src/components/GenUiErrorBoundary.tsx` — class component, `getDerivedStateFromError`, renders existing `<GenUiBlockError/>`. Wrap the switch in `GenUiBlock` with it (inside DepthCtx provider). Reset on `spec` identity change via `key={specHash}` or `componentDidUpdate` check.
**Test:** `{"type":"gallery","images":"nope"}` renders GenUiBlockError, sibling blocks unaffected.

### 1.6 Unchecked casts sweep (H2)
**Files (worktree Flutter renderers):** `display.dart`, `primitives.dart`, `containers.dart`, `charts.dart`, `inputs.dart`, `interactive.dart`, `decisions.dart`, `minitools.dart`, `directives.dart`
Mechanical rules:
- `x as List<dynamic>? ?? const []` → `x is List ? x : const []` (fix inside `_maps`, `_kids`, `_children` helpers first — covers most call sites)
- `spec['title'] as String?` / `(a ?? b) as String?` → `?.toString()` — grep `as String\?` (11 hits) and `as List<dynamic>\?`
- `inputs.dart` FormRenderer toggle: `_values[key] is bool ? _values[key] as bool : (f['value'] == true)`
**Test:** one parameterized "hostile spec" test feeding every block type `{"title":123,"items":"x","children":{},"options":42}` asserting no throw.

### 1.7 Slider + stepper + grid numeric guards (H1/H6/M1/M2/M3)
- `inputs.dart` SliderRenderer: `final lo = math.min(minRaw, maxRaw); final hi = math.max(...); if (lo == hi) hi = lo + 1;` use lo/hi everywhere; `divisions`: `final d = ((hi-lo)/step).round(); divisions = d >= 1 ? d : null;`
- `interactive.dart` StepperRenderer: guards become `_value + step <= max` / `_value - step >= min`; seed `_value = _value.clamp(min, max)`.
- `containers.dart` GridRenderer: `cols.clamp(1, 12)`, `width = width.isFinite && width > 0 ? width : null`.
- `primitives.dart`: clamp `gap`, `width`, `height`, `size`, `padding` ≥ 0 at the `_num` helper level: add `_numClamped(v, def) => (_num(v, def)).clamp(0, double.infinity)` for dimension call sites.
- `display.dart` TableRenderer: `if (columns.isEmpty) return const SizedBox.shrink();`
- **React** `ChartRenderer.tsx`: `const v = Number(d.value); value: Number.isFinite(v) && v >= 0 ? v : 0`.

### 1.8 LLM package security (L1-L5)
**`packages/dart/ethereal_genui_llm/lib/src/adapters/gemini_adapter.dart`:** move key out of URL → `request.headers['x-goog-api-key'] = apiKey;` URL loses `&key=`.
**All 3 adapters:** own the client:
```dart
final client = http.Client();
try { final response = await client.send(request); yield* ...; }
finally { client.close(); }
```
(inside the stream generator use `try/finally` around the `await for`.)
**Gemini parallel tool calls:** copy the Anthropic adapter's consecutive-`tool`-message grouping — accumulate into one `contents` entry with multiple `functionResponse` parts.
**`packages/dart/ethereal_genui/lib/src/widgets/genui_chat.dart`:** `if (!mounted) return;` before each setState after await; hold the StreamSubscription and cancel in dispose (convert `await for` → `.listen` or check mounted each iteration).
**Docs:** doc-comment on `GenUiDirectConnection` + README: keys ship in the binary; prototype-only; proxy for production.
**Tests (L6):** new `test/adapters_test.dart` with canned SSE fixtures via a stub `http.Client` (split-chunk, multi-tool-call, error event) for all 3 adapters.

### 1.9 Gallery hardening (H5/J6)
Flutter `display.dart`: `u.startsWith('https://')`; `Image.network(..., cacheWidth: 400)`; schema: accept `{"url","alt"}` objects (keep string form), pass `semanticLabel: alt`.
React `GalleryRenderer.tsx`: same https filter; `Array.isArray(spec.images)` guard; `alt={altText ?? ''}` + `loading="lazy"` + `referrerPolicy="no-referrer"`.
React `BoxRenderer.tsx` (J7): validate `spec.bg`/`border`/`gradient` entries against `/^#[0-9a-fA-F]{3,8}$|^(rgb|hsl)a?\([\d\s.,%\/]+\)$|^[a-zA-Z]+$/` before injecting into style; reject anything containing `url(` or `var(`.

## Batch 2 — Consent/trust docs (half day) — DONE 2026-07-07 (SECURITY.md + area chart + validator child recursion, both platforms; see plan file snug-meandering-snowflake.md for full verification detail)
- SECURITY.md in repo root: threat model (spec = attacker-influenced), label/value decoupling caveat, unscoped `set` caveat, html-artifact host requirements (iframe `sandbox=""` no allow-same-origin+allow-scripts combo, CSP, no JS bridges, block file://), image-loading behavior, directive consent model.
- `genui_schema.dart`/`genui_schema.ts`: fix the `artifact` note to say "host-provided sandbox — see SECURITY.md" instead of claiming a sandbox exists. Either implement `area` chart in both renderers (line variant with filled `belowBarData` / existing polygon in React already draws fill — just wire `'area'` case to LineChart with opacity fill) or remove from both enum lists. Add `child` recursion to `validateGenUiSpec` (`_validateInto`: `final child = node['child']; if (child is Map) _validateInto(child, '$path.child', issues);`).

## Batch 3 — UX foundation
### 3.1 Dispatched-lock (U1) — DONE 2026-07-07 (see U1/J10 above; implemented as a centralized dispatch boundary, not the per-call-site design sketched below — left for historical reference):
`genui_theme.dart` GenUiPressable: add `bool lockOnTap` (default false→opt-in per call site) OR simpler: central helper in `genui_common.dart`:
```dart
// GenUi.pill/submitButton gain `oneShot: true` param: wraps onTap so after
// first invocation the pill rebuilds disabled with 0.6 opacity until
// actions.enabled flips false→true again (host round-trip completed).
```
Simplest robust shape: a `_GenUiOneShot` StatefulWidget wrapper owning `_fired`; reset when `actions.enabled` transitions false→true. Apply to pill/submitButton/checklist submit/rating stars/stepper send.
### 3.2 GenUiColors.fromTheme (V1) — DONE 2026-07-07, ThemeExtension part (V2) still open, see V2 note above.
`genui_theme.dart`: add factory reading `Theme.of(context)`: surface←colorScheme.surfaceContainerLow, hairline←outlineVariant.withValues(alpha:.4), textPrimary←onSurface, accent←primary, etc.; branch nothing on brightness explicitly (colorScheme already encodes it). `GenUiColors.of`: `resolver ?? Theme.of(context).extension<GenUiThemeExt>()?.colors ?? fromTheme(context)`. Keep `nocturne` as named const. New `GenUiThemeExt extends ThemeExtension` bundling colors+radii+text-style overrides.
### 3.3 Terminal error state (U3)
`genui_block.dart`: `GenUiBlock({..., this.closed = true})` — when `closed && spec == null` render "Couldn't display this block" variant (danger-tinted placeholder) instead of "Preparing…". Chat widget passes `closed: segment.closed`.
### 3.4 didUpdateWidget resync (H3/J9)
`interactive.dart` PollRenderer/StepperRenderer, `minitools.dart` ConverterRenderer/TimerRenderer: implement `didUpdateWidget` — recompute derived fields when relevant spec fields changed (compare old vs new). Poll: rebuild `_votes` but preserve user's own `_voted` index by option value. Timer: if `seconds` changed, reset `_total/_remaining` and stop.
React TimerRenderer: `useEffect(() => { setRemaining(total); setRunning(false) }, [total])`.
### 3.5 Small fixes: stepper send icon → GenUiPressable (U4); artifact onTap null when `openArtifact == null` + hide "tap to open" (U5, both platforms); MouseRegion click cursor in GenUiPressable (U6); AnimatedFractionallySizedBox for poll bar / AnimatedSize for accordion / AnimatedContainer for quiz reveal using GenUiMotion.quick (U7); empty-state placeholder for chart/gallery/badges (U8); pill label `Flexible + ellipsis` (V5); `EdgeInsetsDirectional`/`AlignmentDirectional` sweep (V7); route pill/button/chart-label TextStyles through textTheme (V4); unify frames via `GenUi.frame` variants (V3/V6 — add `GenUi.flatFrame` and a `GenUiFrameScope` InheritedWidget that suppresses nested frames).

## Batch 4 — Accessibility (Flutter; TS side lands via your 6d/6e)
- A1: GenUiPressable → wrap in `FocusableActionDetector(actions: {ActivateIntent: ...}, mouseCursor: click)`; visible focus ring (2px accent border when `_focused`).
- A2/A3: `GenUi.pill(..., {String? semanticLabel, bool? selected, bool? checked})` → `Semantics(button: true, selected: selected, checked: checked, label: ...)`. Rating star: `Semantics(label: 'Rate $i of $max')`. Stepper: 'Increase/Decrease $label'.
- A4: charts: `Semantics(label: _summarize(data), child: ExcludeSemantics(chart))` — "$title. Bar chart. Mon 3, Tue 5…" (cap 10 points then "and N more").
- A5: contrast guard — when spec sets `bg`, compute `ThemeData.estimateBrightnessForColor(bg)` and flip default text color for descendants (thread it via a `DefaultTextStyle` in BoxRenderer).
- A7: stepper buttons 44×44; send icon `SizedBox(44,44, child: Center(icon))`.
- A8: `SemanticsService.announce('$label timer finished', dir)` at 0.
- A9: replace fixed heights (poll 40, calc key 46) with minHeight constraints.
- A10: `GenUiStrings` resolver global (mirror colors resolver) with English defaults: submit/send/yes/no/preparing/unsupported/pause/resume/start/savedToShortcuts/applyAccent.

## Batch 5 — API polish
- Export `GenUiOption`, `genUiOptions` from `ethereal_genui.dart` (M7).
- Checklist `_checked` keyed by option value not index (M6).
- useGenUiStream: `useCallback(subscribe, [processor])`; decide/document end-of-turn behavior — recommend: hook also exposes `completedMessages` parsed via parseSegments so blocks persist after TEXT_MESSAGE_END (J8).
- ChoicesRenderer label-vs-value: when `label != value` on a send-gating control, host-facing doc note + optional `showsOutgoingText` mode (design decision, document in SECURITY.md for now).

## Suggested commit sequence
1. `fix(core): json-patch missing path/from guards` (+tests)
2. `fix(flutter): hex RRGGBBAA parsing` (+cross-lang fixture)
3. `fix: directive consent gates (flutter+react)` (+test updates)
4. `fix: recursion depth caps + react error boundary` (+tests)
5. `fix(flutter): hostile-spec cast hardening` (+hostile spec test)
6. `fix: numeric guards (slider/stepper/grid/chart/table)`
7. `fix(llm): gemini key header, client lifecycle, parallel tool calls, chat mounted guards` (+SSE fixture tests)
8. `fix: gallery/box url+css hardening`
9. `docs: SECURITY.md + schema honesty (artifact note, area chart)`
10. Batch 3/4/5 as separate PRs aligned with Tasks 6d/6e.

## Review

(to be filled after fixes)
