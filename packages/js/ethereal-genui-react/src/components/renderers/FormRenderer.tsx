import React from 'react'
import { genUiOptions } from '@ethereal/genui-core'
import { usePersistedState } from '../../provider.js'

export interface FormRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function FormRenderer({ spec, onSend, className, style }: FormRendererProps) {
  const title = spec.title as string | undefined
  const submitLabel = String(spec.submitLabel ?? 'Submit')
  const id = spec.id as string | undefined
  const fields = (Array.isArray(spec.fields) ? spec.fields : []).filter(
    (f): f is Record<string, unknown> => typeof f === 'object' && f !== null
  )

  const [values, setValues] = usePersistedState<Record<string, unknown>>(id, {})
  const setField = (key: string, v: unknown) => setValues({ ...values, [key]: v })

  const handleSubmit = () => {
    const lines = fields
      .map(f => {
        const key = String(f.key ?? f.label ?? '')
        const label = String(f.label ?? key)
        const v = values[key]
        return v != null && String(v).trim() ? `${label}: ${String(v).trim()}` : null
      })
      .filter((l): l is string => l !== null)
    onSend(lines.join('\n'))
  }

  const inputStyle: React.CSSProperties = {
    padding: '6px var(--ethereal-space-md)',
    borderRadius: 'var(--ethereal-radius-sm, 6px)',
    border: '1px solid var(--ethereal-hairline)',
    backgroundColor: 'transparent',
    color: 'var(--ethereal-text-primary)',
    fontSize: '0.875rem',
    fontFamily: 'inherit',
    outline: 'none',
    width: '100%',
    boxSizing: 'border-box',
  }

  const labelStyle: React.CSSProperties = {
    margin: 0,
    marginBottom: '4px',
    fontWeight: 500,
    fontSize: '0.875rem',
    color: 'var(--ethereal-text-secondary, var(--ethereal-text-primary))',
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
        gap: 'var(--ethereal-space-md)',
        ...style,
      }}
    >
      {title && (
        <p style={{
          margin: 0,
          fontWeight: 600,
          color: 'var(--ethereal-text-primary)',
          fontSize: '0.9375rem',
          letterSpacing: '-0.01em',
          paddingBottom: 'var(--ethereal-space-sm)',
        }}>
          {title}
        </p>
      )}
      {fields.map((f, idx) => {
        const key = String(f.key ?? f.label ?? '')
        const fieldLabel = String(f.label ?? key)
        const fieldType = String(f.type ?? 'text')

        if (fieldType === 'toggle') {
          const boolVal = (values[key] as boolean | undefined) ?? (f.value === true)
          return (
            <div key={idx} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <span style={{ color: 'var(--ethereal-text-primary)', fontSize: '1rem' }}>{fieldLabel}</span>
              <input
                type="checkbox"
                checked={boolVal}
                onChange={(e) => setField(key, e.target.checked)}
                style={{ accentColor: 'var(--ethereal-accent)', width: '1.25rem', height: '1.25rem', cursor: 'pointer' }}
              />
            </div>
          )
        }

        if (fieldType === 'select') {
          const options = genUiOptions(f.options)
          return (
            <div key={idx} style={{ display: 'flex', flexDirection: 'column' }}>
              <p style={labelStyle}>{fieldLabel}</p>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--ethereal-space-sm)' }}>
                {options.map((opt) => {
                  const isSel = values[key] === opt.value
                  return (
                    <button
                      key={opt.value}
                      onClick={() => setField(key, opt.value)}
                      style={{
                        padding: '5px calc(var(--ethereal-space-md) + 2px)',
                        borderRadius: 'var(--ethereal-radius-pill)',
                        border: 'none',
                        cursor: 'pointer',
                        fontWeight: 500,
                        fontSize: '0.8125rem',
                        backgroundColor: isSel
                          ? 'var(--ethereal-accent)'
                          : 'color-mix(in srgb, var(--ethereal-accent) 10%, transparent)',
                        color: isSel ? 'var(--ethereal-on-accent, #fff)' : 'var(--ethereal-accent)',
                      }}
                    >
                      {opt.label}
                    </button>
                  )
                })}
              </div>
            </div>
          )
        }

        // text | number
        return (
          <div key={idx} style={{ display: 'flex', flexDirection: 'column' }}>
            <p style={labelStyle}>{fieldLabel}</p>
            <input
              type={fieldType === 'number' ? 'number' : 'text'}
              value={String(values[key] ?? '')}
              placeholder={String(f.placeholder ?? '')}
              onChange={(e) => setField(key, e.target.value)}
              style={inputStyle}
            />
          </div>
        )
      })}
      <button
        onClick={handleSubmit}
        style={{
          padding: '8px var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          border: 'none',
          cursor: 'pointer',
          fontWeight: 500,
          fontSize: '0.875rem',
          backgroundColor: 'var(--ethereal-accent)',
          color: 'var(--ethereal-on-accent, #fff)',
          alignSelf: 'flex-start',
          transition: 'opacity 0.1s ease',
          marginTop: 'var(--ethereal-space-sm)',
        }}
        onMouseOver={(e) => (e.currentTarget.style.opacity = '0.8')}
        onMouseOut={(e) => (e.currentTarget.style.opacity = '1')}
      >
        {submitLabel}
      </button>
    </div>
  )
}
