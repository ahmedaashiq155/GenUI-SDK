import React from 'react'

export interface TimelineRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function TimelineRenderer({ spec, className, style }: TimelineRendererProps) {
  const title = spec.title as string | undefined
  const items = ((spec.items ?? spec.steps) as Array<Record<string, unknown>> | undefined) ?? []

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
      {items.map((item, i) => {
        const isLast = i === items.length - 1
        const done = item.done === true
        return (
          <div key={i} style={{ display: 'flex', alignItems: 'stretch', gap: 'var(--ethereal-space-md)' }}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flexShrink: 0 }}>
              <div style={{
                width: 14,
                height: 14,
                borderRadius: '50%',
                backgroundColor: done
                  ? 'var(--ethereal-celadon)'
                  : 'color-mix(in srgb, var(--ethereal-accent) 40%, transparent)',
                flexShrink: 0,
              }} />
              {!isLast && (
                <div style={{
                  width: 2,
                  flex: 1,
                  minHeight: 'var(--ethereal-space-lg)',
                  backgroundColor: 'var(--ethereal-hairline)',
                  marginTop: 2,
                }} />
              )}
            </div>
            <div style={{
              display: 'flex',
              flexDirection: 'column',
              gap: '2px',
              paddingBottom: isLast ? 0 : 'var(--ethereal-space-md)',
              flex: 1,
            }}>
              <span style={{
                fontWeight: 600,
                color: 'var(--ethereal-text-primary)',
                fontSize: '0.9375rem',
              }}>
                {String(item.title ?? '')}
              </span>
              {item.subtitle != null && (
                <span style={{
                  color: 'var(--ethereal-text-tertiary)',
                  fontSize: '0.8125rem',
                }}>
                  {String(item.subtitle)}
                </span>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
