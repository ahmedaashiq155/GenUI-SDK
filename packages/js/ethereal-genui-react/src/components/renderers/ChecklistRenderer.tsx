import React from 'react'
import { genUiOptions } from '@ethereal/genui-core'
import { usePersistedState } from '../../provider.js'

export interface ChecklistRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ChecklistRenderer({ spec, onSend, className, style }: ChecklistRendererProps) {
  const options = genUiOptions(spec.items ?? spec.options)
  const title = spec.title as string | undefined
  const submitLabel = String(spec.submitLabel ?? 'Done')
  const id = spec.id as string | undefined

  const initialChecked = options
    .map((o, i) => (o.checked ? i : -1))
    .filter(i => i >= 0)

  const [checkedIndices, setCheckedIndices] = usePersistedState<number[]>(id, initialChecked)
  const checkedSet = new Set(checkedIndices)

  const toggle = (i: number) => {
    const next = checkedSet.has(i)
      ? checkedIndices.filter(x => x !== i)
      : [...checkedIndices, i]
    setCheckedIndices(next)
  }

  const handleSubmit = () => {
    if (checkedIndices.length > 0) {
      const labels = checkedIndices.map(i => options[i]?.label ?? '').filter(Boolean)
      onSend(labels.join(', '))
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
      {options.map((opt, i) => {
        const isChecked = checkedSet.has(i)
        return (
          <div
            key={opt.value}
            onClick={() => toggle(i)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--ethereal-space-sm)',
              cursor: 'pointer',
              padding: '5px 0',
            }}
          >
            <span style={{
              fontSize: '1.25rem',
              color: isChecked ? 'var(--ethereal-accent)' : 'var(--ethereal-text-tertiary, #aaa)',
              lineHeight: 1,
            }}>
              {isChecked ? '✓' : '○'}
            </span>
            <span style={{
              color: 'var(--ethereal-text-primary)',
              textDecoration: isChecked ? 'line-through' : 'none',
              fontSize: '0.9375rem',
            }}>
              {opt.label}
            </span>
          </div>
        )
      })}
      <button
        onClick={handleSubmit}
        disabled={checkedIndices.length === 0}
        style={{
          padding: '8px var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          border: 'none',
          cursor: checkedIndices.length > 0 ? 'pointer' : 'not-allowed',
          fontWeight: 500,
          fontSize: '0.875rem',
          backgroundColor: checkedIndices.length > 0
            ? 'var(--ethereal-accent)'
            : 'color-mix(in srgb, var(--ethereal-accent) 20%, transparent)',
          color: checkedIndices.length > 0 ? 'var(--ethereal-on-accent, #fff)' : 'var(--ethereal-text-tertiary, #aaa)',
          alignSelf: 'flex-start',
          opacity: checkedIndices.length > 0 ? 1 : 0.5,
          marginTop: 'var(--ethereal-space-sm)',
          transition: 'opacity 0.1s ease',
        }}
      >
        {submitLabel}
      </button>
    </div>
  )
}
