import { describe, it, expect, vi } from 'vitest'
import { GenUiStore } from '../src/store.js'

describe('GenUiStore', () => {
  it('setValue + getValue', () => {
    const store = new GenUiStore()
    store.setValue('myId', 42)
    expect(store.getValue('myId')).toBe(42)
  })
  it('merge sets multiple keys', () => {
    const store = new GenUiStore()
    store.merge({ a: 1, b: 2 })
    expect(store.getValue('a')).toBe(1)
    expect(store.getValue('b')).toBe(2)
  })
  it('subscribe fires on setValue', () => {
    const store = new GenUiStore()
    const listener = vi.fn()
    const unsub = store.subscribe(listener)
    store.setValue('x', 'hello')
    expect(listener).toHaveBeenCalledTimes(1)
    unsub()
    store.setValue('x', 'world')
    expect(listener).toHaveBeenCalledTimes(1) // no more calls after unsub
  })
  it('StorageAdapter integration', () => {
    const mem: Record<string, string> = {}
    const adapter = {
      getItem: (k: string) => mem[k] ?? null,
      setItem: (k: string, v: string) => { mem[k] = v },
      removeItem: (k: string) => { delete mem[k] },
    }
    const store1 = new GenUiStore({ storageKey: 'test', storage: adapter })
    store1.setValue('color', 'blue')
    // New store loads from same adapter
    const store2 = new GenUiStore({ storageKey: 'test', storage: adapter })
    expect(store2.getValue('color')).toBe('blue')
  })
  it('clear removes all values', () => {
    const store = new GenUiStore()
    store.setValue('a', 1)
    store.clear()
    expect(store.getValue('a')).toBeUndefined()
  })
})
