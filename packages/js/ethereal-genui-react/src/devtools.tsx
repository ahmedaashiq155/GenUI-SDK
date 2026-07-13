import React, { createContext, useContext, useSyncExternalStore, useState } from 'react'

export type GenUiDebugEventType = 'render' | 'dispatch' | 'validation' | 'error' | 'patch' | 'input'

export interface GenUiDebugEvent {
  type: GenUiDebugEventType
  timestamp: string
  blockType?: string
  message?: string
  data?: Readonly<Record<string, unknown>>
}

export class GenUiDebugController {
  readonly capacity: number
  readonly capturePayloads: boolean
  private eventsValue: readonly GenUiDebugEvent[] = []
  private listeners = new Set<() => void>()

  constructor(options: { capacity?: number; capturePayloads?: boolean } = {}) {
    this.capacity = options.capacity ?? 250
    this.capturePayloads = options.capturePayloads ?? false
  }

  get events(): readonly GenUiDebugEvent[] { return this.eventsValue }
  subscribe = (listener: () => void) => {
    this.listeners.add(listener)
    return () => this.listeners.delete(listener)
  }

  record(event: Omit<GenUiDebugEvent, 'timestamp'>) {
    if (this.capacity <= 0) return
    const safe: GenUiDebugEvent = {
      type: event.type,
      timestamp: new Date().toISOString(),
      ...(event.blockType ? { blockType: event.blockType } : {}),
      ...(this.capturePayloads && event.message ? { message: event.message } : {}),
      ...(this.capturePayloads && event.data ? { data: event.data } : {}),
    }
    this.eventsValue = [...this.eventsValue, safe].slice(-this.capacity)
    this.listeners.forEach((listener) => listener())
  }

  clear() {
    this.eventsValue = []
    this.listeners.forEach((listener) => listener())
  }

  exportJson(): string { return JSON.stringify(this.eventsValue) }
}

const GenUiDebugContext = createContext<GenUiDebugController | null>(null)

export function useOptionalGenUiDebug(): GenUiDebugController | null {
  return useContext(GenUiDebugContext)
}

export interface GenUiDevToolsOverlayProps {
  controller: GenUiDebugController
  children: React.ReactNode
  initiallyOpen?: boolean
}

/** Opt-in in-app inspector; payload capture is off unless explicitly enabled. */
export function GenUiDevToolsOverlay({ controller, children, initiallyOpen = false }: GenUiDevToolsOverlayProps) {
  const [open, setOpen] = useState(initiallyOpen)
  const events = useSyncExternalStore(controller.subscribe, () => controller.events, () => [])
  return (
    <GenUiDebugContext.Provider value={controller}>
      <div style={{ position: 'relative' }}>
        {children}
        <div style={{ position: 'fixed', insetInlineEnd: 12, bottom: 12, zIndex: 2147483647 }}>
          {open && (
            <section
              aria-label="GenUI Inspector"
              style={{ width: 340, height: 360, overflow: 'auto', background: '#111827', color: '#f9fafb', borderRadius: 12, padding: 12 }}
            >
              <header style={{ display: 'flex', justifyContent: 'space-between' }}>
                <strong>GenUI Inspector</strong>
                <button type="button" onClick={() => controller.clear()}>Clear</button>
              </header>
              <ol>
                {[...events].reverse().map((event, index) => (
                  <li key={`${event.timestamp}-${index}`}>
                    {event.type} · {event.blockType ?? event.message ?? 'GenUI'}
                  </li>
                ))}
              </ol>
            </section>
          )}
          <button type="button" aria-label={open ? 'Close GenUI Inspector' : 'Open GenUI Inspector'} onClick={() => setOpen(!open)}>
            {open ? '×' : '⌘'}
          </button>
        </div>
      </div>
    </GenUiDebugContext.Provider>
  )
}
