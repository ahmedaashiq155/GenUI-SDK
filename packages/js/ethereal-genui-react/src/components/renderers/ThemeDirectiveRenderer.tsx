import React, { useEffect } from 'react'
import { useOptionalGenUiActions } from '../../provider.js'

export interface ThemeDirectiveRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

const HEX_REGEX = /^#[0-9a-fA-F]{3,8}$/

export function ThemeDirectiveRenderer({ spec, className, style }: ThemeDirectiveRendererProps) {
  const actions = useOptionalGenUiActions()
  const accent  = typeof spec.accent === 'string' ? spec.accent : ''
  const validHex = HEX_REGEX.test(accent)

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    if (validHex) {
      actions?.setAccent?.(accent)
    }
  }, [])

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
      <span style={{ color: 'var(--ethereal-text-secondary)', fontSize: '0.875rem' }}>
        Accent tuned for this chat
      </span>
    </div>
  )
}
