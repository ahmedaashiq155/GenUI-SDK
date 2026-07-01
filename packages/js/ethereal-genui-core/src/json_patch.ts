/// Minimal JSON Patch (RFC 6902) wrapper around fast-json-patch.
///
/// Apply ops (a list of RFC-6902 operation objects) to doc, returning a new
/// document. doc is never mutated. Unapplicable ops are skipped tolerantly.

import pkg from 'fast-json-patch'
import type { Operation } from 'fast-json-patch'

const { applyOperation, deepClone } = pkg

function pointerTokens(pointer: string): string[] {
  if (!pointer) return []
  return pointer.slice(1).split('/').map(t => t.replace(/~1/g, '/').replace(/~0/g, '~'))
}

/**
 * fast-json-patch's array `replace` writes `arr[i] = value` unconditionally,
 * producing a sparse array (holes serialize to null) for an out-of-bounds
 * index instead of skipping the op. The Dart reference bounds-checks and
 * throws (caught → op skipped) — mirror that here before delegating.
 */
function isOutOfBoundsArrayReplace(doc: unknown, path: string): boolean {
  const tokens = pointerTokens(path)
  if (tokens.length === 0) return false
  let node = doc
  for (let i = 0; i < tokens.length - 1; i++) {
    if (node === null || typeof node !== 'object') return false
    node = Array.isArray(node) ? node[Number(tokens[i])] : (node as Record<string, unknown>)[tokens[i]]
  }
  if (!Array.isArray(node)) return false
  const key = tokens[tokens.length - 1]
  const index = Number(key)
  return !Number.isInteger(index) || index < 0 || index >= node.length
}

export function applyJsonPatch(doc: unknown, ops: unknown[]): unknown {
  // Deep clone so original is never mutated.
  let current = deepClone(doc as object) as unknown
  for (const raw of ops) {
    if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) continue
    const op = raw as Record<string, unknown>
    // Skip test ops — we never abort the patch sequence on a failed test.
    if (op['op'] === 'test') continue
    if (op['op'] === 'replace' && isOutOfBoundsArrayReplace(current, String(op['path'] ?? ''))) continue
    try {
      // applyOperation(doc, op, validate=false, mutateDocument=true, banPrototypeModifications=true)
      // We pass mutateDocument=true because we already deep-cloned; it mutates current in place.
      // Double-cast through unknown to satisfy strict Operation type without reimplementing it.
      current = applyOperation(
        current as object,
        op as unknown as Operation,
        false,
        true,
        true
      ).newDocument as unknown
    } catch {
      // Tolerant: skip a bad op, keep going.
    }
  }
  return current
}
