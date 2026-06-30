import { describe, it, expect, vi } from 'vitest'
import { AguiEventProcessor, stateSnapshotToSpec, stateSnapshotToWidgetState } from '../src/transport.js'
import { EventType } from '@ag-ui/core'

describe('AguiEventProcessor', () => {
  it('RUN_STARTED sets isRunning=true', () => {
    const proc = new AguiEventProcessor()
    proc.processEvent({ type: EventType.RUN_STARTED, threadId: 't', runId: 'r' } as any)
    expect(proc.isRunning).toBe(true)
    expect(proc.errorMessage).toBeNull()
  })
  it('RUN_FINISHED clears running state', () => {
    const proc = new AguiEventProcessor()
    proc.processEvent({ type: EventType.RUN_STARTED, threadId: 't', runId: 'r' } as any)
    proc.processEvent({ type: EventType.RUN_FINISHED, threadId: 't', runId: 'r' } as any)
    expect(proc.isRunning).toBe(false)
    expect(proc.streamingText).toBeNull()
  })
  it('RUN_ERROR sets errorMessage', () => {
    const proc = new AguiEventProcessor()
    proc.processEvent({ type: EventType.RUN_ERROR, message: 'oops' } as any)
    expect(proc.isRunning).toBe(false)
    expect(proc.errorMessage).toBe('oops')
  })
  it('STATE_SNAPSHOT sets uiSpec and widgetState', () => {
    const proc = new AguiEventProcessor()
    proc.processEvent({
      type: EventType.STATE_SNAPSHOT,
      snapshot: {
        ui: { type: 'choices', options: ['A', 'B'] },
        widgets: { toggle1: true },
      },
    } as any)
    expect(proc.uiSpec).toEqual({ type: 'choices', options: ['A', 'B'] })
    expect(proc.widgetState).toEqual({ toggle1: true })
  })
  it('STATE_DELTA applies RFC-6902 patch to uiSpec', () => {
    const proc = new AguiEventProcessor()
    proc.uiSpec = { type: 'choices', options: ['A', 'B'] }
    proc.processEvent({
      type: EventType.STATE_DELTA,
      delta: [{ op: 'replace', path: '/options/0', value: 'C' }],
    } as any)
    expect((proc.uiSpec as any).options).toEqual(['C', 'B'])
  })
  it('TEXT_MESSAGE_CONTENT accumulates streamingText', () => {
    const proc = new AguiEventProcessor()
    proc.processEvent({ type: EventType.TEXT_MESSAGE_START, messageId: 'm1', role: 'assistant' } as any)
    proc.processEvent({ type: EventType.TEXT_MESSAGE_CONTENT, messageId: 'm1', delta: 'Hello' } as any)
    proc.processEvent({ type: EventType.TEXT_MESSAGE_CONTENT, messageId: 'm1', delta: ' world' } as any)
    expect(proc.streamingText).toBe('Hello world')
  })
  it('TEXT_MESSAGE_END finalizes message + clears streamingText', () => {
    const proc = new AguiEventProcessor()
    proc.processEvent({ type: EventType.TEXT_MESSAGE_START, messageId: 'm1', role: 'assistant' } as any)
    proc.processEvent({ type: EventType.TEXT_MESSAGE_CONTENT, messageId: 'm1', delta: 'Hi' } as any)
    proc.processEvent({ type: EventType.TEXT_MESSAGE_END, messageId: 'm1' } as any)
    expect(proc.streamingText).toBeNull()
    expect(proc.messages).toHaveLength(1)
    expect((proc.messages[0] as any).content).toBe('Hi')
  })
  it('listeners notified on state change', () => {
    const proc = new AguiEventProcessor()
    const fn = vi.fn()
    proc.addListener(fn)
    proc.processEvent({ type: EventType.RUN_STARTED, threadId: 't', runId: 'r' } as any)
    expect(fn).toHaveBeenCalledTimes(1)
    proc.removeListener(fn)
    proc.processEvent({ type: EventType.RUN_FINISHED, threadId: 't', runId: 'r' } as any)
    expect(fn).toHaveBeenCalledTimes(1) // no more after remove
  })
  it('unknown event types are ignored gracefully', () => {
    const proc = new AguiEventProcessor()
    expect(() => proc.processEvent({ type: 'SOME_FUTURE_EVENT' } as any)).not.toThrow()
  })
})

describe('stateSnapshotToSpec', () => {
  it('returns ui key from snapshot', () => {
    const spec = stateSnapshotToSpec({ type: EventType.STATE_SNAPSHOT, snapshot: { ui: { type: 'choices' } } } as any)
    expect(spec).toEqual({ type: 'choices' })
  })
  it('returns null when no ui key', () => {
    const spec = stateSnapshotToSpec({ type: EventType.STATE_SNAPSHOT, snapshot: {} } as any)
    expect(spec).toBeNull()
  })
})
