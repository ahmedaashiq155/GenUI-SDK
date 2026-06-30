import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSegments', () {
    test('plain text is a single text segment', () {
      final segs = parseSegments('hello world');
      expect(segs, hasLength(1));
      expect((segs.single as TextSegment).markdown, 'hello world');
    });

    test('separates text, code, and ui blocks in order', () {
      const content = 'Intro line\n'
          '```dart\nvoid main() {}\n```\n'
          'Middle\n'
          '```ui\n{"type":"choices","options":["A"]}\n```\n'
          'Outro';
      final segs = parseSegments(content);
      expect(segs.map((s) => s.runtimeType).toList(), [
        TextSegment,
        CodeSegment,
        TextSegment,
        UiSegment,
        TextSegment,
      ]);
      expect((segs[1] as CodeSegment).language, 'dart');
      expect((segs[1] as CodeSegment).code, 'void main() {}');
      expect((segs[1] as CodeSegment).closed, isTrue);
      expect((segs[3] as UiSegment).json, '{"type":"choices","options":["A"]}');
    });

    test('an unterminated trailing fence is marked not-closed (streaming)', () {
      const content = 'Here:\n```ui\n{"type":"card"';
      final segs = parseSegments(content);
      expect(segs.first, isA<TextSegment>());
      final ui = segs.last as UiSegment;
      expect(ui.closed, isFalse);
      expect(ui.json, '{"type":"card"');
    });

    test('ui language detection is case-insensitive', () {
      final segs = parseSegments('```UI\n{"type":"actions"}\n```');
      expect(segs.single, isA<UiSegment>());
    });
  });
}
