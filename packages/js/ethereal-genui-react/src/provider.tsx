import React, {
  createContext, useContext, useMemo, useRef,
  useSyncExternalStore,
} from 'react'
import { GenUiStore, StorageAdapter } from './store.js'

/** Actions available to the UI. */
export interface GenUiActions {
  sendMessage: (text: string) => void
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
