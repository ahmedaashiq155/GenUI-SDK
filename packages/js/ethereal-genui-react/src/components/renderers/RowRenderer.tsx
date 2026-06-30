import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface RowRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function resolveJustifyContent(align: unknown): React.CSSProperties['justifyContent'] {
  switch (align) {
    case 'center':       return 'center'
    case 'end':          return 'flex-end'
    case 'between':
    case 'spaceBetween': return 'space-between'
    case 'around':
    case 'spaceAround':  return 'space-around'
    default:             return 'flex-start'
  }
}

function resolveAlignItems(cross: unknown): React.CSSProperties['alignItems'] {
  switch (cross) {
    case 'center':  return 'center'
    case 'end':     return 'flex-end'
    case 'stretch': return 'stretch'
    default:        return 'flex-start'
  }
}

function isSpaced(align: unknown): boolean {
  return align === 'between' || align === 'spaceBetween' || align === 'around' || align === 'spaceAround'
}

export function RowRenderer({ spec, onSend, className, style }: RowRendererProps) {
  const children = Array.isArray(spec.children)
    ? (spec.children as unknown[]).filter((c): c is Record<string, unknown> => typeof c === 'object' && c !== null && !Array.isArray(c))
    : []
  const gap = typeof spec.gap === 'number' ? spec.gap : 8
  const align = spec.align
  const cross = spec.cross ?? 'center'
  const expand = Boolean(spec.expand)
  const spaced = isSpaced(align)

  return (
    <div
      className={className}
      style={{
        display: 'flex',
        flexDirection: 'row',
        justifyContent: resolveJustifyContent(align),
        alignItems: resolveAlignItems(cross),
        gap: spaced ? undefined : gap,
        ...style,
      }}
    >
      {children.map((c, i) => (
        expand
          ? <div key={i} style={{ flex: 1 }}><GenUiBlock spec={c} onSend={onSend ?? (() => {})} /></div>
          : <GenUiBlock key={i} spec={c} onSend={onSend ?? (() => {})} />
      ))}
    </div>
  )
}
