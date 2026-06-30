/// A normalized choice/option. The model may emit a plain string ("Daily") OR
/// an object ({"label":"Daily","value":"daily"}, {"label":"x","checked":true,
/// "send":"y"}). Renderers must never show the raw map — always read label
/// for display and value for the action.

export interface GenUiOption {
  readonly label: string
  readonly value: string
  readonly checked: boolean
}

/// Normalize a model-supplied list of options/items into GenUiOptions,
/// tolerating both string and object forms.
export function genUiOptions(raw: unknown): GenUiOption[] {
  if (!Array.isArray(raw)) return []
  const out: GenUiOption[] = []
  for (const e of raw) {
    if (e !== null && typeof e === 'object' && !Array.isArray(e)) {
      const map = e as Record<string, unknown>
      const label = String(
        map['label'] ?? map['text'] ?? map['title'] ?? map['name'] ?? map['value'] ?? ''
      )
      const value = String(map['value'] ?? map['send'] ?? map['label'] ?? label)
      out.push({ label, value, checked: map['checked'] === true })
    } else {
      const s = String(e)
      out.push({ label: s, value: s, checked: false })
    }
  }
  return out
}
