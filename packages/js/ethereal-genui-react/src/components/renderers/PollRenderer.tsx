import React, { useEffect, useMemo, useRef, useState } from 'react'
import { usePersistedState } from '../../provider.js'
import { Pressable } from '../Pressable.js'
import { useGenUiInteractionEnabled } from '../GenUiInteraction.js'

export interface PollRendererProps {
  spec: Record<string, unknown>
  onSend: (message: string) => void
  className?: string
  style?: React.CSSProperties
}

export function PollRenderer({ spec, onSend, className, style }: PollRendererProps) {
  const enabled = useGenUiInteractionEnabled()
  const title = spec.title as string | undefined
  const id = spec.id as string | undefined

  const rawOptions = Array.isArray(spec.options) ? spec.options : []
  const options = useMemo(() => rawOptions.map(o => {
    if (typeof o === 'object' && o !== null) {
      const map = o as Record<string, unknown>
      const label = String(map.label ?? map.value ?? '')
      const value = String(map.value ?? map.send ?? map.label ?? '')
      const rawVotes = Number(map.votes ?? 0)
      return { label, value, votes: Number.isFinite(rawVotes) && rawVotes > 0 ? rawVotes : 0 }
    }
    const value = String(o)
    return { label: value, value, votes: 0 }
  }), [spec.options])

  const [storedVote, setStoredVote] = usePersistedState<string | number>(id, -1)
  const votedValue = typeof storedVote === 'number'
    ? options[storedVote]?.value ?? null
    : options.some(option => option.value === storedVote) ? storedVote : null
  const localVotePending = useRef(votedValue != null)
  const previousBaseVotes = useRef(new Map(options.map(option => [option.value, option.votes])))
  const [votes, setVotes] = useState<number[]>(() => options.map(option =>
    option.votes + (option.value === votedValue ? 1 : 0)
  ))

  useEffect(() => {
    if (typeof storedVote === 'number' && votedValue != null) setStoredVote(votedValue)
  }, [setStoredVote, storedVote, votedValue])

  useEffect(() => {
    if (votedValue != null && localVotePending.current) {
      const oldBase = previousBaseVotes.current.get(votedValue)
      const newBase = options.find(option => option.value === votedValue)?.votes
      if (oldBase != null && newBase != null && newBase > oldBase) {
        localVotePending.current = false
      }
    }
    setVotes(options.map(option =>
      option.votes + (localVotePending.current && option.value === votedValue ? 1 : 0)
    ))
    previousBaseVotes.current = new Map(options.map(option => [option.value, option.votes]))
  }, [options, votedValue])

  const handleVote = (i: number) => {
    if (votedValue != null) return
    const newVotes = votes.map((v, idx) => idx === i ? v + 1 : v)
    localVotePending.current = true
    setVotes(newVotes)
    setStoredVote(options[i].value)
    onSend(options[i].value)
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
      {options.map((option, i) => {
        const pct = votedValue != null ? votes[i] / total : 0
        const isVoted = option.value === votedValue
        return (
          <Pressable
            key={option.value}
            onPress={() => handleVote(i)}
            disabled={!enabled || votedValue != null}
            aria-pressed={isVoted}
            style={{
              position: 'relative',
              display: 'block',
              width: '100%',
              height: '40px',
              borderRadius: 'var(--ethereal-radius-sm, 6px)',
              backgroundColor: 'color-mix(in srgb, var(--ethereal-surface) 50%, transparent)',
              border: '1px solid var(--ethereal-hairline)',
              overflow: 'hidden',
            }}
          >
            {/* Fill bar */}
            {votedValue != null && (
              <span aria-hidden="true" style={{
                position: 'absolute',
                top: 0,
                left: 0,
                display: 'block',
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
            <span style={{
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
                {option.label}
              </span>
              {votedValue != null && (
                <span style={{
                  fontSize: '0.8125rem',
                  color: 'var(--ethereal-text-secondary, var(--ethereal-text-primary))',
                }}>
                  {Math.round(pct * 100)}%
                </span>
              )}
            </span>
          </Pressable>
        )
      })}
    </div>
  )
}
