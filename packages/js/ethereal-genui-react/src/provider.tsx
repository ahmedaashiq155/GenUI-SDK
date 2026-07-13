import React, {
  createContext, useContext, useMemo, useRef,
  useSyncExternalStore, useState, useCallback,
} from 'react'
import { GenUiStore, StorageAdapter } from './store.js'
import type { GenUiMessageInput } from './multimodal.js'

/** Actions available to the UI. */
export interface GenUiActions {
  sendMessage: (text: string) => void
  sendInput?: (input: GenUiMessageInput) => void | Promise<void>
  setAccent?: ((color: string | null) => void) | undefined
  setShortcuts?: ((items: string[] | null) => void) | undefined
  openArtifact?: ((artifact: Record<string, unknown> | null) => void) | undefined
  enabled: boolean
}

interface GenUiContextValue {
  store: GenUiStore
  actions: GenUiActions
}

const GenUiContext = createContext<GenUiContextValue | null>(null)

export interface GenUiProviderProps {
  children: React.ReactNode
  actions: GenUiActions
  storageKey?: string
  storage?: StorageAdapter
}

export function GenUiProvider({ children, actions, storageKey, storage }: GenUiProviderProps) {
  const storeRef = useRef<GenUiStore | null>(null)
  if (!storeRef.current) {
    storeRef.current = new GenUiStore({ storageKey, storage })
  }
  const value = useMemo(
    () => ({ store: storeRef.current!, actions }),
    // actions identity assumed stable (caller memoizes); store is stable
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [actions]
  )
  return <GenUiContext.Provider value={value}>{children}</GenUiContext.Provider>
}

/** Access the raw store (for advanced use). */
export function useGenUiStore(): GenUiStore {
  const ctx = useContext(GenUiContext)
  if (!ctx) throw new Error('useGenUiStore must be inside GenUiProvider')
  return ctx.store
}

/** Per-id value subscription. Only re-renders when this specific id changes. */
export function useGenUiValue(id: string): unknown {
  const store = useGenUiStore()
  return useSyncExternalStore(
    store.subscribe,
    () => store.getValue(id),
    () => undefined, // server snapshot
  )
}

/** Access GenUiActions. */
export function useGenUiActions(): GenUiActions {
  const ctx = useContext(GenUiContext)
  if (!ctx) throw new Error('useGenUiActions must be inside GenUiProvider')
  return ctx.actions
}

/**
 * Returns the store if inside a GenUiProvider, null otherwise.
 * Use this in renderers so they work with OR without a provider.
 */
export function useOptionalGenUiStore(): GenUiStore | null {
  const ctx = useContext(GenUiContext)
  return ctx?.store ?? null
}

/**
 * Returns GenUiActions if inside a GenUiProvider, null otherwise.
 * Use in directive renderers so they work with OR without a provider.
 */
export function useOptionalGenUiActions(): GenUiActions | null {
  const ctx = useContext(GenUiContext)
  return ctx?.actions ?? null
}

/**
 * State hook that mirrors Dart's GenUiPersistedState mixin.
 * If `id` is set and a GenUiProvider is present, persists value to the store.
 * If no id or no provider, behaves as plain local state.
 */
export function usePersistedState<T>(
  id: string | undefined,
  defaultValue: T
): [T, (v: T) => void] {
  const store = useOptionalGenUiStore()
  const [value, setLocal] = useState<T>(() => {
    if (!id || !store) return defaultValue
    const stored = store.getValue(id)
    return stored !== undefined ? (stored as T) : defaultValue
  })
  const setValue = useCallback(
    (v: T) => {
      setLocal(v)
      if (id && store) store.setValue(id, v)
    },
    [id, store]
  )
  return [value, setValue]
}
