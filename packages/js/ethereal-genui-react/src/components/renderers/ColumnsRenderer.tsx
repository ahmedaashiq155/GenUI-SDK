import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface ColumnsRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function ColumnsRenderer({ spec, onSend, className, style }: ColumnsRendererProps) {
  const children = (spec.children as unknown[] | undefined) ?? []

  return (
    <div
      className={className}
      style={{
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'flex-start',
        gap: 'var(--ethereal-space-sm)',
        width: '100%',
        ...style,
      }}
    >
      {children.map((child, i) => (
        <div key={i} style={{ flex: 1 }}>
          <GenUiBlock
            spec={child as Record<string, unknown>}
            onSend={onSend ?? (() => {})}
          />
        </div>
      ))}
    </div>
  )
}
