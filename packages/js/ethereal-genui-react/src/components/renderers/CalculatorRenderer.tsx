import React, { useState } from 'react'

export interface CalculatorRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

const ROWS = [
  ['C', '÷'],
  ['7', '8', '9', '×'],
  ['4', '5', '6', '−'],
  ['1', '2', '3', '+'],
  ['0', '.', '='],
]

const OPS = new Set(['+', '−', '×', '÷', '='])

function computeResult(acc: number, op: string, b: number): number {
  switch (op) {
    case '+': return acc + b
    case '−': return acc - b
    case '×': return acc * b
    case '÷': return b === 0 ? NaN : acc / b
    default: return b
  }
}

function formatResult(r: number): string {
  if (isNaN(r)) return 'Error'
  return Number.isInteger(r) ? String(r) : String(r)
}

export function CalculatorRenderer({ className, style }: CalculatorRendererProps) {
  const [display, setDisplay] = useState('0')
  const [acc, setAcc] = useState<number | null>(null)
  const [op, setOp] = useState<string | null>(null)
  const [resetNext, setResetNext] = useState(true)

  function handleDigit(d: string) {
    if (resetNext || display === '0') {
      setDisplay(d === '.' ? '0.' : d)
      setResetNext(false)
    } else if (!(d === '.' && display.includes('.'))) {
      setDisplay(display + d)
    }
  }

  function doCompute(currentDisplay: string, currentAcc: number | null, currentOp: string | null): string {
    if (currentOp === null || currentAcc === null) return currentDisplay
    const b = parseFloat(currentDisplay) || 0
    const r = computeResult(currentAcc, currentOp, b)
    return formatResult(r)
  }

  function handleOp(key: string) {
    const current = parseFloat(display) || 0
    if (op !== null && !resetNext) {
      // chain: compute first
      const result = doCompute(display, acc, op)
      const newAcc = parseFloat(result) || 0
      setDisplay(result)
      setAcc(newAcc)
    } else {
      setAcc(current)
    }
    setOp(key)
    setResetNext(true)
  }

  function handleEquals() {
    const result = doCompute(display, acc, op)
    setDisplay(result)
    setAcc(null)
    setOp(null)
    setResetNext(true)
  }

  function handleClear() {
    setDisplay('0')
    setAcc(null)
    setOp(null)
    setResetNext(true)
  }

  function handleKey(key: string) {
    if (key === 'C') {
      handleClear()
    } else if (key === '=') {
      handleEquals()
    } else if (OPS.has(key)) {
      handleOp(key)
    } else {
      handleDigit(key)
    }
  }

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
        flexDirection: 'column',
        gap: 'var(--ethereal-space-sm)',
        ...style,
      }}
    >
      {/* Display */}
      <div style={{
        width: '100%',
        padding: 'var(--ethereal-space-md)',
        textAlign: 'right',
        borderRadius: 'var(--ethereal-radius-md)',
        backgroundColor: 'color-mix(in srgb, var(--ethereal-surface) 60%, transparent)',
        border: '1px solid var(--ethereal-hairline)',
        fontSize: '1.5rem',
        fontWeight: 600,
        fontVariantNumeric: 'tabular-nums',
        color: 'var(--ethereal-text-primary)',
        overflow: 'hidden',
        whiteSpace: 'nowrap',
        textOverflow: 'ellipsis',
      }}>
        {display}
      </div>

      {/* Button rows */}
      {ROWS.map((row, ri) => (
        <div key={ri} style={{ display: 'flex', gap: 'var(--ethereal-space-sm)' }}>
          {row.map((key) => {
            const isClear = key === 'C'
            const isOp = OPS.has(key)
            const flex = key === '0' ? 2 : 1

            let bg: string
            let fg: string
            if (isClear) {
              bg = 'color-mix(in srgb, var(--ethereal-danger) 16%, transparent)'
              fg = 'var(--ethereal-danger)'
            } else if (isOp) {
              bg = 'color-mix(in srgb, var(--ethereal-accent) 18%, transparent)'
              fg = 'var(--ethereal-accent)'
            } else {
              bg = 'color-mix(in srgb, var(--ethereal-surface) 50%, transparent)'
              fg = 'var(--ethereal-text-primary)'
            }

            return (
              <button
                key={key}
                onClick={() => handleKey(key)}
                style={{
                  flex,
                  height: 46,
                  border: 'none',
                  borderRadius: 'var(--ethereal-radius-md)',
                  backgroundColor: bg,
                  color: fg,
                  fontSize: '1.125rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {key}
              </button>
            )
          })}
        </div>
      ))}
    </div>
  )
}
