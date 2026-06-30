import React, { useState } from 'react'

export interface InputRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function InputRenderer({ spec, onSend, className, style }: InputRendererProps) {
  const label = spec.label as string | undefined ?? spec.title as string | undefined
  const placeholder = String(spec.placeholder ?? 'Type your answer')
  const submitLabel = String(spec.submitLabel ?? 'Send')
  const [text, setText] = useState('')

  const handleSubmit = () => {
    const trimmed = text.trim()
    if (trimmed) {
      onSend(trimmed)
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
      {label && (
        <p style={{
          margin: 0,
          fontWeight: 600,
          color: 'var(--ethereal-text-primary)',
          fontSize: '0.9375rem',
          letterSpacing: '-0.01em',
          paddingBottom: 'var(--ethereal-space-sm)',
        }}>
          {label}
        </p>
      )}
      <textarea
        rows={1}
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder={placeholder}
        style={{
          resize: 'vertical',
          minHeight: '2.5rem',
          maxHeight: '6rem',
          padding: '8px var(--ethereal-space-md)',
          borderRadius: 'var(--ethereal-radius-md)',
          border: '1px solid var(--ethereal-hairline)',
          backgroundColor: 'transparent',
          color: 'var(--ethereal-text-primary)',
          fontSize: '0.9375rem',
          fontFamily: 'inherit',
          outline: 'none',
          width: '100%',
          boxSizing: 'border-box',
        }}
      />
      <button
        onClick={handleSubmit}
        disabled={!text.trim()}
        style={{
          padding: '8px var(--ethereal-space-lg)',
          borderRadius: 'var(--ethereal-radius-pill)',
          border: 'none',
          cursor: text.trim() ? 'pointer' : 'not-allowed',
          fontWeight: 500,
          fontSize: '0.875rem',
          backgroundColor: text.trim()
            ? 'var(--ethereal-accent)'
            : 'color-mix(in srgb, var(--ethereal-accent) 20%, transparent)',
          color: text.trim() ? 'var(--ethereal-on-accent)' : 'var(--ethereal-text-tertiary)',
          alignSelf: 'flex-start',
          transition: 'opacity 0.1s ease',
          opacity: text.trim() ? 1 : 0.5,
        }}
      >
        {submitLabel}
      </button>
    </div>
  )
}
