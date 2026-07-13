import React, { useEffect, useMemo, useRef, useState } from 'react'

export interface ConverterRendererProps {
  spec: Record<string, unknown>
  onSend?: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

interface Unit {
  label: string
  factor: number
}

const DEFAULT_UNITS: Unit[] = [
  { label: 'm', factor: 1 },
  { label: 'km', factor: 1000 },
  { label: 'mi', factor: 1609.344 },
  { label: 'ft', factor: 0.3048 },
]

function parseUnits(raw: unknown): Unit[] {
  const arr = Array.isArray(raw) ? raw : []
  const units: Unit[] = arr
    .filter((u): u is Record<string, unknown> => u !== null && typeof u === 'object')
    .map((u) => ({
      label: String(u.label ?? ''),
      factor: typeof u.factor === 'number' ? u.factor : 1,
    }))
  return units.length >= 2 ? units : DEFAULT_UNITS
}

export function ConverterRenderer({ spec, className, style }: ConverterRendererProps) {
  const title = spec.title as string | undefined
  const units = useMemo(() => parseUnits(spec.units), [spec.units])

  const [input, setInput] = useState('1')
  const [fromIdx, setFromIdx] = useState(0)
  const [toIdx, setToIdx] = useState(Math.min(1, units.length - 1))
  const previousUnits = useRef(units)

  useEffect(() => {
    const previousFrom = previousUnits.current[fromIdx]?.label
    const previousTo = previousUnits.current[toIdx]?.label
    const nextFrom = units.findIndex(unit => unit.label === previousFrom)
    const nextTo = units.findIndex(unit => unit.label === previousTo)
    setFromIdx(nextFrom >= 0 ? nextFrom : 0)
    setToIdx(nextTo >= 0 ? nextTo : Math.min(1, units.length - 1))
    previousUnits.current = units
  }, [units])

  const fromFactor = units[fromIdx]?.factor ?? 1
  const toFactor = units[toIdx]?.factor ?? 1
  const numInput = parseFloat(input) || 0
  const result = toFactor === 0 ? 0 : numInput * fromFactor / toFactor
  const resultStr = Number.isInteger(result) ? String(result) : result.toFixed(4)

  const selectStyle: React.CSSProperties = {
    padding: '6px var(--ethereal-space-sm)',
    borderRadius: 'var(--ethereal-radius-sm)',
    border: '1px solid var(--ethereal-hairline)',
    backgroundColor: 'color-mix(in srgb, var(--ethereal-accent) 14%, transparent)',
    color: 'var(--ethereal-accent)',
    fontWeight: 600,
    fontSize: '0.875rem',
    cursor: 'pointer',
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
      {title && (
        <p style={{
          margin: 0,
          fontWeight: 600,
          color: 'var(--ethereal-text-primary)',
          fontSize: '0.9375rem',
          letterSpacing: '-0.012em',
          paddingBottom: 'var(--ethereal-space-sm)',
        }}>
          {title}
        </p>
      )}

      {/* Input row */}
      <div style={{ display: 'flex', gap: 'var(--ethereal-space-sm)', alignItems: 'center' }}>
        <input
          type="text"
          inputMode="decimal"
          aria-label={title ?? 'Value to convert'}
          value={input}
          onChange={(e) => setInput(e.target.value)}
          style={{
            flex: 1,
            padding: '8px var(--ethereal-space-sm)',
            borderRadius: 'var(--ethereal-radius-md)',
            border: '1px solid var(--ethereal-hairline)',
            backgroundColor: 'var(--ethereal-surface)',
            color: 'var(--ethereal-text-primary)',
            fontSize: '1rem',
            fontVariantNumeric: 'tabular-nums',
          }}
        />
        <select
          aria-label="From unit"
          value={fromIdx}
          onChange={(e) => setFromIdx(Number(e.target.value))}
          style={selectStyle}
        >
          {units.map((u, i) => (
            <option key={i} value={i}>{u.label}</option>
          ))}
        </select>
      </div>

      {/* Swap icon */}
      <div aria-hidden="true" style={{
        textAlign: 'center',
        color: 'var(--ethereal-text-tertiary)',
        fontSize: '1.25rem',
        lineHeight: 1,
        padding: '2px 0',
      }}>
        ↕
      </div>

      {/* Result row */}
      <div style={{ display: 'flex', gap: 'var(--ethereal-space-sm)', alignItems: 'center' }}>
        <span aria-live="polite" style={{
          flex: 1,
          padding: '8px var(--ethereal-space-sm)',
          fontSize: '1.25rem',
          fontWeight: 600,
          color: 'var(--ethereal-accent)',
          fontVariantNumeric: 'tabular-nums',
        }}>
          {resultStr}
        </span>
        <select
          aria-label="To unit"
          value={toIdx}
          onChange={(e) => setToIdx(Number(e.target.value))}
          style={selectStyle}
        >
          {units.map((u, i) => (
            <option key={i} value={i}>{u.label}</option>
          ))}
        </select>
      </div>
    </div>
  )
}
