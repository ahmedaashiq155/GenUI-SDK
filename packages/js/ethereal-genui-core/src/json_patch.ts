/// Minimal JSON Patch (RFC 6902) wrapper around fast-json-patch.
///
/// Apply ops (a list of RFC-6902 operation objects) to doc, returning a new
/// document. doc is never mutated. Unapplicable ops are skipped tolerantly.

import pkg from 'fast-json-patch'
import type { Operation } from 'fast-json-patch'

const { applyOperation, deepClone } = pkg

export function applyJsonPatch(doc: unknown, ops: unknown[]): unknown {
  // Deep clone so original is never mutated.
  let current = deepClone(doc as object) as unknown
  for (const raw of ops) {
    if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) continue
    const op = raw as Record<string, unknown>
    // Skip test ops — we never abort the patch sequence on a failed test.
    if (op['op'] === 'test') continue
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
