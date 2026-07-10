import React from 'react'
import { genUiOptions } from '@ethereal/genui-core'
import { useGenUiInteractionEnabled } from '../GenUiInteraction.js'

export interface ChoicesRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ChoicesRenderer({ spec, onSend, className, style }: ChoicesRendererProps) {
  const enabled = useGenUiInteractionEnabled()
  const options = genUiOptions(spec.options)
  const title = spec.title as string | undefined

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
        {options.map((opt) => (
          <button
            key={opt.value}
            onClick={() => onSend(opt.value)}
            disabled={!enabled}
            style={{
              padding: '6px calc(var(--ethereal-space-md) + 2px)',
              borderRadius: 'var(--ethereal-radius-pill)',
              border: 'none',
              cursor: enabled ? 'pointer' : 'not-allowed',
              opacity: enabled ? 1 : 0.55,
              fontWeight: 500,
              fontSize: '0.875rem',
              backgroundColor: 'color-mix(in srgb, var(--ethereal-accent) 10%, transparent)',
              color: 'var(--ethereal-accent)',
              transition: 'opacity 0.1s ease',
            }}
            onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
            onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
          >
            {opt.label}
          </button>
        ))}
      </div>
    </div>
  )
}
