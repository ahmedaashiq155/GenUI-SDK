import React from 'react'

export interface SpacerRendererProps {
  spec: Record<string, unknown>
  className?: string
  style?: React.CSSProperties
}

export function SpacerRenderer({ spec, className, style }: SpacerRendererProps) {
  const size = typeof spec.size === 'number' ? spec.size : 16

  return (
    <div
      className={className}
      style={{
        width: size,
        height: size,
        flexShrink: 0,
        ...style,
      }}
    />
  )
}
