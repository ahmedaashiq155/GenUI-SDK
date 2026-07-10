/// Single source of truth for the generative-UI block catalog.
///
/// One declarative [GenUiBlockSchema] per block type drives BOTH:
///  - the model-facing prompt catalogue ([buildGenUiPromptCatalogue]), and
///  - spec validation ([validateGenUiSpec]).
///
/// Previously the catalog lived twice — as a hand-written prose blob in the
/// system prompt and implicitly across the renderer files — and the two drifted.
/// Adding or changing a block type now happens here, in one place.
library;

/// Bumped when the block schema changes in a way models/clients should notice.
const genUiSchemaVersion = 2;

/// Editorial grouping — mirrors how the catalogue reads to the model.
enum GenUiCategory {
  interactive,
  display,
  moreInteractive,
  charts,
  moreDisplay,
  miniTools,
  layout,
  primitives,
  artifact,
  directive,
}

/// A field a block may carry. [type] is advisory (used by validation + docs):
/// one of string | int | double | bool | num | list | map | color | enum.
class GenUiField {
  const GenUiField(
    this.name,
    this.type, {
    this.required = false,
    this.enumValues,
  });

  final String name;
  final String type;
  final bool required;
  final List<String>? enumValues;
}

/// The schema for one block type.
class GenUiBlockSchema {
  const GenUiBlockSchema({
    required this.type,
    required this.category,
    required this.example,
    this.fields = const [],
    this.aliases = const [],
    this.childrenAllowed = false,
    this.note,
  });

  /// Canonical type string (e.g. `choices`).
  final String type;

  /// Alternate type strings that render the same block (e.g. `kpi` → `stat`).
  final List<String> aliases;

  final GenUiCategory category;

  /// A compact, valid JSON example shown to the model (verbatim quality).
  final String example;

  final List<GenUiField> fields;

  /// Whether this block composes child blocks via `children`/`content`/etc.
  final bool childrenAllowed;

  /// Optional extra guidance appended to the example in the prompt.
  final String? note;

  Iterable<String> get allTypes => [type, ...aliases];
}

// Common reusable field shapes.
const _id = GenUiField('id', 'string');

