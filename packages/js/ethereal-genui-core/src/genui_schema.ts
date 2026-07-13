/// Single source of truth for the generative-UI block catalog.
///
/// One declarative GenUiBlockSchema per block type drives BOTH:
///  - the model-facing prompt catalogue (buildGenUiPromptCatalogue), and
///  - spec validation (validateGenUiSpec).

export const GENUI_SCHEMA_VERSION = 4

export type GenUiFieldType =
  | 'string' | 'int' | 'double' | 'bool' | 'num'
  | 'list' | 'map' | 'color' | 'enum'

export type GenUiCategory =
  | 'interactive' | 'display' | 'moreInteractive' | 'charts'
  | 'moreDisplay' | 'miniTools' | 'layout' | 'primitives'
  | 'artifact' | 'directive'

export interface GenUiField {
  readonly name: string
  readonly type: GenUiFieldType
  readonly required?: boolean
  readonly enumValues?: readonly string[]
}

export interface GenUiBlockSchema {
  readonly type: string
  readonly aliases?: readonly string[]
  readonly category: GenUiCategory
  readonly example: string
  readonly fields?: readonly GenUiField[]
  readonly childrenAllowed?: boolean
  readonly note?: string
  // derived helper:
  readonly allTypes: readonly string[]  // [type, ...aliases]
}

export interface GenUiIssue {
  readonly path: string
  readonly message: string
}

export interface GenUiValidation {
  readonly isValid: boolean
  readonly hasUnknownType: boolean
  readonly issues: readonly GenUiIssue[]
}

// Common reusable field shapes.
const _id: GenUiField = { name: 'id', type: 'string' }

function makeSchema(s: Omit<GenUiBlockSchema, 'allTypes'>): GenUiBlockSchema {
  return { ...s, allTypes: [s.type, ...(s.aliases ?? [])] }
}

