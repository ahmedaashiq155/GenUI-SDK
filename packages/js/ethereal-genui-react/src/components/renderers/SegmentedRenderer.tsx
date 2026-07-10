import React from 'react'
import { genUiOptions } from '@ethereal/genui-core'
import { usePersistedState } from '../../provider.js'
import { useGenUiInteractionEnabled } from '../GenUiInteraction.js'

export interface SegmentedRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function SegmentedRenderer({ spec, onSend, className, style }: SegmentedRendererProps) {
  const enabled = useGenUiInteractionEnabled()
  const options = genUiOptions(spec.options)
  const title = spec.title as string | undefined
  const id = spec.id as string | undefined

  const [selectedIndex, setSelectedIndex] = usePersistedState<number>(id, -1)

  const handleClick = (i: number) => {
    setSelectedIndex(i)
    onSend(options[i].value)
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
      <div
        role="radiogroup"
        aria-label={title}
        style={{
          display: 'flex',
          padding: '3px',
          borderRadius: 'var(--ethereal-radius-md)',
          backgroundColor: 'color-mix(in srgb, var(--ethereal-surface) 60%, transparent)',
          border: '1px solid var(--ethereal-hairline)',
        }}
      >
        {options.map((opt, i) => {
          const isSelected = i === selectedIndex
          return (
            <button
              key={opt.value}
              role="radio"
              aria-checked={isSelected}
              className="ethereal-pressable"
              onClick={() => handleClick(i)}
              disabled={!enabled}
              style={{
                flex: 1,
                padding: 'calc(var(--ethereal-space-sm) + 2px) var(--ethereal-space-sm)',
                borderRadius: 'calc(var(--ethereal-radius-md) - 2px)',
                border: 'none',
                cursor: enabled ? 'pointer' : 'not-allowed',
                opacity: enabled ? 1 : 0.55,
                fontWeight: 600,
                fontSize: '0.8125rem',
                textAlign: 'center',
                backgroundColor: isSelected ? 'var(--ethereal-accent)' : 'transparent',
                color: isSelected ? 'var(--ethereal-on-accent)' : 'var(--ethereal-text-secondary)',
                transition: 'background-color 0.15s ease, color 0.15s ease',
              }}
            >
              {opt.label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
