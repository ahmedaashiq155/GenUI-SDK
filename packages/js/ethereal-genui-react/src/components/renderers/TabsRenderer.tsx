import React, { useId, useState } from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface TabsRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

interface TabItem {
  label: string
  content?: unknown
  text?: string
}

export function TabsRenderer({ spec, onSend, className, style }: TabsRendererProps) {
  const tabs = (spec.tabs as TabItem[] | undefined) ?? []
  const [index, setIndex] = useState(0)
  const idBase = useId()

  if (tabs.length === 0) return null

  const i = Math.min(index, tabs.length - 1)
  const activeTab = tabs[i]

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
      <div
        role="tablist"
        style={{
          overflowX: 'auto',
          whiteSpace: 'nowrap',
          display: 'flex',
          gap: 'var(--ethereal-space-sm)',
          marginBottom: 'var(--ethereal-space-sm)',
          width: '100%',
        }}
      >
        {tabs.map((tab, idx) => {
          const isActive = idx === i
          return (
            <button
              key={idx}
              role="tab"
              id={`${idBase}-tab-${idx}`}
              aria-selected={isActive}
              aria-controls={isActive ? `${idBase}-panel-${i}` : undefined}
              className="ethereal-pressable"
              onClick={() => setIndex(idx)}
              style={{
                borderRadius: 'var(--ethereal-radius-pill)',
                padding: 'var(--ethereal-space-sm) var(--ethereal-space-md)',
                fontWeight: 600,
                fontSize: '13px',
                cursor: 'pointer',
                border: isActive
                  ? '1px solid color-mix(in srgb, var(--ethereal-accent) 40%, transparent)'
                  : '1px solid var(--ethereal-hairline)',
                backgroundColor: isActive
                  ? 'color-mix(in srgb, var(--ethereal-accent) 16%, transparent)'
                  : 'transparent',
                color: isActive
                  ? 'var(--ethereal-accent)'
                  : 'var(--ethereal-text-secondary)',
              }}
            >
              {tab.label}
            </button>
          )
        })}
      </div>
      <div
        role="tabpanel"
        id={`${idBase}-panel-${i}`}
        aria-labelledby={`${idBase}-tab-${i}`}
        style={{ width: '100%' }}
      >
        {activeTab.content && typeof activeTab.content === 'object' && !Array.isArray(activeTab.content) ? (
          <GenUiBlock
            spec={activeTab.content as Record<string, unknown>}
            onSend={onSend ?? (() => {})}
          />
        ) : (
          <span style={{ color: 'var(--ethereal-text-secondary)' }}>
            {activeTab.text ?? ''}
          </span>
        )}
      </div>
    </div>
  )
}
