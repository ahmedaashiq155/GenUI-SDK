import React, { useRef, useState } from 'react'
import { useOptionalGenUiActions, type GenUiActions } from '../provider.js'
import type { GenUiAttachment, GenUiAttachmentPicker } from '../multimodal.js'
import type { useGenUiVoice } from '../voice.js'
import { GenUiVoiceButton } from '../voice.js'
import { Pressable } from './Pressable.js'

export interface GenUiComposerProps {
  actions?: GenUiActions
  pickAttachments?: GenUiAttachmentPicker
  voice?: ReturnType<typeof useGenUiVoice>
  placeholder?: string
  maxAttachments?: number
  className?: string
  style?: React.CSSProperties
}

/** Dependency-free multimodal composer with host-injected media and voice. */
export function GenUiComposer({
  actions: actionsProp,
  pickAttachments,
  voice,
  placeholder = 'Message…',
  maxAttachments = 8,
  className,
  style,
}: GenUiComposerProps) {
  const providerActions = useOptionalGenUiActions()
  const actions = actionsProp ?? providerActions
  const [text, setText] = useState('')
  const [attachments, setAttachments] = useState<GenUiAttachment[]>([])
  const [sending, setSending] = useState(false)
  const sendingRef = useRef(false)
  const limit = Math.min(100, Math.max(0, maxAttachments))
  const enabled = actions?.enabled ?? false
  const canSend = enabled && !sending &&
    (text.trim() !== '' || attachments.length > 0) &&
    (attachments.length === 0 || actions?.sendInput !== undefined)

  async function pick() {
    if (!pickAttachments || !actions?.sendInput) return
    const picked = await pickAttachments()
    setAttachments((current) => [...current, ...picked].slice(0, limit))
  }

  async function send() {
    if (!canSend || !actions || sendingRef.current) return
    sendingRef.current = true
    setSending(true)
    try {
      const input = { text: text.trim(), attachments }
      if (attachments.length > 0) await actions.sendInput?.(input)
      else actions.sendMessage(input.text)
      setText('')
      setAttachments([])
    } finally {
      sendingRef.current = false
      setSending(false)
    }
  }

  return (
    <div className={className} style={{ display: 'grid', gap: 'var(--ethereal-space-sm)', ...style }}>
      {attachments.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 'var(--ethereal-space-sm)' }}>
          {attachments.map((attachment) => (
            <span
              key={attachment.id}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: 'var(--ethereal-space-xs)',
                padding: 'var(--ethereal-space-xs) var(--ethereal-space-sm)',
                borderRadius: 'var(--ethereal-radius-pill)',
                background: 'var(--ethereal-surface)',
                color: 'var(--ethereal-text-primary)',
              }}
            >
              {attachment.name}
              <Pressable
                aria-label={`Remove ${attachment.name}`}
                disabled={!enabled || sending}
                onPress={() => setAttachments((items) => items.filter((item) => item.id !== attachment.id))}
              >
                <span aria-hidden="true">×</span>
              </Pressable>
            </span>
          ))}
        </div>
      )}
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 'var(--ethereal-space-sm)' }}>
        {pickAttachments && (
          <Pressable
            aria-label="Add attachment"
            disabled={!enabled || !actions?.sendInput || attachments.length >= limit}
            onPress={() => void pick()}
          >
            <span aria-hidden="true">＋</span>
          </Pressable>
        )}
        <textarea
          aria-label={placeholder}
          value={text}
          disabled={!enabled || sending}
          rows={1}
          placeholder={placeholder}
          onChange={(event) => setText(event.target.value)}
          onKeyDown={(event) => {
            if (event.key === 'Enter' && !event.shiftKey) {
              event.preventDefault()
              void send()
            }
          }}
          style={{ flex: 1, resize: 'vertical', minHeight: 44 }}
        />
        {voice && <GenUiVoiceButton voice={voice} onTranscript={setText} />}
        <Pressable aria-label="Send" disabled={!canSend} onPress={() => void send()}>
          <span aria-hidden="true">➤</span>
        </Pressable>
      </div>
    </div>
  )
}
