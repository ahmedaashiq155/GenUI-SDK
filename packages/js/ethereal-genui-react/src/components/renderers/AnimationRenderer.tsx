import React from 'react'
import { GenUiBlock } from '../GenUiBlock.js'

export interface AnimationRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

const effects = new Set([
  'fade', 'scale', 'slideUp', 'slideDown', 'slideStart', 'slideEnd', 'pulse',
])

function milliseconds(value: unknown, fallback: number): number {
  const parsed = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(parsed) ? Math.min(10_000, Math.max(0, parsed)) : fallback
}

/** A declarative animation wrapper that CSS disables under reduced motion. */
export function AnimationRenderer({ spec, onSend, className, style }: AnimationRendererProps) {
  const child = spec.child
  if (child === null || typeof child !== 'object' || Array.isArray(child)) return null
  const rawEffect = String(spec.effect ?? 'fade')
  const effect = effects.has(rawEffect) ? rawEffect : 'fade'
  const duration = milliseconds(spec.duration, 250)
  const delay = milliseconds(spec.delay, 0)

  return (
    <div
      className={['ethereal-animation', className].filter(Boolean).join(' ')}
      data-effect={effect}
      style={{
        animationName: `ethereal-${effect}`,
        animationDuration: `${duration}ms`,
        animationDelay: `${delay}ms`,
        animationTimingFunction: 'cubic-bezier(0.2, 0.8, 0.2, 1)',
        animationFillMode: 'both',
        animationIterationCount: spec.repeat === true ? 'infinite' : 1,
        animationDirection: effect === 'pulse' ? 'alternate' : 'normal',
        ...style,
      }}
    >
      <GenUiBlock spec={child as Record<string, unknown>} onSend={onSend} />
    </div>
  )
}
