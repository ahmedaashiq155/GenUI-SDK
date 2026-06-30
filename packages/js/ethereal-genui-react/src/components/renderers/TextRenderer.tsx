import React from 'react'

export interface TextRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function resolveWeight(weight: unknown): number {
  switch (weight) {
    case 'bold':     return 700
    case 'semibold': return 600
    case 'medium':   return 500
    case 'light':    return 300
    default:         return 400
  }
}

function resolveAlign(align: unknown): React.CSSProperties['textAlign'] {
  switch (align) {
    case 'center':  return 'center'
    case 'end':
    case 'right':   return 'right'
    case 'justify': return 'justify'
    default:        return 'left'
  }
}

export function TextRenderer({ spec, className, style }: TextRendererProps) {
  const text    = String(spec.text ?? '')
  const size    = typeof spec.size === 'number' ? spec.size : 15
  const weight  = resolveWeight(spec.weight)
  const color   = typeof spec.color === 'string' && spec.color ? spec.color : 'var(--ethereal-text-primary)'
  const align   = resolveAlign(spec.align)

  return (
    <div
      className={className}
      style={{
        padding: '2px 0',
        lineHeight: 1.4,
        fontSize: size,
        fontWeight: weight,
        color,
        textAlign: align,
        margin: 0,
        ...style,
      }}
    >
      {text}
    </div>
  )
}
