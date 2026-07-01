import { useMemo, useSyncExternalStore } from 'react'
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
 * const { segments } = useGenUiStream(processor)
 * segments.map((seg, i) => {
 *   switch (seg.kind) {
 *     case 'text': return <Markdown key={i}>{seg.markdown}</Markdown>
 *     case 'ui-ready': return <GenUiBlock key={i} spec={seg.spec} onSend={onSend} />
 *     case 'ui-preparing': return <GenUiPlaceholder key={i} />
 *     case 'ui-error': return <GenUiBlockError key={i} />
 *     // ...
 *   }
 * })
 * ```
 */
export function useGenUiStream(processor: AguiEventProcessor): UseGenUiStreamResult {
  const subscribe = (cb: () => void) => {
    processor.addListener(cb)
    return () => processor.removeListener(cb)
  }

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

  const segments = useMemo<RenderableSegment[]>(() => {
    if (text === null) return []
    return parseSegments(text).map(toRenderable)
  }, [text])

  return { segments, isStreaming: isRunning && text !== null }
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
