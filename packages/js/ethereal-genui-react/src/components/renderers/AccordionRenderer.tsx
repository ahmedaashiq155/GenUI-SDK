import React, { useId, useState } from 'react'
import { GenUiBlock } from '../GenUiBlock.js'
import { Pressable } from '../Pressable.js'

export interface AccordionRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

interface AccordionItem {
  title: string
  content?: unknown
  text?: string
}

export function AccordionRenderer({ spec, onSend, className, style }: AccordionRendererProps) {
  const items = (spec.items as AccordionItem[] | undefined) ?? []
  const [openIndices, setOpenIndices] = useState<Set<number>>(new Set())
  const idBase = useId()

  const toggle = (i: number) => {
    setOpenIndices(prev => {
      const next = new Set(prev)
      next.has(i) ? next.delete(i) : next.add(i)
      return next
    })
  }

  return (
    <div
      className={className}
      style={{
        width: '100%',
        ...style,
      }}
    >
      {items.map((item, i) => {
        const isOpen = openIndices.has(i)
        const panelId = `${idBase}-panel-${i}`
        return (
          <div
            key={i}
            style={{
              backgroundColor: 'color-mix(in srgb, var(--ethereal-surface) 50%, transparent)',
              border: '1px solid var(--ethereal-hairline)',
              borderRadius: 'var(--ethereal-radius-md)',
              margin: '3px 0',
            }}
          >
            <Pressable
              onPress={() => toggle(i)}
              aria-expanded={isOpen}
              aria-controls={panelId}
              style={{
                width: '100%',
                padding: 'var(--ethereal-space-md)',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <span>{item.title}</span>
              <span aria-hidden="true" style={{ color: 'var(--ethereal-text-secondary)' }}>
                {isOpen ? '▴' : '▾'}
              </span>
            </Pressable>
            {isOpen && (
              <div
                id={panelId}
                role="region"
                style={{
                  padding: '0 var(--ethereal-space-md) var(--ethereal-space-md)',
                }}
              >
                {item.content && typeof item.content === 'object' && !Array.isArray(item.content) ? (
                  <GenUiBlock
                    spec={item.content as Record<string, unknown>}
                    onSend={onSend ?? (() => {})}
                  />
                ) : (
                  <span>{item.text ?? ''}</span>
                )}
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}
