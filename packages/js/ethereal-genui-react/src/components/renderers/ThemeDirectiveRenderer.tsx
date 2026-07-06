import React, { useState } from 'react'
import { useOptionalGenUiActions } from '../../provider.js'
import { Pressable } from '../Pressable.js'

export interface ThemeDirectiveRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

const HEX_REGEX = /^#[0-9a-fA-F]{3,8}$/

/**
 * {"type":"theme","accent":"#8B93FF"} — offers to recolor this conversation.
 *
 * The accent is only applied after an explicit user tap. Directives must
 * never fire host side effects just by being rendered: the spec is untrusted
 * model output, and silently restyling the app on render is a prompt-
 * injection foothold.
 */
export function ThemeDirectiveRenderer({ spec, className, style }: ThemeDirectiveRendererProps) {
  const actions = useOptionalGenUiActions()
  const accent  = typeof spec.accent === 'string' ? spec.accent : ''
  const validHex = HEX_REGEX.test(accent)
  const [applied, setApplied] = useState(false)
  const canApply = validHex && Boolean(actions?.setAccent) && actions?.enabled !== false && !applied

  return (
    <div
      className={className}
      style={{
        margin: 'var(--ethereal-space-sm) 0',
        padding: 'var(--ethereal-space-md)',
        borderRadius: 'var(--ethereal-radius-md)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 'var(--ethereal-space-sm)',
        ...style,
      }}
    >
      {validHex && (
        <div style={{
          width: 22,
          height: 22,
          borderRadius: '50%',
          background: accent,
          flexShrink: 0,
        }} />
      )}
      <span style={{ flex: 1, color: 'var(--ethereal-text-secondary)', fontSize: '0.875rem' }}>
        {applied ? 'Accent tuned for this chat' : 'Suggested accent for this chat'}
      </span>
      {applied ? (
        <span aria-hidden="true" style={{ color: 'var(--ethereal-accent)', fontSize: '1rem' }}>✓</span>
      ) : canApply ? (
        <Pressable
          onPress={() => {
            setApplied(true)
            actions?.setAccent?.(accent)
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
          Apply
        </Pressable>
      ) : null}
    </div>
  )
}
