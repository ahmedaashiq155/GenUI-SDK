import { useCallback, useMemo, useSyncExternalStore } from 'react'
import { parseSegments, tryParsePartialJson, type MessageSegment } from '@ethereal/genui-core'
import type { AguiEventProcessor } from '../transport.js'

export type RenderableSegment =
  | { kind: 'text'; markdown: string }
  | { kind: 'code'; language: string; code: string; closed: boolean }
  | { kind: 'ui-ready'; spec: Record<string, unknown>; closed: boolean }
  | { kind: 'ui-preparing' }
  | { kind: 'ui-error'; raw: string }

export interface UseGenUiStreamResult {
  segments: RenderableSegment[]
  isStreaming: boolean
  /** Completed processor messages, normalized and pre-parsed for rendering. */
  completedMessages: CompletedGenUiMessage[]
}

export interface CompletedGenUiMessage {
  id?: string
  role?: string
  content: string
  segments: RenderableSegment[]
  /** The untouched AG-UI message for hosts that need provider-specific data. */
  raw: unknown
}

/**
 * Streaming-tolerant chat rendering hook — React parity for Dart's GenUiChat.
 * Subscribes to `processor`'s streamingText, splits it into text/code/ui
 * segments via parseSegments, and tolerant-parses each ui segment so it can
 * be handed straight to <GenUiBlock spec={...} onSend={...} />.
 *
 * Pass the SAME AguiEventProcessor instance you feed events into via
 * processor.processEvent(...) in your AG-UI run loop.
 *
 * Consumer usage:
 * ```tsx
 * const { segments, completedMessages, isStreaming } = useGenUiStream(processor)
 * segments.map((seg, i) => {
 *   switch (seg.kind) {
 *     case 'text': return <Markdown key={i}>{seg.markdown}</Markdown>
 *     case 'ui-ready': return <GenUiBlock key={i} spec={seg.spec} onSend={onSend} enabled={!isStreaming} />
 *     case 'ui-preparing': return <GenUiPlaceholder key={i} />
 *     case 'ui-error': return <GenUiBlockError key={i} />
 *     // ...
 *   }
 * })
 * ```
 */
export function useGenUiStream(processor: AguiEventProcessor): UseGenUiStreamResult {
  const subscribe = useCallback((cb: () => void) => {
    processor.addListener(cb)
    return () => processor.removeListener(cb)
  }, [processor])

  const text = useSyncExternalStore(
    subscribe,
    () => processor.streamingText,
    () => null,
  )
  const isRunning = useSyncExternalStore(
    subscribe,
    () => processor.isRunning,
    () => false,
  )
  const messages = useSyncExternalStore(
    subscribe,
    () => processor.messages,
    () => [] as unknown[],
  )

  const completedMessages = useMemo<CompletedGenUiMessage[]>(() =>
    messages.flatMap((raw) => {
      if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) return []
      const message = raw as Record<string, unknown>
      if (typeof message.content !== 'string') return []
      return [{
        id: typeof message.id === 'string' ? message.id : undefined,
        role: typeof message.role === 'string' ? message.role : undefined,
        content: message.content,
        segments: parseSegments(message.content).map(toRenderable),
        raw,
      }]
    }), [messages])

  const segments = useMemo<RenderableSegment[]>(() => {
    if (text !== null) return parseSegments(text).map(toRenderable)
    for (let i = completedMessages.length - 1; i >= 0; i--) {
      if (completedMessages[i].role === 'assistant') {
        return completedMessages[i].segments
      }
    }
    return []
  }, [completedMessages, text])

  return {
    segments,
    isStreaming: isRunning && text !== null,
    completedMessages,
  }
}

function toRenderable(seg: MessageSegment): RenderableSegment {
  switch (seg.kind) {
    case 'text':
      return { kind: 'text', markdown: seg.markdown }
    case 'code':
      return { kind: 'code', language: seg.language, code: seg.code, closed: seg.closed }
    case 'ui': {
      const parsed = tryParsePartialJson(seg.json)
      if (parsed !== null) return { kind: 'ui-ready', spec: parsed, closed: seg.closed }
      return seg.closed ? { kind: 'ui-error', raw: seg.json } : { kind: 'ui-preparing' }
    }
  }
}
