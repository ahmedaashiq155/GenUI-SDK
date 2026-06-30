import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface ColumnRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function resolveCrossAlign(cross: unknown): React.CSSProperties['alignItems'] {
  switch (cross) {
    case 'center':  return 'center'
    case 'end':     return 'flex-end'
    case 'stretch': return 'stretch'
    case 'start':
    default:        return 'flex-start'
  }
}

export function ColumnRenderer({ spec, onSend, className, style }: ColumnRendererProps) {
  const children = Array.isArray(spec.children)
    ? (spec.children as unknown[]).filter((c): c is Record<string, unknown> => typeof c === 'object' && c !== null && !Array.isArray(c))
    : []
  const gap   = typeof spec.gap === 'number' ? spec.gap : 4
  // Dart: spec['cross'] ?? spec['align'] ?? 'start'
  const cross = spec.cross ?? spec.align ?? 'start'

  return (
    <div
      className={className}
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: resolveCrossAlign(cross),
        gap,
        minHeight: 0,
        ...style,
      }}
    >
      {children.map((c, i) => (
        <GenUiBlock key={i} spec={c} onSend={onSend ?? (() => {})} />
      ))}
    </div>
  )
}
