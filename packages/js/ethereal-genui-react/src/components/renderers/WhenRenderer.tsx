import React, { useSyncExternalStore } from 'react'
import { GenUiBlock } from '../GenUiBlock.js'
import { useOptionalGenUiStore } from '../../provider.js'

export interface WhenRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function WhenRenderer({ spec, onSend, className, style }: WhenRendererProps) {
  const store = useOptionalGenUiStore()
  // Subscribe for reactivity; if no store, always returns undefined
  const value = useSyncExternalStore(
    store ? store.subscribe : (() => () => {}),
    () => store ? store.getValue(spec.key as string) : undefined,
    () => undefined,
  )
  const equals = spec.equals
  const matches = (equals !== undefined && equals !== null)
    ? value === equals
    : (value != null && value !== false && value !== 0 && String(value) !== '')
  if (!matches) return null
  const child = spec.child
  if (child && typeof child === 'object' && !Array.isArray(child)) {
    return <GenUiBlock spec={child as Record<string, unknown>} onSend={onSend ?? (() => {})} />
  }
  const kids = Array.isArray(spec.children)
    ? (spec.children as unknown[]).filter((c): c is Record<string, unknown> => typeof c === 'object' && c !== null && !Array.isArray(c))
    : []
  return (
    <div className={className} style={style}>
      {kids.map((c, i) => <GenUiBlock key={i} spec={c} onSend={onSend ?? (() => {})} />)}
    </div>
  )
}
