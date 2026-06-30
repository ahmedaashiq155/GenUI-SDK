/// Minimal JSON Patch (RFC 6902) over JSON Pointer (RFC 6901), pure Dart.
///
/// This is what makes the Live App ↔ model loop a *delta* loop: instead of the
/// model resending the whole UI spec each turn, it can emit a small list of
/// ops (add / replace / remove / move / copy) that mutate the spec or state in
/// place. The applier is tolerant — an op that can't apply is skipped rather
/// than throwing — so a malformed delta degrades gracefully instead of wiping
/// the running app.
library;

/// Apply [ops] (a list of RFC-6902 operation objects) to [doc], returning a new
/// document. [doc] is never mutated. Unapplicable ops are skipped.
Object? applyJsonPatch(Object? doc, List<dynamic> ops) {
  var current = _clone(doc);
  for (final raw in ops) {
    if (raw is! Map) continue;
    try {
      current = _applyOne(current, raw);
    } catch (_) {
      // Tolerant: skip a bad op, keep going.
    }
  }
  return current;
}

Object? _applyOne(Object? doc, Map op) {
  final type = (op['op'] ?? '').toString();
  final path = (op['path'] ?? '').toString();
  switch (type) {
    case 'add':
      return _add(doc, _tokens(path), op['value']);
    case 'replace':
      return _replace(doc, _tokens(path), op['value']);
    case 'remove':
      return _remove(doc, _tokens(path));
    case 'move':
      final from = _tokens((op['from'] ?? '').toString());
      final value = _get(doc, from);
      final removed = _remove(doc, from);
      return _add(removed, _tokens(path), _clone(value));
    case 'copy':
      final from = _tokens((op['from'] ?? '').toString());
      return _add(doc, _tokens(path), _clone(_get(doc, from)));
    case 'test':
      // No-op for our purposes (we don't abort a patch on a failed test).
      return doc;
    default:
      return doc;
  }
}

/// Parse a JSON Pointer into decoded tokens. '' → empty (the whole document).
List<String> _tokens(String pointer) {
  if (pointer.isEmpty) return const [];
  if (!pointer.startsWith('/')) throw const FormatException('bad pointer');
  return pointer
      .substring(1)
      .split('/')
      .map((t) => t.replaceAll('~1', '/').replaceAll('~0', '~'))
      .toList();
}

Object? _get(Object? doc, List<String> tokens) {
  Object? node = doc;
  for (final t in tokens) {
    if (node is Map) {
      node = node[t];
    } else if (node is List) {
      node = node[int.parse(t)];
    } else {
      throw StateError('path not found');
    }
  }
  return node;
}

Object? _add(Object? doc, List<String> tokens, Object? value) {
  if (tokens.isEmpty) return _clone(value);
  final parent = _get(doc, tokens.sublist(0, tokens.length - 1));
  final last = tokens.last;
  if (parent is Map) {
    parent[last] = _clone(value);
  } else if (parent is List) {
    if (last == '-') {
      parent.add(_clone(value));
    } else {
      final i = int.parse(last).clamp(0, parent.length);
      parent.insert(i, _clone(value));
    }
  } else {
    throw StateError('cannot add to non-container');
  }
  return doc;
}

/// RFC-6902 `replace`: overwrite an existing value at [tokens].
///
/// For Map targets this is identical to `_add` (both overwrite). For List
/// targets `_add` inserts (shifting elements right) but `replace` must
/// overwrite in-place — hence the separate function.
Object? _replace(Object? doc, List<String> tokens, Object? value) {
  if (tokens.isEmpty) return _clone(value);
  final parent = _get(doc, tokens.sublist(0, tokens.length - 1));
  final last = tokens.last;
  if (parent is Map) {
    parent[last] = _clone(value);
  } else if (parent is List) {
    final i = int.parse(last);
    if (i < 0 || i >= parent.length) {
      throw RangeError.index(i, parent, 'replace', 'index out of range');
    }
    parent[i] = _clone(value);
  } else {
    throw StateError('cannot replace in non-container');
  }
  return doc;
}

Object? _remove(Object? doc, List<String> tokens) {
  if (tokens.isEmpty) return null;
  final parent = _get(doc, tokens.sublist(0, tokens.length - 1));
  final last = tokens.last;
  if (parent is Map) {
    parent.remove(last);
  } else if (parent is List) {
    parent.removeAt(int.parse(last));
  } else {
    throw StateError('cannot remove from non-container');
  }
  return doc;
}

/// Deep copy so the input document is never mutated and inserted values are
/// independent of their source.
Object? _clone(Object? node) {
  if (node is Map) {
    return <String, dynamic>{
      for (final entry in node.entries) entry.key.toString(): _clone(entry.value),
    };
  }
  if (node is List) {
    return <dynamic>[for (final e in node) _clone(e)];
  }
  return node; // primitives are immutable
}
