import React from 'react'

export interface IconRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

const ICON_UNICODE: Record<string, string> = {
  star: '★', heart: '♥', check: '✓', close: '✕',
  info: 'ℹ', warning: '⚠', bolt: '⚡', spark: '✨',
  fire: '🔥', sun: '☀', moon: '🌙', cloud: '☁',
  rain: '💧', time: '⏰', calendar: '📅', location: '📍',
  home: '⌂', search: '🔍', settings: '⚙', person: '👤',
  group: '👥', chat: '💬', mail: '✉', phone: '📞',
  play: '▶', pause: '⏸', music: '♪', image: '🖼',
  camera: '📷', code: '<>', terminal: '>_', rocket: '🚀',
  trophy: '🏆', gift: '🎁', cart: '🛒', money: '💰',
  chart: '📊', trending_up: '📈', trending_down: '📉',
  arrow_right: '→', arrow_left: '←', up: '↑', down: '↓',
  lock: '🔒', key: '🔑', flag: '⚑', bell: '🔔',
  book: '📖', bulb: '💡', leaf: '🍃', globe: '🌐',
  map: '🗺', food: '🍽', coffee: '☕', pin: '📌',
  link: '🔗', download: '↓', upload: '↑', refresh: '↻',
  add: '+', remove: '−', edit: '✏', delete: '🗑',
}

export function IconRenderer({ spec, className, style }: IconRendererProps) {
  const iconName = String(spec.icon ?? '')
  const char  = ICON_UNICODE[iconName] ?? '•'
  const size  = typeof spec.size === 'number' ? spec.size : 22
  const color = typeof spec.color === 'string' && spec.color ? spec.color : 'var(--ethereal-accent)'

  return (
    <span
      className={className}
      style={{
        fontSize: size,
        color,
        lineHeight: 1,
        userSelect: 'none',
        ...style,
      }}
    >
      {char}
    </span>
  )
}