/// The full catalog. Order within a category is the order shown to the model.
const List<GenUiBlockSchema> genUiCatalog = [
  // ── Interactive (a tap/submit becomes the user's next message) ──────────
  GenUiBlockSchema(
    type: 'choices',
    category: GenUiCategory.interactive,
    example: '{"type":"choices","title":"optional","options":["A","B"]}',
    fields: [GenUiField('title', 'string'), GenUiField('options', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'actions',
    category: GenUiCategory.interactive,
    example:
        '{"type":"actions","actions":[{"label":"Yes","send":"Yes, do it","primary":true},{"label":"No","send":"No"}]}',
    fields: [GenUiField('title', 'string'), GenUiField('actions', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'confirm',
    category: GenUiCategory.interactive,
    example:
        '{"type":"confirm","prompt":"Delete this?","confirmLabel":"Delete","cancelLabel":"Keep"}',
    fields: [
      GenUiField('prompt', 'string', required: true),
      GenUiField('confirmLabel', 'string'),
      GenUiField('cancelLabel', 'string'),
    ],
  ),
  GenUiBlockSchema(
    type: 'suggestions',
    category: GenUiCategory.interactive,
    example: '{"type":"suggestions","options":["Tell me more","Give an example"]}',
    fields: [GenUiField('options', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'input',
    category: GenUiCategory.interactive,
    example:
        '{"type":"input","label":"Your name?","placeholder":"e.g. Sam","submitLabel":"Send"}',
    fields: [
      GenUiField('label', 'string'),
      GenUiField('placeholder', 'string'),
      GenUiField('submitLabel', 'string'),
      _id,
    ],
  ),
  GenUiBlockSchema(
    type: 'multiselect',
    category: GenUiCategory.interactive,
    example:
        '{"type":"multiselect","title":"Pick toppings","options":["Cheese","Olives"],"submitLabel":"Order"}',
    fields: [
      GenUiField('title', 'string'),
      GenUiField('options', 'list', required: true),
      GenUiField('submitLabel', 'string'),
      _id,
    ],
  ),
  GenUiBlockSchema(
    type: 'slider',
    category: GenUiCategory.interactive,
    example:
        '{"type":"slider","label":"Spiciness","min":0,"max":5,"step":1,"value":2,"unit":"/5"}',
    fields: [
      GenUiField('label', 'string'),
      GenUiField('min', 'num'),
      GenUiField('max', 'num'),
      GenUiField('step', 'num'),
      GenUiField('value', 'num'),
      GenUiField('unit', 'string'),
      _id,
    ],
  ),
  GenUiBlockSchema(
    type: 'form',
    category: GenUiCategory.interactive,
    example:
        '{"type":"form","title":"Booking","fields":[{"key":"name","label":"Name","type":"text"},{"key":"guests","label":"Guests","type":"number"},{"key":"seat","label":"Seating","type":"select","options":["Indoor","Outdoor"]},{"key":"vip","label":"VIP","type":"toggle"}],"submitLabel":"Submit"}',
    fields: [
      GenUiField('title', 'string'),
      GenUiField('fields', 'list', required: true),
      GenUiField('submitLabel', 'string'),
      _id,
    ],
  ),

  // ── Display only (no interaction) ───────────────────────────────────────
  GenUiBlockSchema(
    type: 'card',
    category: GenUiCategory.display,
    example:
        '{"type":"card","title":"...","subtitle":"...","items":[{"label":"Key","value":"Val"}]}',
    fields: [
      GenUiField('title', 'string'),
      GenUiField('subtitle', 'string'),
      GenUiField('items', 'list'),
    ],
  ),
  GenUiBlockSchema(
    type: 'callout',
    category: GenUiCategory.display,
    example: '{"type":"callout","style":"info|warn|success","title":"...","text":"..."}',
    fields: [
      GenUiField('style', 'enum', enumValues: ['info', 'warn', 'warning', 'success']),
      GenUiField('title', 'string'),
      GenUiField('text', 'string'),
    ],
  ),
  GenUiBlockSchema(
    type: 'stat',
    aliases: ['kpi'],
    category: GenUiCategory.display,
    example: '{"type":"stat","title":"...","stats":[{"label":"Users","value":"1.2k"}]}',
    fields: [GenUiField('title', 'string'), GenUiField('stats', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'table',
    category: GenUiCategory.display,
    example: '{"type":"table","columns":["A","B"],"rows":[["1","2"],["3","4"]]}',
    fields: [
      GenUiField('columns', 'list', required: true),
      GenUiField('rows', 'list', required: true),
    ],
  ),

  // ── More interactive ────────────────────────────────────────────────────
  GenUiBlockSchema(
    type: 'rating',
    category: GenUiCategory.moreInteractive,
    example: '{"type":"rating","max":5}',
    fields: [GenUiField('max', 'int'), _id],
  ),
  GenUiBlockSchema(
    type: 'segmented',
    category: GenUiCategory.moreInteractive,
    example: '{"type":"segmented","options":["A","B"]}',
    fields: [GenUiField('options', 'list', required: true), _id],
  ),
  GenUiBlockSchema(
    type: 'stepper',
    category: GenUiCategory.moreInteractive,
    example: '{"type":"stepper","label":"Qty","min":1,"max":9,"value":2}',
    fields: [
      GenUiField('label', 'string'),
      GenUiField('min', 'num'),
      GenUiField('max', 'num'),
      GenUiField('value', 'num'),
      _id,
    ],
  ),
  GenUiBlockSchema(
    type: 'checklist',
    category: GenUiCategory.moreInteractive,
    example: '{"type":"checklist","items":["a","b"]}',
    fields: [
      GenUiField('items', 'list', required: true),
      GenUiField('title', 'string'),
      GenUiField('submitLabel', 'string'),
      _id,
    ],
  ),
  GenUiBlockSchema(
    type: 'poll',
    category: GenUiCategory.moreInteractive,
    example: '{"type":"poll","options":[{"label":"A","votes":3}]}',
    fields: [GenUiField('options', 'list', required: true), GenUiField('title', 'string'), _id],
  ),
  GenUiBlockSchema(
    type: 'quiz',
    category: GenUiCategory.moreInteractive,
    example: '{"type":"quiz","question":"…","options":["…"],"answer":1,"explanation":"…"}',
    fields: [
      GenUiField('question', 'string', required: true),
      GenUiField('options', 'list', required: true),
      GenUiField('answer', 'int', required: true),
      GenUiField('explanation', 'string'),
      _id,
    ],
  ),

  // ── Charts ──────────────────────────────────────────────────────────────
  GenUiBlockSchema(
    type: 'chart',
    category: GenUiCategory.charts,
    example:
        '{"type":"chart","chart":"bar|line|area|pie","title":"…","data":[{"label":"Mon","value":3},{"label":"Tue","value":5}]}',
    fields: [
      GenUiField('chart', 'enum', enumValues: ['bar', 'line', 'pie', 'area']),
      GenUiField('title', 'string'),
      GenUiField('data', 'list', required: true),
    ],
  ),

  // ── More display ────────────────────────────────────────────────────────
  GenUiBlockSchema(
    type: 'timeline',
    aliases: ['steps'],
    category: GenUiCategory.moreDisplay,
    example: '{"type":"timeline","items":[{"title":"…","subtitle":"…","done":true}]}',
    fields: [GenUiField('items', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'progress',
    category: GenUiCategory.moreDisplay,
    example: '{"type":"progress","label":"…","value":0.6}',
    fields: [GenUiField('label', 'string'), GenUiField('value', 'num', required: true)],
  ),
  GenUiBlockSchema(
    type: 'badges',
    aliases: ['chips'],
    category: GenUiCategory.moreDisplay,
    example: '{"type":"badges","items":["new"]}',
    fields: [GenUiField('items', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'gallery',
    category: GenUiCategory.moreDisplay,
    example: '{"type":"gallery","images":["https://…"]}',
    fields: [GenUiField('images', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'divider',
    category: GenUiCategory.moreDisplay,
    example: '{"type":"divider"}',
  ),

  // ── Local mini-tools (no round-trip) ────────────────────────────────────
  GenUiBlockSchema(
    type: 'calculator',
    category: GenUiCategory.miniTools,
    example: '{"type":"calculator"}',
  ),
  GenUiBlockSchema(
    type: 'converter',
    category: GenUiCategory.miniTools,
    example:
        '{"type":"converter","title":"Length","units":[{"label":"m","factor":1},{"label":"km","factor":1000}]}',
    fields: [GenUiField('title', 'string'), GenUiField('units', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'timer',
    category: GenUiCategory.miniTools,
    example: '{"type":"timer","seconds":60,"label":"…"}',
    fields: [GenUiField('seconds', 'int'), GenUiField('label', 'string')],
  ),

  // ── Layout (compose the above as children) ──────────────────────────────
  GenUiBlockSchema(
    type: 'section',
    category: GenUiCategory.layout,
    childrenAllowed: true,
    example: '{"type":"section","children":[ {…}, {…} ]}',
    fields: [GenUiField('children', 'list', required: true), GenUiField('title', 'string')],
  ),
  GenUiBlockSchema(
    type: 'grid',
    category: GenUiCategory.layout,
    childrenAllowed: true,
    example: '{"type":"grid","columns":2,"children":[ {…}, {…} ]}',
    fields: [GenUiField('children', 'list', required: true), GenUiField('columns', 'int')],
  ),
  GenUiBlockSchema(
    type: 'columns',
    category: GenUiCategory.layout,
    childrenAllowed: true,
    example: '{"type":"columns","children":[ {…}, {…} ]}',
    fields: [GenUiField('children', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'accordion',
    category: GenUiCategory.layout,
    childrenAllowed: true,
    example: '{"type":"accordion","items":[{"title":"…","content":{…}}]}',
    fields: [GenUiField('items', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'tabs',
    category: GenUiCategory.layout,
    childrenAllowed: true,
    example: '{"type":"tabs","tabs":[{"label":"…","content":{…}}]}',
    fields: [GenUiField('tabs', 'list', required: true)],
  ),
  GenUiBlockSchema(
    type: 'when',
    category: GenUiCategory.layout,
    childrenAllowed: true,
    example: '{"type":"when","key":"view","equals":"new","child":{…}}',
    note:
        'client-side conditional — shows its child only when state[key] equals '
        '"equals" (or is truthy). Pair with a button "set" to switch views '
        'in-place, with no message sent',
    fields: [
      GenUiField('key', 'string', required: true),
      GenUiField('equals', 'string'),
      GenUiField('child', 'map'),
      GenUiField('children', 'list'),
    ],
  ),

  // ── Freeform primitives ─────────────────────────────────────────────────
  GenUiBlockSchema(
    type: 'box',
    aliases: ['container'],
    category: GenUiCategory.primitives,
    childrenAllowed: true,
    example:
        '{"type":"box","bg":"#14171F","gradient":["#8B93FF","#7FE3D0"],"padding":16,"radius":20,"border":"#ffffff22","align":"center","width":120,"height":120,"send":"optional tap message","children":[ {…} ]}',
    fields: [
      GenUiField('children', 'list'),
      GenUiField('bg', 'color'),
      GenUiField('gradient', 'list'),
      GenUiField('padding', 'num'),
      GenUiField('radius', 'num'),
      GenUiField('border', 'color'),
      GenUiField('align', 'string'),
      GenUiField('width', 'num'),
      GenUiField('height', 'num'),
      GenUiField('send', 'string'),
    ],
  ),
  GenUiBlockSchema(
    type: 'row',
    category: GenUiCategory.primitives,
    childrenAllowed: true,
    example: '{"type":"row","align":"between","cross":"center","gap":8,"expand":false,"children":[ {…} ]}',
    fields: [
      GenUiField('children', 'list'),
      GenUiField('align', 'string'),
      GenUiField('cross', 'string'),
      GenUiField('gap', 'num'),
      GenUiField('expand', 'bool'),
    ],
  ),
  GenUiBlockSchema(
    type: 'column',
    category: GenUiCategory.primitives,
    childrenAllowed: true,
    example: '{"type":"column","cross":"start","gap":6,"children":[ {…} ]}',
    fields: [
      GenUiField('children', 'list'),
      GenUiField('cross', 'string'),
      GenUiField('gap', 'num'),
    ],
  ),
  GenUiBlockSchema(
    type: 'stack',
    category: GenUiCategory.primitives,
    childrenAllowed: true,
    example: '{"type":"stack","align":"bottomRight","children":[ {…} ]}',
    fields: [GenUiField('children', 'list'), GenUiField('align', 'string')],
  ),
  GenUiBlockSchema(
    type: 'text',
    category: GenUiCategory.primitives,
    example: '{"type":"text","text":"Title","size":20,"weight":"bold","color":"#ECEEF2","align":"center"}',
    fields: [
      GenUiField('text', 'string', required: true),
      GenUiField('size', 'num'),
      GenUiField('weight', 'string'),
      GenUiField('color', 'color'),
      GenUiField('align', 'string'),
    ],
  ),
  GenUiBlockSchema(
    type: 'icon',
    category: GenUiCategory.primitives,
    example: '{"type":"icon","icon":"rocket","size":28,"color":"#8B93FF"}',
    note:
        'names: star heart check close info bolt spark fire sun moon cloud time location home search person chat play music image code rocket trophy gift cart money chart trending_up up down lock key flag bell book bulb leaf globe map food coffee link add edit delete …',
    fields: [
      GenUiField('icon', 'string', required: true),
      GenUiField('size', 'num'),
      GenUiField('color', 'color'),
    ],
  ),
  GenUiBlockSchema(
    type: 'button',
    category: GenUiCategory.primitives,
    example: '{"type":"button","label":"Play","send":"play","style":"primary|soft|ghost","icon":"play","color":"#8B93FF"}',
    note:
        'add "set":{"key":"value"} to update local state client-side (e.g. switch '
        'a "when" view) with no message sent; "send" still asks the model',
    fields: [
      GenUiField('label', 'string', required: true),
      GenUiField('send', 'string'),
      GenUiField('set', 'map'),
      GenUiField('style', 'enum', enumValues: ['primary', 'soft', 'ghost']),
      GenUiField('icon', 'string'),
      GenUiField('color', 'color'),
    ],
  ),
  GenUiBlockSchema(
    type: 'spacer',
    category: GenUiCategory.primitives,
    example: '{"type":"spacer","size":12}',
    fields: [GenUiField('size', 'num')],
  ),

  // ── Artifact ────────────────────────────────────────────────────────────
  GenUiBlockSchema(
    type: 'artifact',
    category: GenUiCategory.artifact,
    example:
        '{"type":"artifact","kind":"code|markdown|table|text|html","title":"…","content":"…","language":"dart"}',
    note:
        'kind "html" is passed to a host-provided sandbox — see SECURITY.md; '
        'use it for a fully custom interactive app/game/tool beyond the block '
        'types. Put the whole document in "content"',
    fields: [
      GenUiField('kind', 'enum',
          enumValues: ['code', 'markdown', 'table', 'text', 'html']),
      GenUiField('title', 'string'),
      GenUiField('content', 'string', required: true),
      GenUiField('language', 'string'),
    ],
  ),

  // ── Adaptive directives (act on the app) ────────────────────────────────
  GenUiBlockSchema(
    type: 'theme',
    category: GenUiCategory.directive,
    example: '{"type":"theme","accent":"#8B93FF"}',
    fields: [GenUiField('accent', 'color', required: true)],
  ),
  GenUiBlockSchema(
    type: 'shortcuts',
    category: GenUiCategory.directive,
    example: '{"type":"shortcuts","items":["Plan my week","Summarize a doc"]}',
    fields: [GenUiField('items', 'list', required: true)],
  ),
];

/// Every valid type string (canonical + aliases).
final Set<String> genUiKnownTypes = {
  for (final b in genUiCatalog) ...b.allTypes,
};

/// Lookup by canonical type or alias.
GenUiBlockSchema? genUiSchemaFor(String type) {
  for (final b in genUiCatalog) {
    if (b.type == type || b.aliases.contains(type)) return b;
  }
  return null;
}

// ── Prompt catalogue generation ───────────────────────────────────────────

const _promptIntro =
    'You can render interactive UI in your reply by emitting a fenced code block with language `ui` containing ONE JSON object. You may include several `ui` blocks. Always also reply in normal prose; use UI sparingly, only when it genuinely helps. Put nothing but the JSON object inside a `ui` block.';

/// Per-category framing. `bullet` categories list each example on its own line
/// with a leading "- "; the rest are a single inline, semicolon-joined line.
const Map<GenUiCategory, ({String intro, bool bullet, String? outro})> _categoryMeta = {
  GenUiCategory.interactive: (
    intro: "Interactive (the user's tap/submit becomes their next message):",
    bullet: true,
    outro: null,
  ),
  GenUiCategory.display: (intro: 'Display only (no interaction):', bullet: true, outro: null),
  GenUiCategory.moreInteractive: (intro: 'More interactive:', bullet: false, outro: null),
  GenUiCategory.charts: (intro: 'Charts:', bullet: false, outro: null),
  GenUiCategory.moreDisplay: (intro: 'More display:', bullet: false, outro: null),
  GenUiCategory.miniTools: (intro: 'Local mini-tools (no round-trip):', bullet: false, outro: null),
  GenUiCategory.layout: (
    intro: 'Layout (compose the above as children) — grid takes "columns":2:',
    bullet: false,
    outro: null,
  ),
  GenUiCategory.primitives: (
    intro:
        'Freeform primitives — you are NOT limited to the components above; compose these to build ANY custom UI (cards, dashboards, game boards, scenes). Nest them freely; colors are hex; corners are auto-rounded:',
    bullet: true,
    outro: 'Prefer the high-level components when one fits; reach for primitives to invent something custom.',
  ),
  GenUiCategory.artifact: (
    intro: 'Artifact (long code/doc opens a focused panel):',
    bullet: false,
    outro: null,
  ),
  GenUiCategory.directive: (
    intro: 'Adaptive (acts on the app) — `theme` recolors this chat; `shortcuts` saves home-screen quick actions:',
    bullet: false,
    outro: null,
  ),
};

String _exampleLine(GenUiBlockSchema b) =>
    b.note == null ? b.example : '${b.example} (${b.note})';

/// Builds the model-facing UI catalogue from [genUiCatalog]. This replaces the
/// hand-maintained prose blob so the prompt can never drift from the renderers.
String buildGenUiPromptCatalogue() {
  final buf = StringBuffer(_promptIntro);
  for (final category in GenUiCategory.values) {
    final meta = _categoryMeta[category]!;
    final blocks = genUiCatalog.where((b) => b.category == category).toList();
    if (blocks.isEmpty) continue;
    buf.write('\n\n${meta.intro}');
    if (meta.bullet) {
      for (final b in blocks) {
        buf.write('\n- ${_exampleLine(b)}');
      }
    } else {
      buf.write(' ${blocks.map(_exampleLine).join('; ')}.');
    }
    if (meta.outro != null) buf.write('\n${meta.outro}');
  }
  buf.write('\n\n$_selfContainedNote');
  return buf.toString();
}

/// Steers models to build interactive apps that run in place rather than firing
/// a chat turn for every tap.
const _selfContainedNote =
    'For an interactive app, make it self-contained: switch views with a button '
    '"set":{"key":"v"} + a "when" block, keep per-widget state with a stable "id", '
    'and use the offline mini-tools — so taps update the app in place. Use "send" '
    '(which messages you and starts a new reply) only when you genuinely need to '
    'respond; never for in-app navigation.';

// ── Validation ─────────────────────────────────────────────────────────────

/// One problem found while validating a spec.
class GenUiIssue {
  const GenUiIssue(this.path, this.message);
  final String path;
  final String message;
  @override
  String toString() => '$path: $message';
}

/// Result of validating a spec tree.
class GenUiValidation {
  const GenUiValidation(this.issues);
  final List<GenUiIssue> issues;
  bool get isValid => issues.isEmpty;
  bool get hasUnknownType => issues.any((i) => i.message.startsWith('unknown type'));
}

/// Validates a parsed `ui` spec against the catalog. Tolerant by design: it
/// reports unknown types and missing required fields but does not throw, so
/// rendering can still degrade gracefully. Recurses into child blocks.
GenUiValidation validateGenUiSpec(Object? spec, {String path = r'$'}) {
  final issues = <GenUiIssue>[];
  _validateInto(spec, path, issues);
  return GenUiValidation(issues);
}

void _validateInto(Object? node, String path, List<GenUiIssue> issues) {
  if (node is! Map) return;
  final type = (node['type'] ?? '').toString();
  if (type.isEmpty) {
    issues.add(GenUiIssue(path, 'missing "type"'));
    return;
  }
  final schema = genUiSchemaFor(type);
  if (schema == null) {
    issues.add(GenUiIssue(path, 'unknown type "$type"'));
    return;
  }
  for (final f in schema.fields) {
    if (f.required && node[f.name] == null) {
      issues.add(GenUiIssue('$path.$type', 'missing required field "${f.name}"'));
    }
  }
  // Recurse ONLY into places that actually hold child blocks, so we never
  // mistake field/option descriptors (form fields, poll options, card items —
  // which legitimately have no block "type") for blocks.
  final children = node['children'];
  if (children is List) {
    for (var i = 0; i < children.length; i++) {
      _validateInto(children[i], '$path.children[$i]', issues);
    }
  }
  final child = node['child'];
  if (child is Map) {
    _validateInto(child, '$path.child', issues);
  }
  // accordion.items[].content and tabs.tabs[].content are nested blocks.
  for (final key in const ['items', 'tabs']) {
    final list = node[key];
    if (list is List) {
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is Map && item['content'] is Map) {
          _validateInto(item['content'], '$path.$key[$i].content', issues);
        }
      }
    }
  }
}
