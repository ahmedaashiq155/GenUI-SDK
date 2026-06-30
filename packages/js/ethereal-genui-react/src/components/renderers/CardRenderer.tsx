import React from 'react'

export interface CardRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function CardRenderer({ spec, className, style }: CardRendererProps) {
  const title = spec.title as string | undefined
  const subtitle = spec.subtitle as string | undefined
  const items = (spec.items as Array<Record<string, unknown>> | undefined) ?? []

  return (
    <div
      className={className}
      style={{
        width: '100%',
        padding: 'var(--ethereal-space-lg)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--ethereal-space-xs, 4px)',
        ...style,
      }}
    >
      {title && (
        <p style={{
          margin: 0,
          fontWeight: 600,
          color: 'var(--ethereal-text-primary)',
          fontSize: '0.9375rem',
          letterSpacing: '-0.012em',
        }}>
          {title}
        </p>
      )}
      {subtitle && (
        <p style={{
          margin: 0,
          color: 'var(--ethereal-text-secondary)',
          fontSize: '0.875rem',
        }}>
          {subtitle}
        </p>
      )}
      {items.length > 0 && (
        <div style={{ marginTop: 'var(--ethereal-space-md)', display: 'flex', flexDirection: 'column', gap: 'var(--ethereal-space-sm)' }}>
          {items.map((item, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 'var(--ethereal-space-sm)' }}>
              <span style={{
                width: 110,
                flexShrink: 0,
                color: 'var(--ethereal-text-tertiary)',
                fontSize: '0.875rem',
              }}>
                {String(item.label ?? '')}
              </span>
              <span style={{
                flex: 1,
                color: 'var(--ethereal-text-primary)',
                fontWeight: 500,
                fontSize: '0.9375rem',
                fontVariantNumeric: 'tabular-nums',
              }}>
                {String(item.value ?? '')}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
