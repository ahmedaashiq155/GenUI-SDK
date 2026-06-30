import React from 'react'
import { genUiOptions } from '@ethereal/genui-core'

export interface SuggestionsRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function SuggestionsRenderer({ spec, onSend, className, style }: SuggestionsRendererProps) {
  const options = genUiOptions(spec.options ?? spec.suggestions ?? spec.prompts)
  if (options.length === 0) return null

  return (
    <div
      className={className}
      style={{
        display: 'flex',
        flexWrap: 'wrap',
        gap: 'var(--ethereal-space-sm)',
        padding: 'var(--ethereal-space-sm) 0',
        ...style,
      }}
    >
      {options.map((opt) => (
        <button
          key={opt.value}
          onClick={() => onSend(opt.value)}
          style={{
            padding: '4px var(--ethereal-space-md)',
            borderRadius: 'var(--ethereal-radius-pill)',
            border: '1px solid color-mix(in srgb, var(--ethereal-accent) 20%, transparent)',
            cursor: 'pointer',
            fontWeight: 400,
            fontSize: '0.8125rem',
            backgroundColor: 'color-mix(in srgb, var(--ethereal-accent) 6%, transparent)',
            color: 'var(--ethereal-accent)',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '4px',
            transition: 'opacity 0.1s ease',
          }}
          onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
          onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
        >
          <span style={{ fontSize: '0.75rem' }}>↗</span>
          {opt.label}
        </button>
      ))}
    </div>
  )
}
