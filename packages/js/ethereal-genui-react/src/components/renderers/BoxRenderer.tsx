import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'
import { useOptionalGenUiStore } from '../../provider.js'

export interface BoxRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function BoxRenderer({ spec, onSend, className, style }: BoxRendererProps) {
  const store = useOptionalGenUiStore()

  // Click handling
  const set = spec.set as Record<string, unknown> | null | undefined
  const hasSet = Boolean(set && typeof set === 'object' && Object.keys(set as object).length > 0)
  const sendMsg = typeof spec.send === 'string' ? spec.send : ''
  const hasAction = sendMsg.length > 0 || hasSet

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
  const gradient = Array.isArray(spec.gradient) ? (spec.gradient as unknown[]).filter((c): c is string => typeof c === 'string') : []
  let background: string
  if (gradient.length >= 2) {
    background = `linear-gradient(135deg, ${gradient.join(', ')})`
  } else if (typeof spec.bg === 'string' && spec.bg) {
    background = spec.bg
  } else {
    background = 'var(--ethereal-surface)'
  }

  // Dimensions
  const padding  = typeof spec.padding === 'number' ? spec.padding : 'var(--ethereal-space-md)'
  const radius   = typeof spec.radius  === 'number' ? spec.radius  : 'var(--ethereal-radius-md)'
  const border   = typeof spec.border  === 'string' && spec.border
    ? `1px solid ${spec.border}`
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

  // Children
  const child = spec.child
  const childrenArray = Array.isArray(spec.children)
    ? (spec.children as unknown[]).filter((c): c is Record<string, unknown> => typeof c === 'object' && c !== null && !Array.isArray(c))
    : []

  return (
    <div style={{ padding: '3px 0' }}>
      <div
        className={className}
        onClick={hasAction ? handleClick : undefined}
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
          cursor: hasAction ? 'pointer' : undefined,
          ...style,
        }}
      >
        {child != null && typeof child === 'object' && !Array.isArray(child) && (
          <GenUiBlock spec={child as Record<string, unknown>} onSend={onSend ?? (() => {})} />
        )}
        {childrenArray.map((c, i) => (
          <GenUiBlock key={i} spec={c} onSend={onSend ?? (() => {})} />
        ))}
      </div>
    </div>
  )
}
