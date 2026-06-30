/// Splits an assistant message into ordered segments so fenced blocks render as
/// sibling widgets (outside `gpt_markdown`'s `Text.rich`, where taps were eaten).
sealed class MessageSegment {
  const MessageSegment();
}

class TextSegment extends MessageSegment {
  const TextSegment(this.markdown);
  final String markdown;
}

class CodeSegment extends MessageSegment {
  const CodeSegment(this.language, this.code, this.closed);
  final String language;
  final String code;
  final bool closed;
}

class UiSegment extends MessageSegment {
  const UiSegment(this.json, this.closed);
  final String json;
  final bool closed;
}

final _fenceOpen = RegExp(r'^\s*```(.*)$');
final _fenceClose = RegExp(r'^\s*```\s*$');

/// Parse [content] into text / code / ui segments. Streaming-tolerant: a
/// trailing fence that hasn't closed yet yields a segment with `closed == false`.
List<MessageSegment> parseSegments(String content) {
  final segments = <MessageSegment>[];
  final lines = content.split('\n');
  final textBuffer = StringBuffer();

  void flushText() {
    final text = textBuffer.toString();
    textBuffer.clear();
    if (text.trim().isNotEmpty) segments.add(TextSegment(text.trimRight()));
  }

  var i = 0;
  while (i < lines.length) {
    final open = _fenceOpen.firstMatch(lines[i]);
    if (open != null) {
      flushText();
      final lang = open.group(1)!.trim();
      i++;
      final body = <String>[];
      var closed = false;
      while (i < lines.length) {
        if (_fenceClose.hasMatch(lines[i])) {
          closed = true;
          i++;
          break;
        }
        body.add(lines[i]);
        i++;
      }
      final inner = body.join('\n');
      if (lang.toLowerCase() == 'ui') {
        segments.add(UiSegment(inner, closed));
      } else {
        segments.add(CodeSegment(lang, inner, closed));
      }
    } else {
      textBuffer.writeln(lines[i]);
      i++;
    }
  }
  flushText();
  return segments;
}
