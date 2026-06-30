import { describe, it, expect } from 'vitest'
import { applyJsonPatch } from '../src/json_patch.js'

describe('applyJsonPatch', () => {
  it('add op', () => {
    const result = applyJsonPatch({ a: 1 }, [{ op: 'add', path: '/b', value: 2 }])
    expect(result).toEqual({ a: 1, b: 2 })
  })
  it('replace op on object', () => {
    const result = applyJsonPatch({ type: 'choices', options: ['A', 'B'] }, [
      { op: 'replace', path: '/options/0', value: 'C' },
    ])
    expect(result).toEqual({ type: 'choices', options: ['C', 'B'] })
  })
  it('replace on list index overwrites, not inserts', () => {
    const doc = { items: ['X', 'Y', 'Z'] }
    const result = applyJsonPatch(doc, [{ op: 'replace', path: '/items/1', value: 'NEW' }]) as any
    expect(result.items).toEqual(['X', 'NEW', 'Z'])
    expect(result.items).toHaveLength(3)  // not 4!
  })
  it('remove op', () => {
    const result = applyJsonPatch({ a: 1, b: 2 }, [{ op: 'remove', path: '/a' }])
    expect(result).toEqual({ b: 2 })
  })
  it('does not mutate input', () => {
    const original = { a: 1 }
    applyJsonPatch(original, [{ op: 'add', path: '/b', value: 2 }])
    expect(original).toEqual({ a: 1 })
  })
  it('skips bad ops tolerantly', () => {
    const doc = { a: 1 }
    const result = applyJsonPatch(doc, [
      { op: 'remove', path: '/nonexistent' },
      { op: 'add', path: '/b', value: 2 },
    ])
    expect((result as any).b).toBe(2)
  })
})
