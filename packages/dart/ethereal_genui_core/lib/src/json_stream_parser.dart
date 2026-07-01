import 'dart:convert';

/// Attempts to parse [raw] as a JSON object, tolerating truncation from
/// mid-stream LLM output. Returns the decoded map on success (either a clean
/// parse or a single-pass repair), or `null` if truly unparseable.
///
/// Single-pass, single-retry: never O(n^2) on long streamed specs.
Map<String, dynamic>? tryParsePartialJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  // Fast path: already-complete JSON.
  try {
    final value = jsonDecode(trimmed);
    if (value is Map<String, dynamic>) return value;
  } catch (_) {
    // Fall through to repair.
  }

  final repaired = repairPartialJson(trimmed);
  if (repaired == null) return null;

  try {
    final value = jsonDecode(repaired);
    if (value is Map<String, dynamic>) return value;
  } catch (_) {
    // Unparseable even after repair.
  }
  return null;
}

/// Runs the single left-to-right repair scan on an already-trimmed,
/// non-empty [s] and returns the repaired JSON *string* (not yet decoded),
/// or `null` if no container-based repair applies.
///
/// Exposed (not private) because the repaired string itself — not just the
/// value it decodes to — is the cross-language parity target for the
/// TypeScript port of this algorithm; tests assert against it directly.
String? repairPartialJson(String s) => _repair(s);

/// One open `{` or `[` frame in the scan stack.
class _Frame {
  _Frame(this.opener, this.lastSafeIndex);

  /// The opening bracket character: `{` or `[`.
  final String opener;

  /// String offset immediately after the last syntactically complete
  /// element/pair in this frame (right after the opening bracket if none
  /// yet completed).
  int lastSafeIndex;

  /// Object frames only: are we currently positioned right after a key
  /// string with no colon seen yet?
  bool afterKey = false;

  /// Object frames only: are we currently positioned right after a colon
  /// with no value token started yet?
  bool afterColon = false;

  /// Has any value token started (but not necessarily finished) since the
  /// last comma/opening bracket in this frame? Used to distinguish "bare
  /// trailing comma" from "value in progress" at EOF.
  bool valueStarted = false;
}

/// Runs the single left-to-right repair scan described in the task brief and
/// returns the repaired JSON string, or `null` if the input isn't a `{`- or
/// `[`-rooted structure at all (nothing to repair).
String? _repair(String s) {
  if (s.isEmpty) return null;

  final stack = <_Frame>[];
  var inString = false;
  var escaped = false;
  // True once we've seen the opening quote of a string but not yet the
  // closing one when the scan ends (i.e. the string is unterminated).
  var stringUnterminated = false;

  var i = 0;
  final len = s.length;
  while (i < len) {
    final c = s[i];

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == r'\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
        stringUnterminated = false;
        if (stack.isNotEmpty) {
          final frame = stack.last;
          if (frame.opener == '{' && !frame.afterKey && !frame.afterColon) {
            // This string was a key.
            frame.afterKey = true;
          } else {
            // This string was a value (object value or array element).
            frame.valueStarted = true;
            if (frame.opener == '{') frame.afterColon = false;
          }
        }
      }
      i++;
      continue;
    }

    switch (c) {
      case '"':
        inString = true;
        stringUnterminated = true;
        escaped = false;
        break;
      case '{':
      case '[':
        stack.add(_Frame(c, i + 1));
        if (stack.length > 1) {
          // Becoming the value of the *parent* frame's pending slot; parent
          // bookkeeping is finalized when this frame closes.
        }
        break;
      case '}':
      case ']':
        if (stack.isNotEmpty) {
          stack.removeLast();
          if (stack.isNotEmpty) {
            final parent = stack.last;
            parent.valueStarted = true;
            if (parent.opener == '{') parent.afterColon = false;
            parent.lastSafeIndex = i + 1;
          }
        }
        break;
      case ':':
        if (stack.isNotEmpty && stack.last.opener == '{') {
          stack.last.afterKey = false;
          stack.last.afterColon = true;
        }
        break;
      case ',':
        if (stack.isNotEmpty) {
          final frame = stack.last;
          // A comma after a completed value/element marks a new safe point;
          // reset per-slot flags so we can detect a bare trailing comma or a
          // dangling next key.
          frame.lastSafeIndex = i + 1;
          frame.afterKey = false;
          frame.afterColon = false;
          frame.valueStarted = false;
        }
        break;
      default:
        // Whitespace or part of a bare token (number/true/false/null). Mark
        // the enclosing frame as having a value in progress so a lone comma
        // isn't mistaken for trailing when a scalar follows it.
        if (!_isWhitespace(c) && stack.isNotEmpty) {
          final frame = stack.last;
          if (!(frame.opener == '{' && frame.afterKey)) {
            frame.valueStarted = true;
            if (frame.opener == '{') frame.afterColon = false;
          }
        }
        break;
    }
    i++;
  }

  if (stack.isEmpty && !stringUnterminated) {
    // Nothing was ever opened as an object/array (or everything already
    // closed) — no container-based repair applies. Return unchanged so the
    // caller's retry decode fails naturally (this truly isn't valid JSON).
    return s;
  }

  final buffer = StringBuffer(s);

  // 1. Close an unterminated string by appending a closing quote. Keep the
  // partial content — do not drop it.
  if (stringUnterminated) {
    buffer.write('"');
    inString = false;
    if (stack.isNotEmpty) {
      final frame = stack.last;
      if (frame.opener == '{' && !frame.afterKey && !frame.afterColon) {
        frame.afterKey = true;
      } else {
        frame.valueStarted = true;
        if (frame.opener == '{') frame.afterColon = false;
      }
    }
  }

  // 2. Walk backward from the deepest still-open frame. If it has a
  // dangling key/colon with nothing after it, truncate back to its
  // lastSafeIndex (dropping the dangling fragment, including a leading
  // comma). Otherwise leave it as-is (it ended on a complete value/element,
  // or a bare trailing comma to be stripped in step 3).
  if (stack.isNotEmpty) {
    final frame = stack.last;
    final dangling = frame.opener == '{' &&
        (frame.afterKey || frame.afterColon) &&
        !frame.valueStarted;
    if (dangling) {
      final current = buffer.toString();
      buffer
        ..clear()
        ..write(current.substring(0, frame.lastSafeIndex));
    }
  }

  // 3. Strip a bare trailing comma with nothing after it.
  if (stack.isNotEmpty) {
    final trimmedTail = buffer.toString().trimRight();
    if (trimmedTail.endsWith(',')) {
      buffer
        ..clear()
        ..write(trimmedTail.substring(0, trimmedTail.length - 1));
    }
  }

  // 4. Close every still-open container, innermost (last-opened) first.
  for (var f = stack.length - 1; f >= 0; f--) {
    buffer.write(stack[f].opener == '{' ? '}' : ']');
  }

  return buffer.toString();
}

bool _isWhitespace(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';
