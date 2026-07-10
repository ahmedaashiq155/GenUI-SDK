import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'
import { useOptionalGenUiStore } from '../../provider.js'
import { safeColor } from './cssSafe.js'
import { useGenUiInteractionEnabled } from '../GenUiInteraction.js'

export interface BoxRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function BoxRenderer({ spec, onSend, className, style }: BoxRendererProps) {
  const store = useOptionalGenUiStore()
  const sendEnabled = useGenUiInteractionEnabled()

  // Click handling
  const set = spec.set as Record<string, unknown> | null | undefined
  const hasSet = Boolean(set && typeof set === 'object' && Object.keys(set as object).length > 0)
  const sendMsg = typeof spec.send === 'string' ? spec.send : ''
  const hasAction = sendMsg.length > 0 || hasSet
  const actionEnabled = hasAction && (sendMsg.length === 0 || sendEnabled)

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

  // Background
  const gradient = Array.isArray(spec.gradient)
    ? (spec.gradient as unknown[]).map(safeColor).filter((c): c is string => c !== undefined)
    : []
  const bg = safeColor(spec.bg)
  let background: string
  if (gradient.length >= 2) {
    background = `linear-gradient(135deg, ${gradient.join(', ')})`
  } else if (bg) {
    background = bg
  } else {
    background = 'var(--ethereal-surface)'
  }

  // Dimensions
  const padding  = typeof spec.padding === 'number' ? spec.padding : 'var(--ethereal-space-md)'
  const radius   = typeof spec.radius  === 'number' ? spec.radius  : 'var(--ethereal-radius-md)'
  const borderColor = safeColor(spec.border)
  const border   = borderColor
    ? `1px solid ${borderColor}`
    : '1px solid var(--ethereal-hairline)'
  const width  = typeof spec.width  === 'number' ? spec.width  : undefined
  const height = typeof spec.height === 'number' ? spec.height : undefined

  // Alignment
  let alignItems: React.CSSProperties['alignItems'] = 'flex-start'
  switch (spec.align) {
    case 'center':  alignItems = 'center';   break
    case 'end':     alignItems = 'flex-end'; break
    case 'stretch': alignItems = 'stretch';  break
  }

  // Children — child and children are mutually exclusive; child takes precedence
  const child = spec.child
  const hasSingleChild = child != null && typeof child === 'object' && !Array.isArray(child)
  const childrenArray = !hasSingleChild && Array.isArray(spec.children)
    ? (spec.children as unknown[]).filter((c): c is Record<string, unknown> => typeof c === 'object' && c !== null && !Array.isArray(c))
    : []

  return (
    <div style={{ padding: '3px 0' }}>
      <div
        className={className}
        onClick={actionEnabled ? handleClick : undefined}
        aria-disabled={hasAction && !actionEnabled ? true : undefined}
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems,
          padding: typeof padding === 'number' ? `${padding}px` : padding,
          borderRadius: typeof radius === 'number' ? `${radius}px` : radius,
          border,
          background,
          width:  width  ? `${width}px`  : undefined,
          height: height ? `${height}px` : undefined,
          cursor: actionEnabled ? 'pointer' : undefined,
          opacity: hasAction && !actionEnabled ? 0.55 : undefined,
          ...style,
        }}
      >
        {hasSingleChild && (
          <GenUiBlock spec={child as Record<string, unknown>} onSend={onSend ?? (() => {})} />
        )}
        {childrenArray.map((c, i) => (
          <GenUiBlock key={i} spec={c} onSend={onSend ?? (() => {})} />
        ))}
      </div>
    </div>
  )
}
