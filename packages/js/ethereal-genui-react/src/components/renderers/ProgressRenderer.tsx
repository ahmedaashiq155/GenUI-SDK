import React from 'react'

export interface ProgressRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ProgressRenderer({ spec, className, style }: ProgressRendererProps) {
  const label = spec.label as string | undefined

  let value: number
  if (typeof spec.percent === 'number') {
    value = spec.percent / 100
  } else if (typeof spec.value === 'number') {
    value = spec.value
  } else {
    value = 0
  }
  value = Math.min(1, Math.max(0, value))
  const pct = Math.round(value * 100)

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
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        {label && (
          <span style={{
            color: 'var(--ethereal-text-primary)',
            fontSize: '0.9375rem',
          }}>
            {label}
          </span>
        )}
        <span style={{
          color: 'var(--ethereal-accent)',
          fontSize: '0.875rem',
          fontWeight: 500,
          marginLeft: 'auto',
        }}>
          {pct}%
        </span>
      </div>
      <div style={{
        width: '100%',
        height: 8,
        borderRadius: 99,
        backgroundColor: 'color-mix(in srgb, var(--ethereal-accent) 14%, transparent)',
        overflow: 'hidden',
      }}>
        <div style={{
          width: `${pct}%`,
          height: '100%',
          borderRadius: 99,
          backgroundColor: 'var(--ethereal-accent)',
          transition: 'width 0.3s ease',
        }} />
      </div>
    </div>
  )
}
