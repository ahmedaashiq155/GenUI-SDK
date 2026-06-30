import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface StackRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

interface AlignStyles {
  alignItems: React.CSSProperties['alignItems']
  justifyContent: React.CSSProperties['justifyContent']
}

function resolveAlignment(align: unknown): AlignStyles {
  switch (align) {
    case 'topLeft':     return { alignItems: 'flex-start', justifyContent: 'flex-start' }
    case 'topRight':    return { alignItems: 'flex-start', justifyContent: 'flex-end'   }
    case 'bottomLeft':  return { alignItems: 'flex-end',   justifyContent: 'flex-start' }
    case 'bottomRight': return { alignItems: 'flex-end',   justifyContent: 'flex-end'   }
    case 'top':         return { alignItems: 'flex-start', justifyContent: 'center'     }
    case 'bottom':      return { alignItems: 'flex-end',   justifyContent: 'center'     }
    default:            return { alignItems: 'center',     justifyContent: 'center'     }
  }
}

export function StackRenderer({ spec, onSend, className, style }: StackRendererProps) {
  const children = Array.isArray(spec.children)
    ? (spec.children as unknown[]).filter((c): c is Record<string, unknown> => typeof c === 'object' && c !== null && !Array.isArray(c))
    : []
  const alignStyles = resolveAlignment(spec.align)

  return (
    <div
      className={className}
      style={{
        display: 'grid',
        ...style,
      }}
    >
      {children.map((c, i) => (
        <div
          key={i}
          style={{
            gridArea: '1 / 1 / 2 / 2',
            display: 'flex',
            alignItems: alignStyles.alignItems,
            justifyContent: alignStyles.justifyContent,
          }}
        >
          <GenUiBlock spec={c} onSend={onSend ?? (() => {})} />
        </div>
      ))}
    </div>
  )
}
