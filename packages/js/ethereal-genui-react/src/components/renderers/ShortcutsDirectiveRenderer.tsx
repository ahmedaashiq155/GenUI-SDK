import React, { useState } from 'react'
import { useOptionalGenUiActions } from '../../provider.js'
import { Pressable } from '../Pressable.js'

export interface ShortcutsDirectiveRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

/**
 * {"type":"shortcuts","items":[…]} — offers quick-actions inline and, after
 * an explicit user tap, saves them via the host's setShortcuts callback.
 *
 * Persisting is gated on a user tap: saved shortcuts replay their text as a
 * user message later, so letting a rendered spec store them silently would
 * give an injected prompt a durable, cross-session foothold.
 */
export function ShortcutsDirectiveRenderer({ spec, onSend, className, style }: ShortcutsDirectiveRendererProps) {
  const actions = useOptionalGenUiActions()
  const rawItems = Array.isArray(spec.items) ? spec.items as unknown[] : []
  const items = rawItems
    .filter((s): s is string => typeof s === 'string' && s.trim().length > 0)
  const [saved, setSaved] = useState(false)
  const canSave = items.length > 0 && Boolean(actions?.setShortcuts) && actions?.enabled !== false && !saved

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
        <span aria-hidden="true" style={{ fontSize: 14 }}>⚡</span>
        <span style={{ flex: 1, color: 'var(--ethereal-text-secondary)', fontSize: '0.875rem' }}>
          {saved ? 'Saved to your shortcuts' : 'Suggested shortcuts'}
        </span>
        {saved ? (
          <span aria-hidden="true" style={{ color: 'var(--ethereal-accent)', fontSize: '1rem' }}>✓</span>
        ) : canSave ? (
          <Pressable
            onPress={() => {
              setSaved(true)
              actions?.setShortcuts?.(items)
            }}
            style={{
              padding: '4px 12px',
              borderRadius: 'var(--ethereal-radius-pill)',
              background: 'color-mix(in srgb, var(--ethereal-accent) 14%, transparent)',
              color: 'var(--ethereal-accent)',
              fontSize: '0.875rem',
              fontWeight: 500,
            }}
          >
            Save
          </Pressable>
        ) : null}
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
            className="ethereal-pressable"
            style={{
              padding: '4px 12px',
              borderRadius: 'var(--ethereal-radius-pill)',
              background: 'color-mix(in srgb, var(--ethereal-accent) 14%, transparent)',
              color: 'var(--ethereal-accent)',
              border: 'none',
              fontSize: '0.875rem',
              cursor: 'pointer',
            }}
          >
            {s}
          </button>
        ))}
      </div>
    </div>
  )
}
