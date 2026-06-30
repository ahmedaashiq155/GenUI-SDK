# Changelog

## 0.1.0

Initial extraction from the Ethereal chat app into a standalone, app-agnostic
Flutter package.

- Pluggable renderer registry (`register(type, builder)`).
- Single-source-of-truth block schema → model prompt + validation.
- ~40 block types: decisions, inputs/forms, display, charts, layout containers,
  freeform primitives, offline mini-tools, and `artifact`/`tool_call` cards.
- Durable per-widget state via `GenUiStateScope` + `GenUiPersistedState`.
- RFC-6902 JSON Patch (`applyJsonPatch`) for an incremental delta loop.
- Host-agnostic theming via `genUiColorResolver` (no app-shell imports).
