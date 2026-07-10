import React from 'react'
import { genUiOptions } from '@ethereal/genui-core'
import { usePersistedState } from '../../provider.js'
import { useGenUiInteractionEnabled } from '../GenUiInteraction.js'

export interface MultiSelectRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function MultiSelectRenderer({ spec, onSend, className, style }: MultiSelectRendererProps) {
  const enabled = useGenUiInteractionEnabled()
  const options = genUiOptions(spec.options)
  const title = spec.title as string | undefined
  const submitLabel = String(spec.submitLabel ?? 'Submit')
  const id = spec.id as string | undefined

  const [selected, setSelected] = usePersistedState<string[]>(id, [])
  const selectedSet = new Set(selected)

  const toggle = (value: string) => {
    const next = selectedSet.has(value)
      ? selected.filter(v => v !== value)
      : [...selected, value]
    setSelected(next)
  }

  const handleSubmit = () => {
    if (selected.length > 0) {
      onSend(Array.from(selected).join(', '))
    }
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
        {options.map((opt) => {
          const isSel = selectedSet.has(opt.value)
          return (
            <button
              key={opt.value}
              onClick={() => toggle(opt.value)}
              disabled={!enabled}
              style={{
                padding: '6px calc(var(--ethereal-space-md) + 2px)',
                borderRadius: 'var(--ethereal-radius-pill)',
                border: 'none',
                cursor: enabled ? 'pointer' : 'not-allowed',
                opacity: enabled ? 1 : 0.55,
                fontWeight: 500,
                fontSize: '0.875rem',
                backgroundColor: isSel
                  ? 'var(--ethereal-accent)'
                  : 'color-mix(in srgb, var(--ethereal-accent) 10%, transparent)',
                color: isSel ? 'var(--ethereal-on-accent)' : 'var(--ethereal-accent)',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
                transition: 'opacity 0.1s ease',
              }}
              onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
              onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
            >
              {isSel && <span>✓</span>}
              {opt.label}
            </button>
          )
        })}
      </div>
      <button
        onClick={handleSubmit}
        disabled={!enabled || selected.length === 0}
        style={{
          padding: '8px var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          border: 'none',
          cursor: enabled && selected.length > 0 ? 'pointer' : 'not-allowed',
          fontWeight: 500,
          fontSize: '0.875rem',
          backgroundColor: selected.length > 0
            ? 'var(--ethereal-accent)'
            : 'color-mix(in srgb, var(--ethereal-accent) 20%, transparent)',
          color: selected.length > 0 ? 'var(--ethereal-on-accent)' : 'var(--ethereal-text-tertiary)',
          alignSelf: 'flex-start',
          opacity: enabled && selected.length > 0 ? 1 : 0.5,
          transition: 'opacity 0.1s ease',
          marginTop: 'var(--ethereal-space-sm)',
        }}
      >
        {submitLabel}
      </button>
    </div>
  )
}
