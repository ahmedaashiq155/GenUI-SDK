import React from 'react'
import { useOptionalGenUiActions } from '../../provider.js'

export interface ArtifactRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function kindIcon(kind: string): string {
  switch (kind) {
    case 'code':     return '<>'
    case 'markdown': return '≡'
    case 'table':    return '⊞'
    case 'html':     return '⟨/⟩'
    default:         return '⊟'
  }
}

export function ArtifactRenderer({ spec, className, style }: ArtifactRendererProps) {
  const actions = useOptionalGenUiActions()
  const kind    = String(spec.kind ?? '')
  const title   = String(spec.title ?? 'Artifact')
  const icon    = kindIcon(kind)

  function handleClick() {
    actions?.openArtifact?.(spec)
  }

  return (
    <div
      className={className}
      onClick={handleClick}
      style={{
        margin: 'var(--ethereal-space-sm) 0',
        padding: 'var(--ethereal-space-md)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 'var(--ethereal-space-md)',
        cursor: 'pointer',
        ...style,
      }}
    >
      {/* Icon box */}
      <div style={{
        width: 40,
        height: 40,
        flexShrink: 0,
        borderRadius: 'var(--ethereal-radius-md)',
        backgroundColor: 'color-mix(in srgb, var(--ethereal-accent) 14%, transparent)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: 700,
        fontSize: 14,
        color: 'var(--ethereal-accent)',
      }}>
        {icon}
      </div>
      {/* Content */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontWeight: 600,
          fontSize: '0.9375rem',
          color: 'var(--ethereal-text-primary)',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
        }}>
          {title}
        </div>
        <div style={{
          fontSize: 12,
          color: 'var(--ethereal-text-tertiary)',
          marginTop: 2,
        }}>
          {kind} · tap to open
        </div>
      </div>
      {/* Trailing icon */}
      <span style={{ color: 'var(--ethereal-text-tertiary)', fontSize: 16 }}>
        ↗
      </span>
    </div>
  )
}
