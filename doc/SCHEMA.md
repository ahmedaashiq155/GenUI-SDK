# Block schema

The block catalogue is defined **once**, declaratively, in
[`lib/src/genui_schema.dart`](../lib/src/genui_schema.dart) as a list of
`GenUiBlockSchema`. That single definition drives:

1. the **model-facing prompt** — `buildGenUiPromptCatalogue()`, and
2. **validation** — `validateGenUiSpec(spec)` (tolerant; reports unknown types
   and missing required fields, recursing into real child-block slots only).

`genUiSchemaVersion` is bumped when the schema changes in a way clients should
notice.

Because the prompt is generated from the catalogue, it can never drift from the
renderers — a drift guard test asserts the registry covers exactly the catalogue
types.

## Categories

| Category | Blocks |
|---|---|
| Interactive | `choices`, `actions`, `confirm`, `suggestions`, `input`, `multiselect`, `slider`, `form` |
| Display | `card`, `callout`, `stat` (`kpi`), `table` |
| More interactive | `rating`, `segmented`, `stepper`, `checklist`, `poll`, `quiz` |
| Charts | `chart` (bar/line/pie) |
| More display | `timeline` (`steps`), `progress`, `badges` (`chips`), `gallery`, `divider` |
| Mini-tools (offline) | `calculator`, `converter`, `timer` |
| Layout | `section`, `grid`, `columns`, `accordion`, `tabs` |
| Primitives | `box` (`container`), `row`, `column`, `stack`, `text`, `icon`, `button`, `spacer` |
| Artifact | `artifact` |
| Directives | `theme`, `shortcuts` |

Stateful blocks accept an `id`; in a `GenUiStateScope` their state is restored on
build and persisted on change (see `GenUiPersistedState`).

## Regenerating this reference

The authoritative, always-current list of every block + example is the output of
`buildGenUiPromptCatalogue()`. To print it:

```dart
import 'package:ethereal_genui/ethereal_genui.dart';
void main() => print(buildGenUiPromptCatalogue());
```
