import React, { useEffect } from 'react'
import { genUiOptions } from '@ethereal/genui-core'
import { usePersistedState } from '../../provider.js'
import { Pressable } from '../Pressable.js'
import { useGenUiInteractionEnabled } from '../GenUiInteraction.js'

export interface ChecklistRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ChecklistRenderer({ spec, onSend, className, style }: ChecklistRendererProps) {
  const enabled = useGenUiInteractionEnabled()
  const options = genUiOptions(spec.items ?? spec.options)
  const title = spec.title as string | undefined
  const submitLabel = String(spec.submitLabel ?? 'Done')
  const id = spec.id as string | undefined

  const initialChecked = options
    .filter(o => o.checked)
    .map(o => o.value)

  const [storedChecked, setStoredChecked] = usePersistedState<Array<string | number>>(id, initialChecked)
  const availableValues = new Set(options.map(option => option.value))
  const checkedValues = storedChecked
    .map(value => typeof value === 'number' ? options[value]?.value : String(value))
    .filter((value): value is string => value != null && availableValues.has(value))
  const checkedSet = new Set(checkedValues)

  useEffect(() => {
    if (storedChecked.length !== checkedValues.length ||
        storedChecked.some((value, index) => value !== checkedValues[index])) {
      setStoredChecked(checkedValues)
    }
  }, [checkedValues.join('\u0000'), setStoredChecked, storedChecked])

  const toggle = (value: string) => {
    const next = checkedSet.has(value)
      ? checkedValues.filter(x => x !== value)
      : [...checkedValues, value]
    setStoredChecked(next)
  }

  const handleSubmit = () => {
    if (checkedValues.length > 0) {
      const labels = options
        .filter(option => checkedSet.has(option.value))
        .map(option => option.label)
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
        const isChecked = checkedSet.has(opt.value)
        return (
          <Pressable
            key={opt.value}
            role="checkbox"
            aria-checked={isChecked}
            onPress={() => toggle(opt.value)}
            disabled={!enabled}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 'var(--ethereal-space-sm)',
              padding: '5px 0',
              width: '100%',
            }}
          >
            <span aria-hidden="true" style={{
              fontSize: '1.25rem',
              color: isChecked ? 'var(--ethereal-accent)' : 'var(--ethereal-text-tertiary)',
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
          </Pressable>
        )
      })}
      <button
        onClick={handleSubmit}
        disabled={!enabled || checkedValues.length === 0}
        style={{
          padding: '8px var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          border: 'none',
          cursor: enabled && checkedValues.length > 0 ? 'pointer' : 'not-allowed',
          fontWeight: 500,
          fontSize: '0.875rem',
          backgroundColor: checkedValues.length > 0
            ? 'var(--ethereal-accent)'
            : 'color-mix(in srgb, var(--ethereal-accent) 20%, transparent)',
          color: checkedValues.length > 0 ? 'var(--ethereal-on-accent)' : 'var(--ethereal-text-tertiary)',
          alignSelf: 'flex-start',
          opacity: enabled && checkedValues.length > 0 ? 1 : 0.5,
          marginTop: 'var(--ethereal-space-sm)',
          transition: 'opacity 0.1s ease',
        }}
      >
        {submitLabel}
      </button>
    </div>
  )
}
