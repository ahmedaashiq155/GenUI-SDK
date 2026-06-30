import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface GridRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function GridRenderer({ spec, onSend, className, style }: GridRendererProps) {
  const cols = (spec.columns as number | undefined) ?? 2
  const children = (spec.children as unknown[] | undefined) ?? []

  return (
    <div
      className={className}
      style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${cols}, 1fr)`,
        gap: 'var(--ethereal-space-sm)',
        width: '100%',
        ...style,
      }}
    >
      {children.map((child, i) => (
        <GenUiBlock
          key={i}
          spec={child as Record<string, unknown>}
          onSend={onSend ?? (() => {})}
        />
      ))}
    </div>
  )
}
