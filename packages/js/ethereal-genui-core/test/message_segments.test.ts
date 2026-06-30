import { describe, it, expect } from 'vitest'
import { parseSegments } from '../src/message_segments.js'

describe('parseSegments', () => {
  it('plain text → TextSegment', () => {
    const segs = parseSegments('Hello world')
    expect(segs).toHaveLength(1)
    expect(segs[0]).toEqual({ kind: 'text', markdown: 'Hello world' })
  })
  it('ui fence → UiSegment closed', () => {
    const content = 'Before\n```ui\n{"type":"choices"}\n```\nAfter'
    const segs = parseSegments(content)
    expect(segs).toHaveLength(3)
    expect(segs[1]).toEqual({ kind: 'ui', json: '{"type":"choices"}', closed: true })
  })
  it('code fence → CodeSegment', () => {
    const content = '```dart\nprint("hi");\n```'
    const segs = parseSegments(content)
    expect(segs).toHaveLength(1)
    expect(segs[0]).toEqual({ kind: 'code', language: 'dart', code: 'print("hi");', closed: true })
  })
  it('unclosed ui fence → closed: false', () => {
    const content = 'text\n```ui\n{"type":"choices"}'
    const segs = parseSegments(content)
    const ui = segs.find(s => s.kind === 'ui')
    expect(ui).toBeDefined()
    expect((ui as any).closed).toBe(false)
  })
  it('multiple segments in order', () => {
    const content = 'A\n```ui\n{}\n```\nB\n```python\ncode\n```\nC'
    const segs = parseSegments(content)
    expect(segs.map(s => s.kind)).toEqual(['text', 'ui', 'text', 'code', 'text'])
  })
})
