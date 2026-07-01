import { AGUIEvent, EventType, RunAgentInput, StateSnapshotEvent, StateDeltaEvent } from '@ag-ui/core'
import { applyJsonPatch } from '@ethereal/genui-core'

/**
 * Abstract transport interface. Users subclass this to connect any AG-UI backend.
 * sendEvent default is a no-op — override to push state back to the agent.
 */
export abstract class EtherealAguiTransport {
  abstract run(input: RunAgentInput): AsyncIterable<AGUIEvent>
  async sendEvent(event: AGUIEvent): Promise<void> {}
}

/**
 * Processes a stream of AG-UI events into Ethereal state.
 * Pure class, no React. Mirrors Dart's AguiEventProcessor.
 */
export class AguiEventProcessor {
  uiSpec: Record<string, unknown> = {}
  widgetState: Record<string, unknown> = {}
  streamingText: string | null = null
  isRunning: boolean = false
  errorMessage: string | null = null
  messages: unknown[] = []

  private _listeners: Set<() => void> = new Set()
  private _currentMessageId: string | null = null
  private _currentMessageBuffer: string = ''

  addListener(fn: () => void): void { this._listeners.add(fn) }
  removeListener(fn: () => void): void { this._listeners.delete(fn) }
  private _notify(): void { this._listeners.forEach(l => l()) }

  /** Process one AG-UI event. Returns true if state changed. */
  processEvent(event: AGUIEvent): boolean {
    switch (event.type) {
      case EventType.RUN_STARTED:
        this.isRunning = true
        this.errorMessage = null
        this._notify()
        return true

      case EventType.RUN_FINISHED:
        this.isRunning = false
        this.streamingText = null
        this._notify()
        return true

      case EventType.RUN_ERROR:
        this.isRunning = false
        this.errorMessage = (event as any).message ?? 'Unknown error'
        this._notify()
        return true

      case EventType.STATE_SNAPSHOT: {
        const e = event as StateSnapshotEvent
        const snap = e.snapshot ?? {}
        if (snap.ui !== undefined) {
          this.uiSpec = snap.ui as Record<string, unknown>
        }
        if (snap.widgets !== undefined) {
          this.widgetState = snap.widgets as Record<string, unknown>
        }
        this._notify()
        return true
      }

      case EventType.STATE_DELTA: {
        const e = event as StateDeltaEvent
        const ops = Array.isArray(e.delta) ? e.delta : []
        this.uiSpec = applyJsonPatch(this.uiSpec, ops) as Record<string, unknown> ?? {}
        this._notify()
        return true
      }

      case EventType.TEXT_MESSAGE_START:
        this._currentMessageId = (event as any).messageId ?? null
        this._currentMessageBuffer = ''
        this.streamingText = ''
        this._notify()
        return true

      case EventType.TEXT_MESSAGE_CONTENT:
        this._currentMessageBuffer += (event as any).delta ?? ''
        this.streamingText = this._currentMessageBuffer
        this._notify()
        return true

      case EventType.TEXT_MESSAGE_END:
        if (this._currentMessageBuffer) {
          this.messages = [
            ...this.messages,
            { role: 'assistant', content: this._currentMessageBuffer, id: this._currentMessageId },
          ]
        }
        this.streamingText = null
        this._currentMessageId = null
        this._currentMessageBuffer = ''
        this._notify()
        return true

      case EventType.MESSAGES_SNAPSHOT:
        this.messages = (event as any).messages ?? []
        this._notify()
        return true

      case EventType.STEP_STARTED:
      case EventType.STEP_FINISHED:
      case EventType.TOOL_CALL_START:
      case EventType.TOOL_CALL_ARGS:
      case EventType.TOOL_CALL_END:
      case EventType.RAW:
      case EventType.CUSTOM:
        // Accept and ignore gracefully
        return false

      default:
        // Any new event types (ACTIVITY_*, REASONING_*, etc.) — ignore
        return false
    }
  }
}

/**
 * Utility: extract stateSnapshotToSpec (public API, mirrors Dart).
 * Returns the GenUI spec from a STATE_SNAPSHOT event, or null if no 'ui' key.
 */
export function stateSnapshotToSpec(event: StateSnapshotEvent): Record<string, unknown> | null {
  const snap = event.snapshot ?? {}
  return snap.ui !== undefined ? (snap.ui as Record<string, unknown>) : null
}

/**
 * Utility: extract widget state from a STATE_SNAPSHOT event.
 */
export function stateSnapshotToWidgetState(event: StateSnapshotEvent): Record<string, unknown> {
  const snap = event.snapshot ?? {}
  return (snap.widgets ?? {}) as Record<string, unknown>
}
