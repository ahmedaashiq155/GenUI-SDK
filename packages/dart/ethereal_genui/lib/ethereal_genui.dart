/// Ethereal GenUI — a native, offline-capable, stateful generative-UI engine.
///
/// A model emits a small JSON `ui` block; this library renders it as real,
/// interactive Flutter widgets. Highlights:
///  - **Pluggable registry** — add a block type with one `register` call.
///  - **Single-source-of-truth schema** — one catalog drives both the model
///    prompt ([buildGenUiPromptCatalogue]) and validation ([validateGenUiSpec]).
///  - **Durable per-widget state** — [GenUiStateScope] + [GenUiPersistedState]
///    let a composition keep its state offline.
///  - **Delta loop** — [applyJsonPatch] (RFC 6902) for incremental UI/state
///    updates instead of resending the whole spec.
///  - **Host-agnostic theming** — inject colours via [genUiColorResolver]; the
///    engine imports nothing from any app shell.
///
/// Typical use:
/// ```dart
/// buildGenUiSpec(context, spec, GenUiActions(sendMessage: (t) {...}));
/// ```
library;

// Core (pure Dart — re-exported so hosts keep a single unchanged import)
export 'package:ethereal_genui_core/ethereal_genui_core.dart';

// Flutter-layer
export 'src/genui_actions.dart';
export 'src/widgets/genui_chat.dart';
export 'src/genui_block.dart' show buildGenUiSpec, genUiPlaceholder, GenUiBlock, kGenUiMaxDepth;
export 'src/genui_registry.dart';
export 'src/genui_state.dart';
export 'src/genui_theme.dart';
export 'src/genui_common.dart' show GenUi;

// AG-UI Flutter adapter
export 'src/agui_flutter_adapter.dart';

// Renderers / helpers used directly by hosts (the rest are registry-internal).
export 'src/renderers/artifact.dart' show ArtifactRenderer;
export 'src/renderers/tool_call.dart' show ToolCallRenderer;
export 'src/renderers/directives.dart' show parseHexColor;
export 'src/renderers/display.dart' show TableRenderer;
export 'src/renderers/primitives.dart' show iconByName;
export 'src/renderers/charts.dart' show chartSemanticLabel;