/// The full catalog. Order within a category is the order shown to the model.
export const genUiCatalog: readonly GenUiBlockSchema[] = [
  // ── Interactive (a tap/submit becomes the user's next message) ──────────
  makeSchema({
    type: 'choices',
    category: 'interactive',
    example: '{"type":"choices","title":"optional","options":["A","B"]}',
    fields: [{ name: 'title', type: 'string' }, { name: 'options', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'actions',
    category: 'interactive',
    example: '{"type":"actions","actions":[{"label":"Yes","send":"Yes, do it","primary":true},{"label":"No","send":"No"}]}',
    fields: [{ name: 'title', type: 'string' }, { name: 'actions', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'confirm',
    category: 'interactive',
    example: '{"type":"confirm","prompt":"Delete this?","confirmLabel":"Delete","cancelLabel":"Keep"}',
    fields: [
      { name: 'prompt', type: 'string', required: true },
      { name: 'confirmLabel', type: 'string' },
      { name: 'cancelLabel', type: 'string' },
    ],
  }),
  makeSchema({
    type: 'suggestions',
    category: 'interactive',
    example: '{"type":"suggestions","options":["Tell me more","Give an example"]}',
    fields: [{ name: 'options', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'input',
    category: 'interactive',
    example: '{"type":"input","label":"Your name?","placeholder":"e.g. Sam","submitLabel":"Send"}',
    fields: [
      { name: 'label', type: 'string' },
      { name: 'placeholder', type: 'string' },
      { name: 'submitLabel', type: 'string' },
      _id,
    ],
  }),
  makeSchema({
    type: 'multiselect',
    category: 'interactive',
    example: '{"type":"multiselect","title":"Pick toppings","options":["Cheese","Olives"],"submitLabel":"Order"}',
    fields: [
      { name: 'title', type: 'string' },
      { name: 'options', type: 'list', required: true },
      { name: 'submitLabel', type: 'string' },
      _id,
    ],
  }),
  makeSchema({
    type: 'slider',
    category: 'interactive',
    example: '{"type":"slider","label":"Spiciness","min":0,"max":5,"step":1,"value":2,"unit":"/5"}',
    fields: [
      { name: 'label', type: 'string' },
      { name: 'min', type: 'num' },
      { name: 'max', type: 'num' },
      { name: 'step', type: 'num' },
      { name: 'value', type: 'num' },
      { name: 'unit', type: 'string' },
      _id,
    ],
  }),
  makeSchema({
    type: 'form',
    category: 'interactive',
    example: '{"type":"form","title":"Booking","fields":[{"key":"name","label":"Name","type":"text","required":true},{"key":"guests","label":"Guests","type":"number"},{"key":"seat","label":"Seating","type":"select","options":["Indoor","Outdoor"],"required":true},{"key":"vip","label":"VIP","type":"toggle"}],"submitLabel":"Submit"}',
    fields: [
      { name: 'title', type: 'string' },
      { name: 'fields', type: 'list', required: true },
      { name: 'submitLabel', type: 'string' },
      _id,
    ],
  }),

  // ── Display only (no interaction) ───────────────────────────────────────
  makeSchema({
    type: 'card',
    category: 'display',
    example: '{"type":"card","title":"...","subtitle":"...","items":[{"label":"Key","value":"Val"}]}',
    fields: [
      { name: 'title', type: 'string' },
      { name: 'subtitle', type: 'string' },
      { name: 'items', type: 'list' },
    ],
  }),
  makeSchema({
    type: 'callout',
    category: 'display',
    example: '{"type":"callout","style":"info|warn|success","title":"...","text":"..."}',
    fields: [
      { name: 'style', type: 'enum', enumValues: ['info', 'warn', 'warning', 'success'] },
      { name: 'title', type: 'string' },
      { name: 'text', type: 'string' },
    ],
  }),
  makeSchema({
    type: 'stat',
    aliases: ['kpi'],
    category: 'display',
    example: '{"type":"stat","title":"...","stats":[{"label":"Users","value":"1.2k"}]}',
    fields: [{ name: 'title', type: 'string' }, { name: 'stats', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'table',
    category: 'display',
    example: '{"type":"table","columns":["A","B"],"rows":[["1","2"],["3","4"]]}',
    fields: [
      { name: 'columns', type: 'list', required: true },
      { name: 'rows', type: 'list', required: true },
    ],
  }),

  // ── More interactive ────────────────────────────────────────────────────
  makeSchema({
    type: 'rating',
    category: 'moreInteractive',
    example: '{"type":"rating","max":5}',
    fields: [{ name: 'max', type: 'int' }, _id],
  }),
  makeSchema({
    type: 'segmented',
    category: 'moreInteractive',
    example: '{"type":"segmented","options":["A","B"]}',
    fields: [{ name: 'options', type: 'list', required: true }, _id],
  }),
  makeSchema({
    type: 'stepper',
    category: 'moreInteractive',
    example: '{"type":"stepper","label":"Qty","min":1,"max":9,"value":2}',
    fields: [
      { name: 'label', type: 'string' },
      { name: 'min', type: 'num' },
      { name: 'max', type: 'num' },
      { name: 'value', type: 'num' },
      _id,
    ],
  }),
  makeSchema({
    type: 'checklist',
    category: 'moreInteractive',
    example: '{"type":"checklist","items":["a","b"]}',
    fields: [
      { name: 'items', type: 'list', required: true },
      { name: 'title', type: 'string' },
      { name: 'submitLabel', type: 'string' },
      _id,
    ],
  }),
  makeSchema({
    type: 'poll',
    category: 'moreInteractive',
    example: '{"type":"poll","options":[{"label":"A","votes":3}]}',
    fields: [{ name: 'options', type: 'list', required: true }, { name: 'title', type: 'string' }, _id],
  }),
  makeSchema({
    type: 'quiz',
    category: 'moreInteractive',
    example: '{"type":"quiz","question":"…","options":["…"],"answer":1,"explanation":"…"}',
    fields: [
      { name: 'question', type: 'string', required: true },
      { name: 'options', type: 'list', required: true },
      { name: 'answer', type: 'int', required: true },
      { name: 'explanation', type: 'string' },
      _id,
    ],
  }),

  // ── Charts ──────────────────────────────────────────────────────────────
  makeSchema({
    type: 'chart',
    category: 'charts',
    example: '{"type":"chart","chart":"bar|line|area|pie","title":"…","data":[{"label":"Mon","value":3},{"label":"Tue","value":5}]}',
    fields: [
      { name: 'chart', type: 'enum', enumValues: ['bar', 'line', 'pie', 'area'] },
      { name: 'title', type: 'string' },
      { name: 'data', type: 'list', required: true },
    ],
  }),

  // ── More display ────────────────────────────────────────────────────────
  makeSchema({
    type: 'timeline',
    aliases: ['steps'],
    category: 'moreDisplay',
    example: '{"type":"timeline","items":[{"title":"…","subtitle":"…","done":true}]}',
    fields: [{ name: 'items', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'progress',
    category: 'moreDisplay',
    example: '{"type":"progress","label":"…","value":0.6}',
    fields: [{ name: 'label', type: 'string' }, { name: 'value', type: 'num', required: true }],
  }),
  makeSchema({
    type: 'badges',
    aliases: ['chips'],
    category: 'moreDisplay',
    example: '{"type":"badges","items":["new"]}',
    fields: [{ name: 'items', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'gallery',
    category: 'moreDisplay',
    example: '{"type":"gallery","images":["https://…"],"alt":["Description"]}',
    fields: [
      { name: 'images', type: 'list', required: true },
      { name: 'alt', type: 'list' },
    ],
  }),
  makeSchema({
    type: 'divider',
    category: 'moreDisplay',
    example: '{"type":"divider"}',
  }),

  // ── Local mini-tools (no round-trip) ────────────────────────────────────
  makeSchema({
    type: 'calculator',
    category: 'miniTools',
    example: '{"type":"calculator"}',
  }),
  makeSchema({
    type: 'converter',
    category: 'miniTools',
    example: '{"type":"converter","title":"Length","units":[{"label":"m","factor":1},{"label":"km","factor":1000}]}',
    fields: [{ name: 'title', type: 'string' }, { name: 'units', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'timer',
    category: 'miniTools',
    example: '{"type":"timer","seconds":60,"label":"…"}',
    fields: [{ name: 'seconds', type: 'int' }, { name: 'label', type: 'string' }],
  }),

  // ── Layout (compose the above as children) ──────────────────────────────
  makeSchema({
    type: 'section',
    category: 'layout',
    childrenAllowed: true,
    example: '{"type":"section","children":[ {…}, {…} ]}',
    fields: [{ name: 'children', type: 'list', required: true }, { name: 'title', type: 'string' }],
  }),
  makeSchema({
    type: 'grid',
    category: 'layout',
    childrenAllowed: true,
    example: '{"type":"grid","columns":2,"children":[ {…}, {…} ]}',
    fields: [{ name: 'children', type: 'list', required: true }, { name: 'columns', type: 'int' }],
  }),
  makeSchema({
    type: 'columns',
    category: 'layout',
    childrenAllowed: true,
    example: '{"type":"columns","children":[ {…}, {…} ]}',
    fields: [{ name: 'children', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'accordion',
    category: 'layout',
    childrenAllowed: true,
    example: '{"type":"accordion","items":[{"title":"…","content":{…}}]}',
    fields: [{ name: 'items', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'tabs',
    category: 'layout',
    childrenAllowed: true,
    example: '{"type":"tabs","tabs":[{"label":"…","content":{…}}]}',
    fields: [{ name: 'tabs', type: 'list', required: true }],
  }),
  makeSchema({
    type: 'when',
    category: 'layout',
    childrenAllowed: true,
    example: '{"type":"when","key":"view","equals":"new","child":{…}}',
    note: 'client-side conditional — shows its child only when state[key] equals "equals" (or is truthy). Pair with a button "set" to switch views in-place, with no message sent',
    fields: [
      { name: 'key', type: 'string', required: true },
      { name: 'equals', type: 'string' },
      { name: 'child', type: 'map' },
      { name: 'children', type: 'list' },
    ],
  }),
  makeSchema({
    type: 'animate',
    category: 'layout',
    childrenAllowed: true,
    example: '{"type":"animate","effect":"fade|scale|slideUp|slideDown|slideStart|slideEnd|pulse","duration":250,"delay":0,"repeat":false,"child":{…}}',
    note: 'reduce-motion-aware presentation wrapper; use repeat only for meaningful status/emphasis, never decoration',
    fields: [
      { name: 'effect', type: 'enum', enumValues: ['fade', 'scale', 'slideUp', 'slideDown', 'slideStart', 'slideEnd', 'pulse'] },
      { name: 'duration', type: 'int' },
      { name: 'delay', type: 'int' },
      { name: 'repeat', type: 'bool' },
      { name: 'child', type: 'map', required: true },
    ],
  }),

  // ── Freeform primitives ─────────────────────────────────────────────────
  makeSchema({
    type: 'box',
    aliases: ['container'],
    category: 'primitives',
    childrenAllowed: true,
    example: '{"type":"box","bg":"#14171F","gradient":["#8B93FF","#7FE3D0"],"padding":16,"radius":20,"border":"#ffffff22","align":"center","width":120,"height":120,"send":"optional tap message","children":[ {…} ]}',
    fields: [
      { name: 'children', type: 'list' },
      { name: 'bg', type: 'color' },
      { name: 'gradient', type: 'list' },
      { name: 'padding', type: 'num' },
      { name: 'radius', type: 'num' },
      { name: 'border', type: 'color' },
      { name: 'align', type: 'string' },
      { name: 'width', type: 'num' },
      { name: 'height', type: 'num' },
      { name: 'send', type: 'string' },
    ],
  }),
  makeSchema({
    type: 'row',
    category: 'primitives',
    childrenAllowed: true,
    example: '{"type":"row","align":"between","cross":"center","gap":8,"expand":false,"children":[ {…} ]}',
    fields: [
      { name: 'children', type: 'list' },
      { name: 'align', type: 'string' },
      { name: 'cross', type: 'string' },
      { name: 'gap', type: 'num' },
      { name: 'expand', type: 'bool' },
    ],
  }),
  makeSchema({
    type: 'column',
    category: 'primitives',
    childrenAllowed: true,
    example: '{"type":"column","cross":"start","gap":6,"children":[ {…} ]}',
    fields: [
      { name: 'children', type: 'list' },
      { name: 'cross', type: 'string' },
      { name: 'gap', type: 'num' },
    ],
  }),
  makeSchema({
    type: 'stack',
    category: 'primitives',
    childrenAllowed: true,
    example: '{"type":"stack","align":"bottomRight","children":[ {…} ]}',
    fields: [{ name: 'children', type: 'list' }, { name: 'align', type: 'string' }],
  }),
  makeSchema({
    type: 'text',
    category: 'primitives',
    example: '{"type":"text","text":"Title","size":20,"weight":"bold","color":"#ECEEF2","align":"center"}',
    fields: [
      { name: 'text', type: 'string', required: true },
      { name: 'size', type: 'num' },
      { name: 'weight', type: 'string' },
      { name: 'color', type: 'color' },
      { name: 'align', type: 'string' },
    ],
  }),
  makeSchema({
    type: 'icon',
    category: 'primitives',
    example: '{"type":"icon","icon":"rocket","size":28,"color":"#8B93FF"}',
    note: 'names: star heart check close info bolt spark fire sun moon cloud time location home search person chat play music image code rocket trophy gift cart money chart trending_up up down lock key flag bell book bulb leaf globe map food coffee link add edit delete …',
    fields: [
      { name: 'icon', type: 'string', required: true },
      { name: 'size', type: 'num' },
      { name: 'color', type: 'color' },
    ],
  }),
  makeSchema({
    type: 'button',
    category: 'primitives',
    example: '{"type":"button","label":"Play","send":"play","style":"primary|soft|ghost","icon":"play","color":"#8B93FF"}',
    note: 'add "set":{"key":"value"} to update local state client-side (e.g. switch a "when" view) with no message sent; "send" still asks the model',
    fields: [
      { name: 'label', type: 'string', required: true },
      { name: 'send', type: 'string' },
      { name: 'set', type: 'map' },
      { name: 'style', type: 'enum', enumValues: ['primary', 'soft', 'ghost'] },
      { name: 'icon', type: 'string' },
      { name: 'color', type: 'color' },
    ],
  }),
  makeSchema({
    type: 'spacer',
    category: 'primitives',
    example: '{"type":"spacer","size":12}',
    fields: [{ name: 'size', type: 'num' }],
  }),

  // ── Artifact ────────────────────────────────────────────────────────────
  makeSchema({
    type: 'artifact',
    category: 'artifact',
    example: '{"type":"artifact","kind":"code|markdown|table|text|html","title":"…","content":"…","language":"dart"}',
    note: 'kind "html" is passed to a host-provided sandbox — see SECURITY.md; use it for a fully custom interactive app/game/tool beyond the block types. Put the whole document in "content"',
    fields: [
      { name: 'kind', type: 'enum', enumValues: ['code', 'markdown', 'table', 'text', 'html'] },
      { name: 'title', type: 'string' },
      { name: 'content', type: 'string', required: true },
      { name: 'language', type: 'string' },
    ],
  }),

  // ── Adaptive directives (act on the app) ────────────────────────────────
  makeSchema({
    type: 'theme',
    category: 'directive',
    example: '{"type":"theme","accent":"#8B93FF"}',
    fields: [{ name: 'accent', type: 'color', required: true }],
  }),
  makeSchema({
    type: 'shortcuts',
    category: 'directive',
    example: '{"type":"shortcuts","items":["Plan my week","Summarize a doc"]}',
    fields: [{ name: 'items', type: 'list', required: true }],
  }),
]

/// Every valid type string (canonical + aliases).
export const genUiKnownTypes: Set<string> = new Set(
  genUiCatalog.flatMap(b => b.allTypes)
)

/// Lookup by canonical type or alias.
export function genUiSchemaFor(type: string, catalog: readonly GenUiBlockSchema[] = genUiCatalog): GenUiBlockSchema | undefined {
  for (const b of catalog) {
    if (b.type === type || (b.aliases ?? []).includes(type)) return b
  }
  return undefined
}

// ── Prompt catalogue generation ───────────────────────────────────────────

const _promptIntro =
  'You can render interactive UI in your reply by emitting a fenced code block with language `ui` containing ONE JSON object. You may include several `ui` blocks. Always also reply in normal prose; use UI sparingly, only when it genuinely helps. Put nothing but the JSON object inside a `ui` block.'

/// Per-category framing. bullet categories list each example on its own line
/// with a leading "- "; the rest are a single inline, semicolon-joined line.
const _categoryMeta: Record<GenUiCategory, { intro: string; bullet: boolean; outro?: string }> = {
  interactive: {
    intro: "Interactive (the user's tap/submit becomes their next message):",
    bullet: true,
  },
  display: { intro: 'Display only (no interaction):', bullet: true },
  moreInteractive: { intro: 'More interactive:', bullet: false },
  charts: { intro: 'Charts:', bullet: false },
  moreDisplay: { intro: 'More display:', bullet: false },
  miniTools: { intro: 'Local mini-tools (no round-trip):', bullet: false },
  layout: {
    intro: 'Layout (compose the above as children) — grid takes "columns":2:',
    bullet: false,
  },
  primitives: {
    intro: 'Freeform primitives — you are NOT limited to the components above; compose these to build ANY custom UI (cards, dashboards, game boards, scenes). Nest them freely; colors are hex; corners are auto-rounded:',
    bullet: true,
    outro: 'Prefer the high-level components when one fits; reach for primitives to invent something custom.',
  },
  artifact: { intro: 'Artifact (long code/doc opens a focused panel):', bullet: false },
  directive: {
    intro: 'Adaptive (acts on the app) — `theme` recolors this chat; `shortcuts` saves home-screen quick actions:',
    bullet: false,
  },
}

// Category iteration order must match Dart enum declaration order exactly.
const _categoryOrder: GenUiCategory[] = [
  'interactive',
  'display',
  'moreInteractive',
  'charts',
  'moreDisplay',
  'miniTools',
  'layout',
  'primitives',
  'artifact',
  'directive',
]

function _exampleLine(b: GenUiBlockSchema): string {
  return b.note == null ? b.example : `${b.example} (${b.note})`
}

/// Builds the model-facing UI catalogue from genUiCatalog. This replaces the
/// hand-maintained prose blob so the prompt can never drift from the renderers.
export function buildGenUiPromptCatalogue(catalog: readonly GenUiBlockSchema[] = genUiCatalog): string {
  let buf = _promptIntro
  for (const category of _categoryOrder) {
    const meta = _categoryMeta[category]
    const blocks = catalog.filter(b => b.category === category)
    if (blocks.length === 0) continue
    buf += `\n\n${meta.intro}`
    if (meta.bullet) {
      for (const b of blocks) {
        buf += `\n- ${_exampleLine(b)}`
      }
    } else {
      buf += ` ${blocks.map(_exampleLine).join('; ')}.`
    }
    if (meta.outro != null) buf += `\n${meta.outro}`
  }
  buf += `\n\n${_selfContainedNote}`
  return buf
}

/// Steers models to build interactive apps that run in place rather than firing
/// a chat turn for every tap.
const _selfContainedNote =
  'For an interactive app, make it self-contained: switch views with a button "set":{"key":"v"} + a "when" block, keep per-widget state with a stable "id", and use the offline mini-tools — so taps update the app in place. Use "send" (which messages you and starts a new reply) only when you genuinely need to respond; never for in-app navigation.'

// ── Validation ─────────────────────────────────────────────────────────────

/// Validates a parsed `ui` spec against the catalog. Tolerant by design: it
/// reports unknown types and missing required fields but does not throw, so
/// rendering can still degrade gracefully. Recurses into child blocks.
export function validateGenUiSpec(spec: unknown, path = '$', catalog: readonly GenUiBlockSchema[] = genUiCatalog): GenUiValidation {
  const issues: GenUiIssue[] = []
  _validateInto(spec, path, issues, catalog)
  return {
    issues,
    isValid: issues.length === 0,
    hasUnknownType: issues.some(i => i.message.startsWith('unknown type')),
  }
}

function _validateInto(node: unknown, path: string, issues: GenUiIssue[], catalog: readonly GenUiBlockSchema[]): void {
  if (node === null || typeof node !== 'object' || Array.isArray(node)) return
  const map = node as Record<string, unknown>
  const type = String(map['type'] ?? '')
  if (type === '') {
    issues.push({ path, message: 'missing "type"' })
    return
  }
  const schema = genUiSchemaFor(type, catalog)
  if (schema == null) {
    issues.push({ path, message: `unknown type "${type}"` })
    return
  }
  for (const f of schema.fields ?? []) {
    if (f.required && map[f.name] == null) {
      issues.push({ path: `${path}.${type}`, message: `missing required field "${f.name}"` })
    }
  }
  // Recurse ONLY into places that actually hold child blocks.
  const children = map['children']
  if (Array.isArray(children)) {
    for (let i = 0; i < children.length; i++) {
      _validateInto(children[i], `${path}.children[${i}]`, issues, catalog)
    }
  }
  const child = map['child']
  if (child !== null && typeof child === 'object' && !Array.isArray(child)) {
    _validateInto(child, `${path}.child`, issues, catalog)
  }
  // accordion.items[].content and tabs.tabs[].content are nested blocks.
  for (const key of ['items', 'tabs'] as const) {
    const list = map[key]
    if (Array.isArray(list)) {
      for (let i = 0; i < list.length; i++) {
        const item = list[i]
        if (item !== null && typeof item === 'object' && !Array.isArray(item)) {
          const itemMap = item as Record<string, unknown>
          if (itemMap['content'] !== null && typeof itemMap['content'] === 'object' && !Array.isArray(itemMap['content'])) {
            _validateInto(itemMap['content'], `${path}.${key}[${i}].content`, issues, catalog)
          }
        }
      }
    }
  }
}
