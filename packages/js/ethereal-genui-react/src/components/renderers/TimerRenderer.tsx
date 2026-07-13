import React, { useState, useEffect } from 'react'

export interface TimerRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0')
  const s = (seconds % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

export function TimerRenderer({ spec, className, style }: TimerRendererProps) {
  const rawTotal = typeof spec.seconds === 'number' && Number.isFinite(spec.seconds)
    ? Math.round(spec.seconds)
    : 60
  const total = Math.min(Math.max(rawTotal, 0), 86400)
  const label = spec.label as string | undefined

  const [remaining, setRemaining] = useState(() => total)
  const [running, setRunning] = useState(false)

  useEffect(() => {
    setRunning(false)
    setRemaining(total)
  }, [total])

  useEffect(() => {
    if (!running) return
    const id = setInterval(() => {
      setRemaining((r) => {
        if (r <= 1) {
          setRunning(false)
          return 0
        }
        return r - 1
      })
    }, 1000)
    return () => clearInterval(id)
  }, [running])

  function handleToggle() {
    if (running) {
      setRunning(false)
    } else {
      if (remaining === 0) {
        setRemaining(total)
      }
      setRunning(true)
    }
  }

  // running = Pause, paused (remaining > 0, not running) = Resume, done/idle = Start
  let btnLabel: string
  if (running) {
    btnLabel = 'Pause'
  } else if (remaining > 0 && remaining < total) {
    btnLabel = 'Resume'
  } else {
    btnLabel = 'Start'
  }

  const isDone = remaining === 0 && !running

  return (
    <div
      className={className}
      style={{
        width: '100%',
        padding: 'var(--ethereal-space-lg)',
        borderRadius: 'var(--ethereal-radius-lg)',
        border: '1px solid var(--ethereal-hairline)',
        backgroundColor: 'var(--ethereal-surface)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: 'var(--ethereal-space-md)',
        ...style,
      }}
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
        {label && (
          <span style={{
            color: 'var(--ethereal-text-tertiary)',
            fontSize: '0.8125rem',
          }}>
            {label}
          </span>
        )}
        <span style={{
          fontSize: '2.5rem',
          fontWeight: 700,
          fontVariantNumeric: 'tabular-nums',
          letterSpacing: '-0.02em',
          color: isDone ? 'var(--ethereal-celadon)' : 'var(--ethereal-text-primary)',
          lineHeight: 1,
        }}>
          {formatTime(remaining)}
        </span>
      </div>
      <button
        onClick={handleToggle}
        style={{
          padding: '8px var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          border: 'none',
          cursor: 'pointer',
          fontWeight: 500,
          fontSize: '0.875rem',
          backgroundColor: 'var(--ethereal-accent)',
          color: 'var(--ethereal-on-accent)',
          flexShrink: 0,
        }}
      >
        {btnLabel}
      </button>
    </div>
  )
}
