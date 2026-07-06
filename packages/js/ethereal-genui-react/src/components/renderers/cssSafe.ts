/**
 * Guards spec-supplied color strings before they reach an inline `style`.
 *
 * The spec is untrusted model output; a raw value flowing into a CSS property
 * (directly or interpolated into `color-mix(…)`/`linear-gradient(…)`) can smuggle
 * `url(https://evil/pixel)` (a remote-fetch/tracking beacon) or `var(--…)` probes.
 * Only a plain hex / rgb(a) / hsl(a) / single named color is allowed through.
 */
const CSS_COLOR = /^#[0-9a-fA-F]{3,8}$|^(?:rgb|hsl)a?\([\d\s.,%/]+\)$|^[a-zA-Z]{1,20}$/

export function safeColor(v: unknown): string | undefined {
  return typeof v === 'string' && CSS_COLOR.test(v.trim()) ? v.trim() : undefined
}
