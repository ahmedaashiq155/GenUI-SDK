/**
 * StorageAdapter — pluggable persistence backend.
 * Default: in-memory (ephemeral). Swap for sessionStorage/localStorage to
 * survive navigation/refresh.
 */
export interface StorageAdapter {
  getItem(key: string): string | null
  setItem(key: string, value: string): void
  removeItem(key: string): void
}

/**
 * GenUiStore — useSyncExternalStore-compatible external store.
 *
 * Flat id-keyed map. Per-id subscription granularity: components reading
 * different ids don't cross-render — useSyncExternalStore compares snapshots
 * with Object.is, so only components whose specific id changed re-render.
 */
export class GenUiStore {
  private _state: Map<string, unknown> = new Map()
  private _listeners: Set<() => void> = new Set()
  private _storageKey: string
  private _storage?: StorageAdapter

  constructor(opts?: { storageKey?: string; storage?: StorageAdapter }) {
    this._storageKey = opts?.storageKey ?? 'ethereal_genui_state'
    this._storage = opts?.storage
    if (this._storage) this._loadFromStorage()
  }

  /** Subscribe to any state change. Returns unsubscribe function. */
  subscribe = (listener: () => void): (() => void) => {
    this._listeners.add(listener)
    return () => this._listeners.delete(listener)
  }

  /** Returns current value for a single id (use inside useSyncExternalStore getSnapshot). */
  getValue = (id: string): unknown => {
    return this._state.get(id)
  }

  /** Returns a stable-reference snapshot of the full state map (for full reads). */
  getSnapshot = (): ReadonlyMap<string, unknown> => {
    return this._state
  }

  setValue(id: string, value: unknown): void {
    this._state.set(id, value)
    this._persistToStorage()
    this._notify()
  }

  merge(patch: Record<string, unknown>): void {
    for (const [k, v] of Object.entries(patch)) {
      this._state.set(k, v)
    }
    this._persistToStorage()
    this._notify()
  }

  clear(): void {
    this._state.clear()
    this._storage?.removeItem(this._storageKey)
    this._notify()
  }

  private _notify(): void {
    this._listeners.forEach(l => l())
  }

  private _persistToStorage(): void {
    if (!this._storage) return
    const obj: Record<string, unknown> = {}
    this._state.forEach((v, k) => { obj[k] = v })
    this._storage.setItem(this._storageKey, JSON.stringify(obj))
  }

  private _loadFromStorage(): void {
    if (!this._storage) return
    try {
      const raw = this._storage.getItem(this._storageKey)
      if (!raw) return
      const obj = JSON.parse(raw) as Record<string, unknown>
      for (const [k, v] of Object.entries(obj)) {
        this._state.set(k, v)
      }
    } catch {
      // corrupt storage — start fresh
    }
  }
}
