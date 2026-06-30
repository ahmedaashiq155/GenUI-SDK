import React from 'react'

export interface StatRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function StatRenderer({ spec, className, style }: StatRendererProps) {
  const title = spec.title as string | undefined
  const stats = ((spec.stats ?? spec.items) as Array<Record<string, unknown>> | undefined) ?? []

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
        gap: 'var(--ethereal-space-sm)',
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
          paddingBottom: 'var(--ethereal-space-sm)',
        }}>
          {title}
        </p>
      )}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--ethereal-space-lg)' }}>
        {stats.map((s, i) => (
          <div key={i} style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
            <span style={{
              fontSize: '1.75rem',
              fontWeight: 700,
              color: 'var(--ethereal-accent)',
              letterSpacing: '-0.03em',
              fontVariantNumeric: 'tabular-nums',
              lineHeight: 1,
            }}>
              {String(s.value ?? '')}
            </span>
            <span style={{
              fontSize: '0.6875rem',
              fontWeight: 600,
              color: 'var(--ethereal-text-tertiary)',
              letterSpacing: '0.06em',
              textTransform: 'uppercase',
            }}>
              {String(s.label ?? '')}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
