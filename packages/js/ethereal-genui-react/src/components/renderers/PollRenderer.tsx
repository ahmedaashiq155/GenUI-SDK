import React, { useState } from 'react'
import { usePersistedState } from '../../provider.js'

export interface PollRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function PollRenderer({ spec, onSend, className, style }: PollRendererProps) {
  const title = spec.title as string | undefined
  const id = spec.id as string | undefined

  // Parse raw options — may be strings or objects with label+votes
  const rawOptions = Array.isArray(spec.options) ? spec.options : []
  const labels: string[] = rawOptions.map(o =>
    typeof o === 'object' && o !== null
      ? String((o as Record<string, unknown>).label ?? '')
      : String(o)
  )

  const [votedIndex, setVotedIndex] = usePersistedState<number>(id, -1)
  const [votes, setVotes] = useState<number[]>(() =>
    rawOptions.map(o =>
      typeof o === 'object' && o !== null && (o as Record<string, unknown>).votes
        ? Number((o as Record<string, unknown>).votes)
        : 0
    )
  )

  const handleVote = (i: number) => {
    if (votedIndex >= 0) return
    const newVotes = votes.map((v, idx) => idx === i ? v + 1 : v)
    setVotes(newVotes)
    setVotedIndex(i)
    onSend(labels[i])
  }

  const total = Math.max(votes.reduce((a, b) => a + b, 0), 1)

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
          letterSpacing: '-0.01em',
          paddingBottom: 'var(--ethereal-space-sm)',
        }}>
          {title}
        </p>
      )}
      {labels.map((lbl, i) => {
        const pct = votedIndex >= 0 ? votes[i] / total : 0
        const isVoted = i === votedIndex
        return (
          <div
            key={i}
            onClick={() => handleVote(i)}
            style={{
              position: 'relative',
              height: '40px',
              borderRadius: 'var(--ethereal-radius-sm, 6px)',
              backgroundColor: 'color-mix(in srgb, var(--ethereal-surface) 50%, transparent)',
              border: '1px solid var(--ethereal-hairline)',
              overflow: 'hidden',
              cursor: votedIndex < 0 ? 'pointer' : 'default',
            }}
          >
            {/* Fill bar */}
            {votedIndex >= 0 && (
              <div style={{
                position: 'absolute',
                top: 0,
                left: 0,
                height: '100%',
                width: `${Math.max(pct * 100, pct > 0 ? 0.5 : 0)}%`,
                minWidth: pct > 0 ? '2px' : '0',
                backgroundColor: isVoted
                  ? 'color-mix(in srgb, var(--ethereal-accent) 28%, transparent)'
                  : 'color-mix(in srgb, var(--ethereal-accent) 12%, transparent)',
                borderRadius: 'var(--ethereal-radius-sm, 6px)',
              }} />
            )}
            {/* Label row */}
            <div style={{
              position: 'relative',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              height: '100%',
              padding: '0 var(--ethereal-space-md)',
            }}>
              <span style={{
                fontWeight: isVoted ? 700 : 500,
                color: 'var(--ethereal-text-primary)',
                fontSize: '0.9375rem',
              }}>
                {lbl}
              </span>
              {votedIndex >= 0 && (
                <span style={{
                  fontSize: '0.8125rem',
                  color: 'var(--ethereal-text-secondary, var(--ethereal-text-primary))',
                }}>
                  {Math.round(pct * 100)}%
                </span>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}
