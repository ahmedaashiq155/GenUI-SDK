import React from 'react'
import { usePersistedState } from '../../provider.js'

export interface StepperRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function toInt(v: unknown, fallback: number): number {
  if (typeof v === 'number') return Math.round(v)
  if (typeof v === 'string') {
    const parsed = parseInt(v, 10)
    if (!isNaN(parsed)) return parsed
  }
  return fallback
}

export function StepperRenderer({ spec, onSend, className, style }: StepperRendererProps) {
  const label = String(spec.label ?? spec.title ?? '')
  const unit = String(spec.unit ?? '')
  const id = spec.id as string | undefined
  const min = toInt(spec.min, 0)
  const max = toInt(spec.max, 99)
  const step = toInt(spec.step, 1)

  const [value, setValue] = usePersistedState<number>(id, toInt(spec.value, min))

  const btnStyle = (disabled: boolean): React.CSSProperties => ({
    width: '38px',
    height: '38px',
    borderRadius: 'var(--ethereal-radius-pill)',
    border: 'none',
    cursor: disabled ? 'not-allowed' : 'pointer',
    backgroundColor: disabled
      ? 'color-mix(in srgb, var(--ethereal-accent) 8%, transparent)'
      : 'color-mix(in srgb, var(--ethereal-accent) 16%, transparent)',
    color: disabled ? 'color-mix(in srgb, var(--ethereal-accent) 40%, transparent)' : 'var(--ethereal-accent)',
    fontWeight: 700,
    fontSize: '1.25rem',
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    transition: 'opacity 0.1s ease',
    opacity: disabled ? 0.5 : 1,
  })

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
        alignItems: 'center',
        gap: 'var(--ethereal-space-sm)',
        ...style,
      }}
    >
      {label && (
        <span style={{
          flex: 1,
          fontWeight: 500,
          fontSize: '1rem',
          color: 'var(--ethereal-text-primary)',
        }}>
          {label}
        </span>
      )}
      <button
        onClick={() => value > min && setValue(value - step)}
        disabled={value <= min}
        style={btnStyle(value <= min)}
      >
        −
      </button>
      <span style={{
        minWidth: '2.5rem',
        textAlign: 'center',
        fontWeight: 600,
        fontSize: '1rem',
        color: 'var(--ethereal-text-primary)',
      }}>
        {value}{unit}
      </span>
      <button
        onClick={() => value < max && setValue(value + step)}
        disabled={value >= max}
        style={btnStyle(value >= max)}
      >
        +
      </button>
      <button
        onClick={() => onSend(label ? `${label}: ${value}${unit}` : `${value}${unit}`)}
        style={{
          background: 'none',
          border: 'none',
          cursor: 'pointer',
          color: 'var(--ethereal-accent)',
          fontSize: '1.25rem',
          padding: '4px',
          marginLeft: 'var(--ethereal-space-sm)',
          display: 'inline-flex',
          alignItems: 'center',
        }}
        title="Send"
      >
        →
      </button>
    </div>
  )
}
