import React, { useEffect } from 'react'
import { useOptionalGenUiActions } from '../../provider.js'

export interface ShortcutsDirectiveRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ShortcutsDirectiveRenderer({ spec, onSend, className, style }: ShortcutsDirectiveRendererProps) {
  const actions = useOptionalGenUiActions()
  const rawItems = Array.isArray(spec.items) ? spec.items as unknown[] : []
  const items = rawItems
    .filter((s): s is string => typeof s === 'string' && s.trim().length > 0)

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    actions?.setShortcuts?.(items)
  }, [])

  if (items.length === 0) return null

  return (
    <div
      className={className}
      style={{
        padding: 'var(--ethereal-space-md)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--ethereal-space-sm)',
        ...style,
      }}
    >
      {/* Header */}
      <div style={{
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 'var(--ethereal-space-xs, 4px)',
      }}>
        <span style={{ fontSize: 14 }}>⚡</span>
        <span style={{ color: 'var(--ethereal-text-secondary)', fontSize: '0.875rem' }}>
          Saved to your shortcuts
        </span>
      </div>
      {/* Pills */}
      <div style={{
        display: 'flex',
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 'var(--ethereal-space-sm)',
      }}>
        {items.map((s, i) => (
          <button
            key={i}
            onClick={() => onSend?.(s)}
            style={{
              padding: '4px 12px',
              borderRadius: 'var(--ethereal-radius-pill)',
              background: 'color-mix(in srgb, var(--ethereal-accent) 14%, transparent)',
              color: 'var(--ethereal-accent)',
              border: 'none',
              fontSize: '0.875rem',
              cursor: 'pointer',
              outline: 'none',
            }}
          >
            {s}
          </button>
        ))}
      </div>
    </div>
  )
}
