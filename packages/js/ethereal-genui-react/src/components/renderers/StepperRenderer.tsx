import React, { useEffect } from 'react'
import { usePersistedState } from '../../provider.js'
import { useGenUiInteractionEnabled } from '../GenUiInteraction.js'

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
  const enabled = useGenUiInteractionEnabled()
  const label = String(spec.label ?? spec.title ?? '')
  const unit = String(spec.unit ?? '')
  const id = spec.id as string | undefined
  const rawMin = toInt(spec.min, 0)
  const rawMax = toInt(spec.max, 99)
  const min = Math.min(rawMin, rawMax)
  const max = Math.max(rawMin, rawMax)
  const step = Math.max(Math.abs(toInt(spec.step, 1)), 1)
  const specValue = Math.min(Math.max(toInt(spec.value, min), min), max)

  const [value, setValue] = usePersistedState<number>(id, specValue)

  useEffect(() => {
    setValue(Math.min(Math.max(specValue, min), max))
  }, [max, min, setValue, specValue])

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
        onClick={() => value - step >= min && setValue(Math.max(value - step, min))}
        disabled={!enabled || value - step < min}
        style={btnStyle(!enabled || value - step < min)}
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
        onClick={() => value + step <= max && setValue(Math.min(value + step, max))}
        disabled={!enabled || value + step > max}
        style={btnStyle(!enabled || value + step > max)}
      >
        +
      </button>
      <button
        onClick={() => onSend(label ? `${label}: ${value}${unit}` : `${value}${unit}`)}
        disabled={!enabled}
        style={{
          background: 'none',
          border: 'none',
          cursor: enabled ? 'pointer' : 'not-allowed',
          opacity: enabled ? 1 : 0.55,
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
