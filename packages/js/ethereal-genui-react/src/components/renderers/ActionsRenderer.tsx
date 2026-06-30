import React from 'react'

export interface ActionsRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ActionsRenderer({ spec, onSend, className, style }: ActionsRendererProps) {
  const title = spec.title as string | undefined
  const actions = (Array.isArray(spec.actions) ? spec.actions : []) as Array<Record<string, unknown>>

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
          letterSpacing: '-0.01em',
          paddingBottom: 'var(--ethereal-space-sm)',
        }}>
          {title}
        </p>
      )}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--ethereal-space-sm)' }}>
        {actions.map((a, idx) => {
          const label = String(a.label ?? '')
          const send = String(a.send ?? a.label ?? '')
          const primary = a.primary === true
          return (
            <button
              key={idx}
              onClick={() => onSend(send)}
              style={{
                padding: '6px calc(var(--ethereal-space-md) + 2px)',
                borderRadius: 'var(--ethereal-radius-pill)',
                border: 'none',
                cursor: 'pointer',
                fontWeight: 500,
                fontSize: '0.875rem',
                backgroundColor: primary
                  ? 'var(--ethereal-accent)'
                  : 'color-mix(in srgb, var(--ethereal-accent) 10%, transparent)',
                color: primary ? 'var(--ethereal-on-accent, #fff)' : 'var(--ethereal-accent)',
                transition: 'opacity 0.1s ease',
              }}
              onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
              onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
            >
              {label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
