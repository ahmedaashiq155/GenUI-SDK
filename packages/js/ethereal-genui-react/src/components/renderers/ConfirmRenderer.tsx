import React from 'react'

export interface ConfirmRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ConfirmRenderer({ spec, onSend, className, style }: ConfirmRendererProps) {
  const prompt = String(spec.prompt ?? spec.title ?? 'Confirm?')
  const confirmLabel = String(spec.confirmLabel ?? 'Yes')
  const cancelLabel = String(spec.cancelLabel ?? 'No')

  const pillBase: React.CSSProperties = {
    padding: '6px calc(var(--ethereal-space-md) + 2px)',
    borderRadius: 'var(--ethereal-radius-pill)',
    border: 'none',
    cursor: 'pointer',
    fontWeight: 500,
    fontSize: '0.875rem',
    transition: 'opacity 0.1s ease',
  }

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
        gap: 'var(--ethereal-space-md)',
        ...style,
      }}
    >
      <p style={{
        margin: 0,
        color: 'var(--ethereal-text-primary)',
        fontSize: '1rem',
      }}>
        {prompt}
      </p>
      <div style={{ display: 'flex', gap: 'var(--ethereal-space-sm)' }}>
        <button
          onClick={() => onSend(confirmLabel)}
          style={{
            ...pillBase,
            backgroundColor: 'var(--ethereal-accent)',
            color: 'var(--ethereal-on-accent)',
          }}
          onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
          onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
        >
          {confirmLabel}
        </button>
        <button
          onClick={() => onSend(cancelLabel)}
          style={{
            ...pillBase,
            backgroundColor: 'color-mix(in srgb, var(--ethereal-accent) 10%, transparent)',
            color: 'var(--ethereal-accent)',
          }}
          onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
          onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
        >
          {cancelLabel}
        </button>
      </div>
    </div>
  )
}
