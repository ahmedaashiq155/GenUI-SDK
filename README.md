# Ethereal GenUI

A **native, offline-capable, stateful generative-UI engine for Flutter**. A model
emits a small JSON `ui` block; this package renders it as real, interactive
Flutter widgets — no HTML, no iframe, no server round-trip.

It's the engine extracted from the Ethereal chat app, with **zero dependencies on
any app shell** (only `flutter` + `fl_chart`).

## Why it's different

Most "AI UI" approaches are a spec (A2UI), an event protocol (AG-UI), or HTML in a
sandbox (MCP-UI / OpenAI Apps). This is a *shipped renderer* that combines four
things none of them have together:

- **Native rendering** — real Flutter widgets, themable, fast, offline.
- **Offline client-side mini-tools** — `calculator`, `converter`, `timer` compute
  locally with no model call.
- **Durable per-widget state** — a composition keeps its state across launches.
- **A bidirectional delta loop** — the model updates a running UI via RFC-6902
  JSON Patch instead of resending the whole spec.

## Quick start

```dart
import 'package:ethereal_genui/ethereal_genui.dart';

// Blocks follow the nearest Material Theme automatically.
buildGenUiSpec(
  context,
  {'type': 'choices', 'title': 'Pick one', 'options': ['A', 'B']},
  GenUiActions(sendMessage: (text) => print('user chose $text')),
);
```

For subtree-scoped customization, install `GenUiTheme` as a Material
`ThemeExtension`. It controls color roles, spacing, radii, motion, and frame
styling, and interpolates during animated theme changes:

```dart
final scheme = ColorScheme.fromSeed(seedColor: const Color(0xff3155cc));

MaterialApp(
  theme: ThemeData(
    colorScheme: scheme,
    extensions: [
      GenUiTheme.fromColorScheme(scheme).copyWith(
        spacing: const GenUiSpacingTheme(md: 14, lg: 18),
        frames: const GenUiFrameTheme(shadowOpacity: 0.04),
      ),
    ],
  ),
);
```

The original Ethereal dark palette remains an explicit opt-in preset with
`extensions: const [GenUiTheme.nocturne()]`. The global
`genUiColorResolver` remains temporarily available for source compatibility,
but new integrations should prefer the ThemeExtension.

Tell the model what it can emit with the generated catalogue:

```dart
final systemPrompt = buildGenUiPromptCatalogue();
```

## Extending

Add a block type without forking:

```dart
defaultGenUiRegistry.register('confetti', (context, spec, actions) =>
    ConfettiWidget(count: spec['count'] ?? 50));
```

## Layout

- `lib/ethereal_genui.dart` — public API (barrel).
- `lib/src/genui_schema.dart` — the single source of truth for block types.
- `lib/src/genui_registry.dart` — the pluggable `type → renderer` map.
- `lib/src/genui_theme.dart` — host-agnostic theming + shape/press primitives.
- `lib/src/renderers/` — one file per block family.

See `doc/SCHEMA.md` for the block catalogue and `doc/SCHEMA.md` generation notes.

## Status

`0.1.0` — extracted and in use by the Ethereal app. The schema, registry, and
theming surfaces are intended as stable public API; renderers are evolving.
