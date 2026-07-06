import React from 'react'
import { genUiOptions } from '@ethereal/genui-core'
import { usePersistedState } from '../../provider.js'
import { Pressable } from '../Pressable.js'

export interface QuizRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

function toInt(v: unknown, fallback: number): number {
  if (typeof v === 'number') return Math.round(v)
  if (typeof v === 'string') {
    const parsed = parseInt(v, 10)
    if (!isNaN(parsed)) return parsed
  }
  return fallback
}

export function QuizRenderer({ spec, onSend: _onSend, className, style }: QuizRendererProps) {
  const question = String(spec.question ?? spec.title ?? '')
  const options = genUiOptions(spec.options)
  const answer = toInt(spec.answer, -1)
  const explanation = spec.explanation as string | undefined
  const id = spec.id as string | undefined

  const [picked, setPicked] = usePersistedState<number>(id, -1)
  const answered = picked >= 0

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
      <p style={{
        margin: 0,
        fontWeight: 600,
        color: 'var(--ethereal-text-primary)',
        fontSize: '0.9375rem',
        letterSpacing: '-0.01em',
        paddingBottom: 'var(--ethereal-space-sm)',
      }}>
        {question}
      </p>
      {options.map((opt, i) => {
        const isCorrect = answered && i === answer
        const isWrong = answered && i === picked && i !== answer

        let borderColor = 'var(--ethereal-hairline)'
        let bgColor = 'color-mix(in srgb, var(--ethereal-surface) 40%, transparent)'
        let icon: string | null = null

        if (isCorrect) {
          borderColor = 'var(--ethereal-celadon)'
          bgColor = 'color-mix(in srgb, var(--ethereal-celadon) 14%, transparent)'
          icon = '✓'
        } else if (isWrong) {
          borderColor = 'var(--ethereal-danger)'
          bgColor = 'color-mix(in srgb, var(--ethereal-danger) 12%, transparent)'
          icon = '✗'
        }

        return (
          <Pressable
            key={opt.value}
            data-correct={isCorrect || undefined}
            data-wrong={isWrong || undefined}
            disabled={answered}
            aria-label={
              isCorrect ? `${opt.label} — correct answer`
                : isWrong ? `${opt.label} — incorrect`
                : opt.label
            }
            onPress={() => setPicked(i)}
            style={{
              width: '100%',
              padding: 'var(--ethereal-space-md)',
              borderRadius: 'var(--ethereal-radius-md)',
              border: `1px solid ${borderColor}`,
              backgroundColor: bgColor,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              fontSize: '0.9375rem',
              color: 'var(--ethereal-text-primary)',
            }}
          >
            <span>{opt.label}</span>
            {icon && (
              <span aria-hidden="true" style={{
                fontSize: '1rem',
                color: isCorrect
                  ? 'var(--ethereal-celadon)'
                  : 'var(--ethereal-danger)',
              }}>
                {icon}
              </span>
            )}
          </Pressable>
        )
      })}
      {answered && explanation && (
        <p style={{
          margin: 0,
          marginTop: 'var(--ethereal-space-sm)',
          fontSize: '0.875rem',
          color: 'var(--ethereal-text-secondary, var(--ethereal-text-primary))',
        }}>
          {explanation}
        </p>
      )}
    </div>
  )
}
