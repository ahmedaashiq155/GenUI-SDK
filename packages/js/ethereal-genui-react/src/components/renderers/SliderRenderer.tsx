import React from 'react'
import { usePersistedState } from '../../provider.js'

export interface SliderRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function toNum(v: unknown, fallback: number): number {
  if (typeof v === 'number') return v
  if (typeof v === 'string') {
    const parsed = parseFloat(v)
    if (!isNaN(parsed)) return parsed
  }
  return fallback
}

export function SliderRenderer({ spec, onSend, className, style }: SliderRendererProps) {
  const label = spec.label as string | undefined ?? spec.title as string | undefined
  const submitLabel = String(spec.submitLabel ?? 'Submit')
  const id = spec.id as string | undefined
  const min = toNum(spec.min, 0)
  const max = toNum(spec.max, 100)
  const step = toNum(spec.step, 1)
  const unit = String(spec.unit ?? '')

  const [value, setValue] = usePersistedState<number>(id, toNum(spec.value, min))
  const display = Number.isInteger(value) ? String(value) : value.toFixed(1)

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
          <p style={{
            margin: 0,
            fontWeight: 600,
            color: 'var(--ethereal-text-primary)',
            fontSize: '0.9375rem',
            letterSpacing: '-0.01em',
            flex: 1,
          }}>
            {label}
          </p>
        )}
        <span style={{
          fontWeight: 600,
          fontSize: '1rem',
          color: 'var(--ethereal-accent)',
        }}>
          {display}{unit}
        </span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => setValue(parseFloat(e.target.value))}
        style={{
          width: '100%',
          accentColor: 'var(--ethereal-accent)',
        }}
      />
      <button
        onClick={() => onSend(`${display}${unit}`)}
        style={{
          padding: '8px var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          border: 'none',
          cursor: 'pointer',
          fontWeight: 500,
          fontSize: '0.875rem',
          backgroundColor: 'var(--ethereal-accent)',
          color: 'var(--ethereal-on-accent, #fff)',
          alignSelf: 'flex-start',
          transition: 'opacity 0.1s ease',
        }}
        onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
        onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
      >
        {submitLabel}
      </button>
    </div>
  )
}
