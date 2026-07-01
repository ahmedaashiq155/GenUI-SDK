import { describe, it, expect } from 'vitest'
import { tryParsePartialJson, repairPartialJson } from '../src/json_stream_parser.js'

describe('tryParsePartialJson — worked examples', () => {
  it('simple unclosed object, no dangling anything — just close', () => {
    const input = '{"type":"card","title":"Users"'
    const repaired = '{"type":"card","title":"Users"}'
    expect(repairPartialJson(input)).toBe(repaired)
    expect(tryParsePartialJson(input)).toEqual({ type: 'card', title: 'Users' })
  })

  it('unclosed string mid-value — close it, KEEP partial content', () => {
    const input = '{"a":1,"b":"unclo'
    const repaired = '{"a":1,"b":"unclo"}'
    expect(repairPartialJson(input)).toBe(repaired)
    expect(tryParsePartialJson(input)).toEqual({ a: 1, b: 'unclo' })
  })

  it('nested: close inner string, inner object, array, outer object', () => {
    const input = '{"type":"card","items":[{"label":"a'
    const repaired = '{"type":"card","items":[{"label":"a"}]}'
    expect(repairPartialJson(input)).toBe(repaired)
    expect(tryParsePartialJson(input)).toEqual({
      type: 'card',
      items: [{ label: 'a' }],
    })
  })

  it('dangling colon with no value token at all — truncate and drop', () => {
    const input = '{"type":"card","title":'
    const repaired = '{"type":"card"}'
    expect(repairPartialJson(input)).toBe(repaired)
    expect(tryParsePartialJson(input)).toEqual({ type: 'card' })
  })

  it('dangling key with no colon yet — truncate and drop', () => {
    const input = '{"a":1,"key'
    const repaired = '{"a":1}'
    expect(repairPartialJson(input)).toBe(repaired)
    expect(tryParsePartialJson(input)).toEqual({ a: 1 })
  })

  it('trailing comma in an array with nothing after — strip then close', () => {
    const input = '{"type":"list","items":["a","b",'
    const repaired = '{"type":"list","items":["a","b"]}'
    expect(repairPartialJson(input)).toBe(repaired)
    expect(tryParsePartialJson(input)).toEqual({
      type: 'list',
      items: ['a', 'b'],
    })
  })

  it('plain unclosed object', () => {
    const input = '{"type":"card"'
    const repaired = '{"type":"card"}'
    expect(repairPartialJson(input)).toBe(repaired)
    expect(tryParsePartialJson(input)).toEqual({ type: 'card' })
  })

  it('unparseable even after repair attempt — returns null', () => {
    const input = 'not json at all {{{'
    expect(tryParsePartialJson(input)).toBeNull()
  })

  it('empty string — returns null immediately, no repair attempted', () => {
    expect(tryParsePartialJson('')).toBeNull()
    expect(tryParsePartialJson('   ')).toBeNull()
  })

  it('already-valid JSON — fast path, repair never runs', () => {
    const input = '{"a":1,"b":2}'
    expect(tryParsePartialJson(input)).toEqual({ a: 1, b: 2 })
  })

  it('top-level array is rejected even if repairable — GenUI specs are objects', () => {
    expect(tryParsePartialJson('[1,2,3')).toBeNull()
    expect(tryParsePartialJson('[1,2,3]')).toBeNull()
  })

  it('escaped backslash-quote inside an unclosed string is not mistaken for a real closing quote', () => {
    const input = '{"a":"line1\\nline2\\"quoted'
    const repaired = '{"a":"line1\\nline2\\"quoted"}'
    expect(repairPartialJson(input)).toBe(repaired)
    const result = tryParsePartialJson(input)
    expect(result).not.toBeNull()
    expect(result!.a).toBe('line1\nline2"quoted')
  })
})

describe('tryParsePartialJson — additional coverage', () => {
  it('deeply nested unclosed object at multiple levels', () => {
    const input =
      '{"type":"box","children":[{"type":"text","text":"hi"},{"type":"button","label":"Go'
    const result = tryParsePartialJson(input)
    expect(result).not.toBeNull()
    expect(result!.type).toBe('box')
    const children = result!.children as unknown[]
    expect(children.length).toBe(2)
    expect(children[0]).toEqual({ type: 'text', text: 'hi' })
    expect(children[1]).toEqual({ type: 'button', label: 'Go' })
  })

  it('non-object top-level JSON value returns null (only plain objects accepted)', () => {
    expect(tryParsePartialJson('"just a string"')).toBeNull()
    expect(tryParsePartialJson('42')).toBeNull()
  })

  it('whitespace is trimmed before parsing', () => {
    const input = '   {"a":1}   '
    expect(tryParsePartialJson(input)).toEqual({ a: 1 })
  })
})
