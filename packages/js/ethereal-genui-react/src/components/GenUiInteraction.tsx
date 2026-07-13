import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react'
import { useOptionalGenUiDebug } from '../devtools.js'

export interface GenUiInteractionValue {
  enabled: boolean
  dispatch: (message: string) => void
}

const GenUiInteractionContext = createContext<GenUiInteractionValue | null>(null)

export function useOptionalGenUiInteraction(): GenUiInteractionValue | null {
  return useContext(GenUiInteractionContext)
}

export function useGenUiInteractionEnabled(): boolean {
  return useOptionalGenUiInteraction()?.enabled ?? true
}

export interface GenUiInteractionBoundaryProps {
  children: React.ReactNode
  enabled: boolean
  onSend: (message: string) => void
}

/**
 * Owns one synchronous dispatch lock for an entire rendered spec tree. The ref
 * closes the same-frame double-click window; state exposes the pending affordance
 * to renderers. A completed host turn is signalled by enabled changing false→true.
 */
export function GenUiInteractionBoundary({
  children,
  enabled,
  onSend,
}: GenUiInteractionBoundaryProps) {
  const debug = useOptionalGenUiDebug()
  const dispatchedRef = useRef(false)
  const previousEnabledRef = useRef(enabled)
  const [dispatched, setDispatched] = useState(false)

  useEffect(() => {
    if (!previousEnabledRef.current && enabled) {
      dispatchedRef.current = false
      setDispatched(false)
    }
    previousEnabledRef.current = enabled
  }, [enabled])

  const dispatch = useCallback((message: string) => {
    if (!enabled || dispatchedRef.current) return
    dispatchedRef.current = true
    setDispatched(true)
    debug?.record({ type: 'dispatch', message })
    onSend(message)
  }, [debug, enabled, onSend])

  const value = useMemo<GenUiInteractionValue>(() => ({
    enabled: enabled && !dispatched,
    dispatch,
  }), [dispatch, dispatched, enabled])

  return (
    <GenUiInteractionContext.Provider value={value}>
      {children}
    </GenUiInteractionContext.Provider>
  )
}
