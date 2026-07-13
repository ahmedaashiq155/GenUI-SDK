import { describe, it, expect } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { EventType } from '@ag-ui/core'
import { AguiEventProcessor } from '../src/transport.js'
import { useGenUiStream } from '../src/hooks/useGenUiStream.js'

function start(proc: AguiEventProcessor) {
  proc.processEvent({ type: EventType.RUN_STARTED, threadId: 't', runId: 'r' } as any)
  proc.processEvent({ type: EventType.TEXT_MESSAGE_START, messageId: 'm1', role: 'assistant' } as any)
}

function content(proc: AguiEventProcessor, delta: string) {
  proc.processEvent({ type: EventType.TEXT_MESSAGE_CONTENT, messageId: 'm1', delta } as any)
}

describe('useGenUiStream', () => {
  it('returns no segments before any streaming text has arrived', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    expect(result.current.segments).toEqual([])
    expect(result.current.isStreaming).toBe(false)
    expect(result.current.completedMessages).toEqual([])
  })

  it('produces a text segment for plain streamed content', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    act(() => {
      start(proc)
      content(proc, 'Hello world')
    })
    expect(result.current.segments).toEqual([{ kind: 'text', markdown: 'Hello world' }])
    expect(result.current.isStreaming).toBe(true)
  })

  it('produces ui-preparing for a still-open ui fence with no content yet', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    act(() => {
      start(proc)
      // The fence just opened — no JSON content at all yet, so tolerant
      // parsing returns null and the fence is still open (not closed).
      content(proc, '```ui\n')
    })
    expect(result.current.segments).toEqual([{ kind: 'ui-preparing' }])
    expect(result.current.isStreaming).toBe(true)
  })

  it('transitions ui-preparing -> ui-ready as more content streams in and the fence closes', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    act(() => {
      start(proc)
      content(proc, '```ui\n')
    })
    expect(result.current.segments).toEqual([{ kind: 'ui-preparing' }])

    act(() => {
      content(proc, '{"type":"card","title":"Users"}\n```')
    })
    expect(result.current.segments).toEqual([
      { kind: 'ui-ready', spec: { type: 'card', title: 'Users' }, closed: true },
    ])
  })

  it('produces ui-ready with closed:false for a tolerant-parseable but still-open fence', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    act(() => {
      start(proc)
      // Unclosed string value — tolerant parser can already produce a spec
      // even though the fence itself hasn't closed yet.
      content(proc, '```ui\n{"type":"card","title":"Partial')
    })
    expect(result.current.segments).toEqual([
      { kind: 'ui-ready', spec: { type: 'card', title: 'Partial' }, closed: false },
    ])
  })

  it('produces ui-error for a genuinely malformed but closed fence', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    act(() => {
      start(proc)
      content(proc, '```ui\nnot json at all {{{\n```')
    })
    expect(result.current.segments).toEqual([{ kind: 'ui-error', raw: 'not json at all {{{' }])
  })

  it('retains completed segments and exposes completed messages after TEXT_MESSAGE_END', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    act(() => {
      start(proc)
      content(proc, 'Hello world')
    })
    expect(result.current.segments).toEqual([{ kind: 'text', markdown: 'Hello world' }])

    act(() => {
      proc.processEvent({ type: EventType.TEXT_MESSAGE_END, messageId: 'm1' } as any)
    })
    expect(result.current.segments).toEqual([{ kind: 'text', markdown: 'Hello world' }])
    expect(result.current.isStreaming).toBe(false)
    expect(result.current.completedMessages).toMatchObject([
      {
        id: 'm1',
        role: 'assistant',
        content: 'Hello world',
        segments: [{ kind: 'text', markdown: 'Hello world' }],
      },
    ])
  })

  it('normalizes MESSAGES_SNAPSHOT content and keeps raw message metadata', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    const raw = {
      id: 'a1',
      role: 'assistant',
      content: 'A card\n```ui\n{"type":"card","title":"Done"}\n```',
      providerMeta: { cached: true },
    }
    act(() => {
      proc.processEvent({ type: EventType.MESSAGES_SNAPSHOT, messages: [raw] } as any)
    })
    expect(result.current.completedMessages).toHaveLength(1)
    expect(result.current.completedMessages[0].raw).toBe(raw)
    expect(result.current.completedMessages[0].segments[1]).toEqual({
      kind: 'ui-ready',
      spec: { type: 'card', title: 'Done' },
      closed: true,
    })
    expect(result.current.segments).toEqual(result.current.completedMessages[0].segments)
  })

  it('mixes text and ui segments in order', () => {
    const proc = new AguiEventProcessor()
    const { result } = renderHook(() => useGenUiStream(proc))
    act(() => {
      start(proc)
      content(proc, 'Here you go:\n```ui\n{"type":"divider"}\n```\nDone.')
    })
    expect(result.current.segments).toEqual([
      { kind: 'text', markdown: 'Here you go:' },
      { kind: 'ui-ready', spec: { type: 'divider' }, closed: true },
      { kind: 'text', markdown: 'Done.' },
    ])
  })
})
