import 'package:ethereal_genui_core/ethereal_genui_core.dart';
import 'package:test/test.dart';

void main() {
  group('tryParsePartialJson — worked examples', () {
    test('simple unclosed object, no dangling anything — just close', () {
      const input = '{"type":"card","title":"Users"';
      const repaired = '{"type":"card","title":"Users"}';
      expect(repairPartialJson(input), repaired);
      expect(
        tryParsePartialJson(input),
        equals({'type': 'card', 'title': 'Users'}),
      );
    });

    test('unclosed string mid-value — close it, KEEP partial content', () {
      const input = '{"a":1,"b":"unclo';
      const repaired = '{"a":1,"b":"unclo"}';
      expect(repairPartialJson(input), repaired);
      expect(tryParsePartialJson(input), equals({'a': 1, 'b': 'unclo'}));
    });

    test('nested: close inner string, inner object, array, outer object', () {
      const input = '{"type":"card","items":[{"label":"a';
      const repaired = '{"type":"card","items":[{"label":"a"}]}';
      expect(repairPartialJson(input), repaired);
      expect(
        tryParsePartialJson(input),
        equals({
          'type': 'card',
          'items': [{'label': 'a'}],
        }),
      );
    });

    test('dangling colon with no value token at all — truncate and drop', () {
      const input = '{"type":"card","title":';
      const repaired = '{"type":"card"}';
      expect(repairPartialJson(input), repaired);
      expect(tryParsePartialJson(input), equals({'type': 'card'}));
    });

    test('dangling key with no colon yet — truncate and drop', () {
      const input = '{"a":1,"key';
      const repaired = '{"a":1}';
      expect(repairPartialJson(input), repaired);
      expect(tryParsePartialJson(input), equals({'a': 1}));
    });

    test('trailing comma in an array with nothing after — strip then close', () {
      const input = '{"type":"list","items":["a","b",';
      const repaired = '{"type":"list","items":["a","b"]}';
      expect(repairPartialJson(input), repaired);
      expect(
        tryParsePartialJson(input),
        equals({
          'type': 'list',
          'items': ['a', 'b'],
        }),
      );
    });

    test('plain unclosed object', () {
      const input = '{"type":"card"';
      const repaired = '{"type":"card"}';
      expect(repairPartialJson(input), repaired);
      expect(tryParsePartialJson(input), equals({'type': 'card'}));
    });

    test('unparseable even after repair attempt — returns null', () {
      const input = 'not json at all {{{';
      expect(tryParsePartialJson(input), isNull);
    });

    test('empty string — returns null immediately, no repair attempted', () {
      expect(tryParsePartialJson(''), isNull);
      expect(tryParsePartialJson('   '), isNull);
    });

    test('already-valid JSON — fast path, repair never runs', () {
      const input = '{"a":1,"b":2}';
      expect(tryParsePartialJson(input), equals({'a': 1, 'b': 2}));
    });
  });

  group('tryParsePartialJson — escape tracking', () {
    test('escaped backslash-quote inside an unclosed string is not mistaken '
        'for a real closing quote', () {
      const input = r'{"a":"line1\nline2\"quoted';
      final result = tryParsePartialJson(input);
      expect(result, isNotNull);
      expect(result!['a'], 'line1\nline2"quoted');
    });
  });

  group('tryParsePartialJson — additional coverage', () {
    test('deeply nested unclosed object at multiple levels', () {
      const input = '{"type":"box","children":[{"type":"text","text":"hi"},{"type":"button","label":"Go';
      final result = tryParsePartialJson(input);
      expect(result, isNotNull);
      expect(result!['type'], 'box');
      final children = result['children'] as List;
      expect(children.length, 2);
      expect(children[0], equals({'type': 'text', 'text': 'hi'}));
      expect(children[1], equals({'type': 'button', 'label': 'Go'}));
    });

    test('non-object top-level JSON value returns null (only maps accepted)', () {
      expect(tryParsePartialJson('[1,2,3]'), isNull);
      expect(tryParsePartialJson('"just a string"'), isNull);
    });

    test('whitespace is trimmed before parsing', () {
      const input = '   {"a":1}   ';
      expect(tryParsePartialJson(input), equals({'a': 1}));
    });
  });
}
