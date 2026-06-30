import React from 'react'

export interface CalloutRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

type CalloutStyle = 'info' | 'warn' | 'warning' | 'success'

function getColorVar(calloutStyle: string): string {
  switch (calloutStyle) {
    case 'warn':
    case 'warning':
      return 'var(--ethereal-danger)'
    case 'success':
      return 'var(--ethereal-celadon)'
    default:
      return 'var(--ethereal-accent)'
  }
}

function getIcon(calloutStyle: string): string {
  switch (calloutStyle) {
    case 'warn':
    case 'warning':
      return '⚠'
    case 'success':
      return '✓'
    default:
      return 'ℹ'
  }
}

export function CalloutRenderer({ spec, className, style }: CalloutRendererProps) {
  const calloutStyle = (spec.style as CalloutStyle | undefined) ?? 'info'
  const title = spec.title as string | undefined
  const text = spec.text as string | undefined
  const colorVar = getColorVar(calloutStyle)
  const icon = getIcon(calloutStyle)

  return (
    <div
      className={className}
      style={{
        width: '100%',
        padding: 'var(--ethereal-space-md)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: `1px solid color-mix(in srgb, ${colorVar} 22%, transparent)`,
        backgroundColor: `color-mix(in srgb, ${colorVar} 10%, transparent)`,
        display: 'flex',
        alignItems: 'flex-start',
        gap: 'var(--ethereal-space-sm)',
        ...style,
      }}
    >
      <span style={{
        color: colorVar,
        fontSize: '1rem',
        lineHeight: 1.4,
        flexShrink: 0,
      }}>
        {icon}
      </span>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
        {title && (
          <p style={{
            margin: 0,
            fontWeight: 600,
            color: 'var(--ethereal-text-primary)',
            fontSize: '0.9375rem',
          }}>
            {title}
          </p>
        )}
        {text && (
          <p style={{
            margin: 0,
            color: 'var(--ethereal-text-secondary)',
            fontSize: '0.875rem',
          }}>
            {text}
          </p>
        )}
      </div>
    </div>
  )
}
