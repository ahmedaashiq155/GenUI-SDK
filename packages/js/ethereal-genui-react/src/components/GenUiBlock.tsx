import React from 'react'
import { ChoicesRenderer } from './renderers/ChoicesRenderer.js'

export interface GenUiBlockProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function GenUiBlock({ spec, onSend, className, style }: GenUiBlockProps) {
  const type = spec.type as string
  switch (type) {
    case 'choices':
      return <ChoicesRenderer spec={spec} onSend={onSend} className={className} style={style} />
    default:
      return null
  }
}
