import React from 'react'
import { usePersistedState } from '../../provider.js'

export interface RatingRendererProps {
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

export function RatingRenderer({ spec, onSend, className, style }: RatingRendererProps) {
  const label = spec.label as string | undefined ?? spec.title as string | undefined
  const max = toInt(spec.max, 5)
  const id = spec.id as string | undefined

  const [value, setValue] = usePersistedState<number>(id, 0)

  const handleClick = (i: number) => {
    setValue(i)
    onSend(`${i} out of ${max}`)
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
      {label && (
        <p style={{
          margin: 0,
          fontWeight: 600,
          color: 'var(--ethereal-text-primary)',
          fontSize: '0.9375rem',
          letterSpacing: '-0.01em',
          paddingBottom: 'var(--ethereal-space-sm)',
        }}>
          {label}
        </p>
      )}
      <div style={{ display: 'flex', gap: '4px' }}>
        {Array.from({ length: max }, (_, idx) => {
          const starNum = idx + 1
          const filled = starNum <= value
          return (
            <button
              key={starNum}
              onClick={() => handleClick(starNum)}
              style={{
                background: 'none',
                border: 'none',
                cursor: 'pointer',
                padding: '2px',
                color: 'var(--ethereal-accent)',
                fontSize: '1.75rem',
                lineHeight: 1,
              }}
            >
              {filled ? '★' : '☆'}
            </button>
          )
        })}
      </div>
    </div>
  )
}
