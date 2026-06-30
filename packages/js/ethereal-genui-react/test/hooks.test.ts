import { describe, it, expect } from 'vitest'
import { render, act } from '@testing-library/react'
import { GenUiStore } from '../src/store.js'
import { useOptionalGenUiStore, usePersistedState } from '../src/provider.js'

// We need React for JSX
import React from 'react'

describe('useOptionalGenUiStore', () => {
  it('returns null outside a provider', () => {
    let result: GenUiStore | null = undefined!
    function Test() {
      result = useOptionalGenUiStore()
      return null
    }
    render(React.createElement(Test))
    expect(result).toBeNull()
  })
})

describe('usePersistedState', () => {
  it('returns defaultValue when no provider and no id', () => {
    let val: number | undefined
    function Test() {
      const [v] = usePersistedState<number>(undefined, 42)
      val = v
      return null
    }
    render(React.createElement(Test))
    expect(val).toBe(42)
  })

  it('updates local state correctly', () => {
    const results: number[] = []
    let setter: ((v: number) => void) = () => {}

    function Test() {
      const [v, setV] = usePersistedState<number>(undefined, 0)
      results.push(v)
      setter = setV
      return null
    }
    const { rerender } = render(React.createElement(Test))
    act(() => { setter(5) })
    rerender(React.createElement(Test))
    expect(results[results.length - 1]).toBe(5)
  })
})
