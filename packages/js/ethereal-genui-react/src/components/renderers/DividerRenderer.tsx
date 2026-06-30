import React from 'react'

export interface DividerRendererProps {
  className?: string
  style?: React.CSSProperties
}

export function DividerRenderer({ className, style }: DividerRendererProps) {
  return (
    <div
      className={className}
      style={{
        width: '100%',
        height: 0,
        borderTop: '1px solid var(--ethereal-hairline)',
        margin: 'var(--ethereal-space-lg) 0',
        ...style,
      }}
    />
  )
}
