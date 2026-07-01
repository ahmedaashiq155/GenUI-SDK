import React from 'react'

export interface GenUiPlaceholderProps {
  type?: string   // if provided and non-empty -> "Unsupported block: {type}"
  className?: string
  style?: React.CSSProperties
}

/**
 * Calm fallback, mirrors Dart's genUiPlaceholder(context, {type}):
 *  - no type -> "Preparing…" (still streaming, not parseable yet)
 *  - type given -> "Unsupported block: {type}" (fully parsed, unknown type)
 */
export function GenUiPlaceholder({ type, className, style }: GenUiPlaceholderProps) {
  const label = type ? `Unsupported block: ${type}` : 'Preparing…'
  return (
    <div
      className={className}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 'var(--ethereal-space-sm)',
        margin: 'var(--ethereal-space-sm) 0',
        padding: 'var(--ethereal-space-sm) var(--ethereal-space-md)',
        borderRadius: 'var(--ethereal-radius-md)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'color-mix(in srgb, var(--ethereal-surface) 50%, transparent)',
        color: 'var(--ethereal-text-tertiary)',
        fontSize: '13px',
        ...style,
      }}
    >
      <span aria-hidden="true">▢</span>
      <span>{label}</span>
    </div>
  )
}
