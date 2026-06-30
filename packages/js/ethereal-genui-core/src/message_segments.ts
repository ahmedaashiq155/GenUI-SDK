/// Splits an assistant message into ordered segments so fenced blocks render as
/// sibling widgets. Streaming-tolerant: a trailing fence that hasn't closed yet
/// yields a segment with closed === false.

export type MessageSegment = TextSegment | CodeSegment | UiSegment

export interface TextSegment {
  readonly kind: 'text'
  readonly markdown: string
}

export interface CodeSegment {
  readonly kind: 'code'
  readonly language: string
  readonly code: string
  readonly closed: boolean
}

export interface UiSegment {
  readonly kind: 'ui'
  readonly json: string
  readonly closed: boolean
}

const _fenceOpen = /^\s*```(.*)$/
const _fenceClose = /^\s*```\s*$/

/// Parse content into text / code / ui segments. Streaming-tolerant: a
/// trailing fence that hasn't closed yet yields a segment with closed === false.
export function parseSegments(content: string): MessageSegment[] {
  const segments: MessageSegment[] = []
  const lines = content.split('\n')
  let textBuffer = ''

  function flushText(): void {
    const text = textBuffer
    textBuffer = ''
    // trimRight equivalent: remove trailing whitespace
    const trimmed = text.replace(/\s+$/, '')
    if (trimmed.trim().length > 0) {
      segments.push({ kind: 'text', markdown: trimmed })
    }
  }

  let i = 0
  while (i < lines.length) {
    const openMatch = _fenceOpen.exec(lines[i])
    if (openMatch !== null) {
      flushText()
      const lang = openMatch[1].trim()
      i++
      const body: string[] = []
      let closed = false
      while (i < lines.length) {
        if (_fenceClose.test(lines[i])) {
          closed = true
          i++
          break
        }
        body.push(lines[i])
        i++
      }
      const inner = body.join('\n')
      if (lang.toLowerCase() === 'ui') {
        segments.push({ kind: 'ui', json: inner, closed })
      } else {
        segments.push({ kind: 'code', language: lang, code: inner, closed })
      }
    } else {
      textBuffer += lines[i] + '\n'
      i++
    }
  }
  flushText()
  return segments
}
