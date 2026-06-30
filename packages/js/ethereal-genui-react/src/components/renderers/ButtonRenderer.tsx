import React from 'react'
import { IconRenderer } from './IconRenderer.js'
import { useOptionalGenUiStore } from '../../provider.js'

export interface ButtonRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ButtonRenderer({ spec, onSend, className, style }: ButtonRendererProps) {
  const store = useOptionalGenUiStore()

  const explicitSend = String(spec.send ?? '')
  const set = spec.set as Record<string, unknown> | null | undefined
  const hasSet = Boolean(set && typeof set === 'object' && Object.keys(set as object).length > 0)
  const sendMsg = explicitSend
    ? explicitSend
    : (hasSet ? '' : String(spec.label ?? ''))
  const hasAction = sendMsg.length > 0 || hasSet

  const tint = typeof spec.color === 'string' && spec.color ? spec.color : 'var(--ethereal-accent)'
  const variant = spec.style as string | undefined

  let bgStyle: string
  let textColor: string
  let borderStyle: string | undefined
  if (variant === 'primary') {
    bgStyle = tint
    textColor = 'var(--ethereal-on-accent)'
    borderStyle = undefined
  } else if (variant === 'ghost') {
    bgStyle = 'transparent'
    textColor = tint
    borderStyle = `1px solid color-mix(in srgb, ${tint} 40%, transparent)`
  } else {
    // soft (default)
    bgStyle = `color-mix(in srgb, ${tint} 14%, transparent)`
    textColor = tint
    borderStyle = undefined
  }

  function handleClick() {
    if (!hasAction) return
    if (hasSet) {
      Object.entries(set!).forEach(([key, value]) => {
        store?.setValue(key, value)
      })
    }
    if (sendMsg.length > 0) {
      onSend?.(sendMsg)
    }
  }

  const hasIcon = typeof spec.icon === 'string' && spec.icon

  return (
    <div
      style={{
        margin: '2px 0',
      }}
    >
      <button
        className={className}
        onClick={handleClick}
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: 6,
          padding: 'var(--ethereal-space-md) var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          background: bgStyle,
          color: textColor,
          border: borderStyle ?? 'none',
          fontWeight: 600,
          fontSize: 14,
          cursor: hasAction ? 'pointer' : 'default',
          opacity: hasAction ? 1 : 0.5,
          outline: 'none',
          ...style,
        }}
      >
        {hasIcon && (
          <IconRenderer spec={{ type: 'icon', icon: spec.icon }} />
        )}
        {String(spec.label ?? '')}
      </button>
    </div>
  )
}
