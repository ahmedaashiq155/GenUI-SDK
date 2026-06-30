import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface SectionRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function SectionRenderer({ spec, onSend, className, style }: SectionRendererProps) {
  const title = spec.title as string | undefined
  const children = (spec.children as unknown[] | undefined) ?? []

  return (
    <div
      className={className}
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'flex-start',
        width: '100%',
        ...style,
      }}
    >
      {title && (
        <span
          style={{
            fontWeight: 600,
            fontSize: '1rem',
            marginTop: 'var(--ethereal-space-sm)',
            marginBottom: 'var(--ethereal-space-xs)',
          }}
        >
          {title}
        </span>
      )}
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
