import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Batch 1 hardening — the spec is untrusted model output. These exercise the
/// crash/security fixes: hostile types, hex parsing, directive consent gates,
/// recursion depth, and numeric guards.
Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  GenUiActions actions({
    void Function(String)? onSend,
    void Function(String)? onAccent,
    void Function(List<String>)? onShortcuts,
    bool enabled = true,
  }) =>
      GenUiActions(
        sendMessage: onSend ?? (_) {},
        setAccent: onAccent,
        setShortcuts: onShortcuts,
        enabled: enabled,
      );

  group('parseHexColor', () {
    test('8-digit RRGGBBAA is reordered to ARGB (not read as AARRGGBB)', () {
      // #ffffff22 = white at ~13% alpha. The alpha byte (0x22) must land in
      // the alpha channel, not blue.
      expect(parseHexColor('#ffffff22'), const Color(0x22FFFFFF));
    });

    test('6-digit is treated as fully opaque', () {
      expect(parseHexColor('#8B93FF'), const Color(0xFF8B93FF));
    });

    test('3-digit shorthand expands', () {
      expect(parseHexColor('#fff'), const Color(0xFFFFFFFF));
    });

    test('garbage returns null', () {
      expect(parseHexColor('not-a-color'), isNull);
      expect(parseHexColor('#12'), isNull);
      expect(parseHexColor(null), isNull);
    });
  });

  group('hostile spec types do not crash the renderer', () {
    // A grab-bag of type-confused values the model might emit for fields that
    // normally expect a string/list. None should throw.
    final hostile = <Map<String, dynamic>>[
      {'type': 'stat', 'title': 2024, 'stats': 'nope'},
      {'type': 'card', 'items': 'none'},
      {'type': 'box', 'children': {'type': 'text', 'text': 'hi'}},
      {'type': 'table', 'columns': 42, 'rows': 'x'},
      {'type': 'gallery', 'images': 'http://x'},
      {'type': 'chart', 'title': 99, 'data': 'no'},
      {'type': 'segmented', 'title': 7, 'options': 5},
      {'type': 'timeline', 'title': true, 'items': 3},
    ];

    for (final spec in hostile) {
      testWidgets('renders ${spec['type']} with hostile fields', (tester) async {
        await tester.pumpWidget(_host(Builder(
          builder: (c) => buildGenUiSpec(c, spec, actions()),
        )));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('directive consent gates', () {
    testWidgets('theme does not apply accent on render — only after tapping Apply',
        (tester) async {
      final applied = <String>[];
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {'type': 'theme', 'accent': '#FF0000'},
          actions(onAccent: applied.add),
        ),
      )));
      await tester.pump();
      expect(applied, isEmpty);

      await tester.tap(find.text('Apply'));
      await tester.pump();
      expect(applied, ['#FF0000']);
    });

    testWidgets('shortcuts does not persist on render — only after tapping Save',
        (tester) async {
      final saved = <List<String>>[];
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {'type': 'shortcuts', 'items': ['Plan my week', 'Summarize']},
          actions(onShortcuts: saved.add),
        ),
      )));
      await tester.pump();
      expect(saved, isEmpty);

      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(saved, [
        ['Plan my week', 'Summarize'],
      ]);
    });
  });

  group('resource guards', () {
    testWidgets('deeply nested spec degrades to a placeholder, no stack overflow',
        (tester) async {
      Map<String, dynamic> spec = {'type': 'text', 'text': 'leaf'};
      for (var i = 0; i < kGenUiMaxDepth + 20; i++) {
        spec = {'type': 'box', 'children': [spec]};
      }
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(c, spec, actions()),
      )));
      expect(tester.takeException(), isNull);
      expect(find.text("Couldn't render this block"), findsWidgets);
    });

    testWidgets('rating with an absurd max is clamped (no OOM)', (tester) async {
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {'type': 'rating', 'max': 100000000},
          actions(),
        ),
      )));
      expect(tester.takeException(), isNull);
      // Clamped to <= 20 filled/empty stars.
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(20));
    });

    testWidgets('slider with inverted min/max does not throw', (tester) async {
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {'type': 'slider', 'min': 100, 'max': 0, 'value': 50},
          actions(),
        ),
      )));
      expect(tester.takeException(), isNull);
    });
  });
}
