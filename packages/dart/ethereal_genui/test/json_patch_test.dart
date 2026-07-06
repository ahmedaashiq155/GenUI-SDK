import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyJsonPatch (RFC 6902)', () {
    test('replace at a list index overwrites in-place (not insert)', () {
      final doc = {'items': ['a', 'b', 'c']};
      final out = applyJsonPatch(doc, [
        {'op': 'replace', 'path': '/items/1', 'value': 'X'},
      ]) as Map;
      // Must be ['a', 'X', 'c'], NOT ['a', 'X', 'b', 'c'].
      expect(out['items'], equals(['a', 'X', 'c']));
    });

    test('replace a nested value', () {
      final doc = {
        'type': 'box',
        'children': [
          {'type': 'text', 'text': 'old'},
        ],
      };
      final out = applyJsonPatch(doc, [
        {'op': 'replace', 'path': '/children/0/text', 'value': 'new'},
      ]) as Map;
      expect((out['children'] as List)[0]['text'], 'new');
    });

    test('add a key and append to a list', () {
      final doc = {
        'children': [
          {'type': 'text', 'text': 'a'},
        ],
      };
      final out = applyJsonPatch(doc, [
        {'op': 'add', 'path': '/title', 'value': 'Hi'},
        {
          'op': 'add',
          'path': '/children/-',
          'value': {'type': 'text', 'text': 'b'},
        },
      ]) as Map;
      expect(out['title'], 'Hi');
      expect((out['children'] as List).length, 2);
      expect((out['children'] as List)[1]['text'], 'b');
    });

    test('insert into a list at an index', () {
      final doc = {
        'children': ['a', 'c'],
      };
      final out = applyJsonPatch(doc, [
        {'op': 'add', 'path': '/children/1', 'value': 'b'},
      ]) as Map;
      expect(out['children'], ['a', 'b', 'c']);
    });

    test('remove a key and a list element', () {
      final doc = {
        'title': 'gone',
        'children': ['a', 'b', 'c'],
      };
      final out = applyJsonPatch(doc, [
        {'op': 'remove', 'path': '/title'},
        {'op': 'remove', 'path': '/children/1'},
      ]) as Map;
      expect(out.containsKey('title'), isFalse);
      expect(out['children'], ['a', 'c']);
    });

    test('move and copy', () {
      final doc = {
        'a': {'x': 1},
        'b': {},
      };
      final moved = applyJsonPatch(doc, [
        {'op': 'move', 'from': '/a/x', 'path': '/b/y'},
      ]) as Map;
      expect((moved['a'] as Map).containsKey('x'), isFalse);
      expect((moved['b'] as Map)['y'], 1);

      final copied = applyJsonPatch({'a': 5, 'b': {}}, [
        {'op': 'copy', 'from': '/a', 'path': '/b/a2'},
      ]) as Map;
      expect((copied['b'] as Map)['a2'], 5);
      expect(copied['a'], 5);
    });

    test('does not mutate the input document', () {
      final doc = {
        'children': [
          {'type': 'text', 'text': 'orig'},
        ],
      };
      applyJsonPatch(doc, [
        {'op': 'replace', 'path': '/children/0/text', 'value': 'changed'},
      ]);
      expect((doc['children'] as List)[0]['text'], 'orig');
    });

    test('is tolerant: a bad op is skipped, others still apply', () {
      final doc = {'a': 1};
      final out = applyJsonPatch(doc, [
        {'op': 'remove', 'path': '/does/not/exist'}, // skipped
        {'op': 'add', 'path': '/b', 'value': 2}, // applied
        {'op': 'bogus', 'path': '/c', 'value': 3}, // unknown op, ignored
      ]) as Map;
      expect(out['a'], 1);
      expect(out['b'], 2);
      expect(out.containsKey('c'), isFalse);
    });

    test('empty path replaces the whole document', () {
      final out = applyJsonPatch({'old': true}, [
        {'op': 'replace', 'path': '', 'value': {'new': true}},
      ]) as Map;
      expect(out, {'new': true});
    });

    test('op with MISSING path is skipped — must not wipe the document', () {
      final doc = {'app': 'running', 'count': 3};
      // A truncated delta that lost its "path" — must be a no-op, not a
      // whole-document replace.
      final replaced = applyJsonPatch(doc, [
        {'op': 'replace', 'value': {'oops': true}},
      ]) as Map;
      expect(replaced, doc);

      // {"op":"remove"} with no path must not null the document.
      final removed = applyJsonPatch(doc, [
        {'op': 'remove'},
      ]);
      expect(removed, doc);

      // add without path is skipped too.
      final added = applyJsonPatch(doc, [
        {'op': 'add', 'value': 42},
      ]) as Map;
      expect(added, doc);
    });

    test('move/copy with missing from is skipped', () {
      final doc = {'a': 1, 'b': 2};
      final moved = applyJsonPatch(doc, [
        {'op': 'move', 'path': '/b'},
      ]) as Map;
      expect(moved, doc);

      final copied = applyJsonPatch(doc, [
        {'op': 'copy', 'path': '/c'},
      ]) as Map;
      expect(copied, doc);
    });
  });
}
