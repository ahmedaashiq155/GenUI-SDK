/**
 * Attempts to parse `raw` as a JSON object, tolerating a truncated/streaming
 * string. Tries a straight JSON.parse first; on failure, walks the string to
 * determine unclosed brackets/braces/quotes, repairs by injecting the minimal
 * closing tokens (or truncating a dangling key with no value token at all),
 * and retries. Returns null if truly unparseable even after repair, or if
 * the top-level result is not a JSON object.
 *
 * Single-pass, single-retry: never O(n^2) on long streamed specs. This is a
 * cross-language parity target — the repaired *string* produced here must
 * match the Dart implementation's `repairPartialJson` exactly (see
 * packages/dart/ethereal_genui_core/lib/src/json_stream_parser.dart).
 */
export function tryParsePartialJson(raw: string): Record<string, unknown> | null {
  const trimmed = raw.trim()
  if (trimmed.length === 0) return null

  // Fast path: already-complete JSON.
  try {
    const value: unknown = JSON.parse(trimmed)
    if (isPlainObject(value)) return value
  } catch {
    // Fall through to repair.
  }

  const repaired = repairPartialJson(trimmed)
  if (repaired === null) return null

  try {
    const value: unknown = JSON.parse(repaired)
    if (isPlainObject(value)) return value
  } catch {
    // Unparseable even after repair.
  }
  return null
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

/** One open `{` or `[` frame in the scan stack. */
interface Frame {
  /** The opening bracket character: `{` or `[`. */
  opener: '{' | '['
  /**
   * String offset immediately after the last syntactically complete
   * element/pair in this frame (right after the opening bracket if none
   * yet completed).
   */
  lastSafeIndex: number
  /** Object frames only: positioned right after a key string, no colon yet. */
  afterKey: boolean
  /** Object frames only: positioned right after a colon, no value token started yet. */
  afterColon: boolean
  /**
   * Has any value token started (but not necessarily finished) since the
   * last comma/opening bracket in this frame? Used to distinguish "bare
   * trailing comma" from "value in progress" at EOF.
   */
  valueStarted: boolean
}

function isWhitespace(c: string): boolean {
  return c === ' ' || c === '\t' || c === '\n' || c === '\r'
}

/**
 * Runs the single left-to-right repair scan on an already-trimmed,
 * non-empty `s` and returns the repaired JSON string (not yet parsed), or
 * `null` if no container-based repair applies (nothing was ever opened as
 * an object/array — this truly isn't JSON).
 *
 * Exported (not just internal) so tests can assert the repaired string
 * directly, matching the Dart parity table in the task brief.
 */
export function repairPartialJson(s: string): string | null {
  if (s.length === 0) return null

  const stack: Frame[] = []
  let inString = false
  let escaped = false
  // True once we've seen the opening quote of a string but not yet the
  // closing one when the scan ends (i.e. the string is unterminated).
  let stringUnterminated = false

  const len = s.length
  for (let i = 0; i < len; i++) {
    const c = s[i]

    if (inString) {
      if (escaped) {
        escaped = false
      } else if (c === '\\') {
        escaped = true
      } else if (c === '"') {
        inString = false
        stringUnterminated = false
        if (stack.length > 0) {
          const frame = stack[stack.length - 1]
          if (frame.opener === '{' && !frame.afterKey && !frame.afterColon) {
            // This string was a key.
            frame.afterKey = true
          } else {
            // This string was a value (object value or array element).
            frame.valueStarted = true
            if (frame.opener === '{') frame.afterColon = false
          }
        }
      }
      continue
    }

    switch (c) {
      case '"':
        inString = true
        stringUnterminated = true
        escaped = false
        break
      case '{':
      case '[':
        stack.push({
          opener: c,
          lastSafeIndex: i + 1,
          afterKey: false,
          afterColon: false,
          valueStarted: false,
        })
        break
      case '}':
      case ']':
        if (stack.length > 0) {
          stack.pop()
          if (stack.length > 0) {
            const parent = stack[stack.length - 1]
            parent.valueStarted = true
            if (parent.opener === '{') parent.afterColon = false
            parent.lastSafeIndex = i + 1
          }
        }
        break
      case ':':
        if (stack.length > 0 && stack[stack.length - 1].opener === '{') {
          stack[stack.length - 1].afterKey = false
          stack[stack.length - 1].afterColon = true
        }
        break
      case ',':
        if (stack.length > 0) {
          const frame = stack[stack.length - 1]
          // A comma after a completed value/element marks a new safe point;
          // reset per-slot flags so we can detect a bare trailing comma or a
          // dangling next key.
          frame.lastSafeIndex = i + 1
          frame.afterKey = false
          frame.afterColon = false
          frame.valueStarted = false
        }
        break
      default:
        // Whitespace or part of a bare token (number/true/false/null). Mark
        // the enclosing frame as having a value in progress so a lone comma
        // isn't mistaken for trailing when a scalar follows it.
        if (!isWhitespace(c) && stack.length > 0) {
          const frame = stack[stack.length - 1]
          if (!(frame.opener === '{' && frame.afterKey)) {
            frame.valueStarted = true
            if (frame.opener === '{') frame.afterColon = false
          }
        }
        break
    }
  }

  if (stack.length === 0 && !stringUnterminated) {
    // Nothing was ever opened as an object/array (or everything already
    // closed) — no container-based repair applies. Return unchanged so the
    // caller's retry decode fails naturally (this truly isn't valid JSON).
    return s
  }

  let buffer = s

  // 1. Close an unterminated string by appending a closing quote. Keep the
  // partial content — do not drop it.
  if (stringUnterminated) {
    buffer += '"'
    if (stack.length > 0) {
      const frame = stack[stack.length - 1]
      if (frame.opener === '{' && !frame.afterKey && !frame.afterColon) {
        frame.afterKey = true
      } else {
        frame.valueStarted = true
        if (frame.opener === '{') frame.afterColon = false
      }
    }
  }

  // 2. Look at the deepest still-open frame. If it has a dangling key/colon
  // with nothing after it, truncate back to its lastSafeIndex (dropping the
  // dangling fragment, including a leading comma). Otherwise leave it as-is
  // (it ended on a complete value/element, or a bare trailing comma to be
  // stripped in step 3).
  if (stack.length > 0) {
    const frame = stack[stack.length - 1]
    const dangling = frame.opener === '{' && (frame.afterKey || frame.afterColon) && !frame.valueStarted
    if (dangling) {
      buffer = buffer.substring(0, frame.lastSafeIndex)
    }
  }

  // 3. Strip a bare trailing comma with nothing after it.
  if (stack.length > 0) {
    const trimmedTail = buffer.replace(/\s+$/, '')
    if (trimmedTail.endsWith(',')) {
      buffer = trimmedTail.substring(0, trimmedTail.length - 1)
    }
  }

  // 4. Close every still-open container, innermost (last-opened) first.
  for (let f = stack.length - 1; f >= 0; f--) {
    buffer += stack[f].opener === '{' ? '}' : ']'
  }

  return buffer
}
