import React from 'react'

export interface BadgesRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function BadgesRenderer({ spec, className, style }: BadgesRendererProps) {
  const items = (spec.items as unknown[] | undefined ?? []).map(String)

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
        flexWrap: 'wrap',
        gap: 'var(--ethereal-space-sm)',
        ...style,
      }}
    >
      {items.map((badge, i) => (
        <span
          key={i}
          style={{
            padding: '5px calc(var(--ethereal-space-md))',
            borderRadius: 'var(--ethereal-radius-pill)',
            backgroundColor: 'color-mix(in srgb, var(--ethereal-accent) 14%, transparent)',
            color: 'var(--ethereal-accent)',
            fontWeight: 600,
            fontSize: '0.8125rem',
          }}
        >
          {badge}
        </span>
      ))}
    </div>
  )
}
