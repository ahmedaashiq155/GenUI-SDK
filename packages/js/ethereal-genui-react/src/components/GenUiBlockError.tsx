import React from 'react'

export interface GenUiBlockErrorProps {
  className?: string
  style?: React.CSSProperties
}

/**
 * Third state alongside GenUiPlaceholder's two: the fence closed but content
 * is still unparseable even after tolerant repair. Distinct copy from
 * "Preparing…" so genuinely malformed output doesn't read as "still loading."
 */
export function GenUiBlockError({ className, style }: GenUiBlockErrorProps) {
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
        border: '1px solid color-mix(in srgb, var(--ethereal-danger) 30%, transparent)',
        backgroundColor: 'color-mix(in srgb, var(--ethereal-surface) 50%, transparent)',
        color: 'var(--ethereal-danger)',
        fontSize: '13px',
        ...style,
      }}
    >
      <span aria-hidden="true">⚠</span>
      <span>Couldn&apos;t render this</span>
    </div>
  )
}
