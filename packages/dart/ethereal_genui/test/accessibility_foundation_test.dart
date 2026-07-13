import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child, {
  double textScale = 1,
  Iterable<LocalizationsDelegate<dynamic>> delegates = const [],
}) => MaterialApp(
  localizationsDelegates: delegates,
  supportedLocales: const [Locale('en')],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

GenUiActions _actions() => GenUiActions(sendMessage: (_) {});

void main() {
  testWidgets('GenUiPressable activates from keyboard and shows focus', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      _host(
        GenUiPressable(
          onTap: () => activations++,
          semanticLabel: 'Keyboard action',
          child: const Text('Action'),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(activations, 1);
    final focusDecoration = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .any((decoration) => decoration.border != null);
    expect(focusDecoration, isTrue);
  });

  testWidgets('selection and checked state are exposed through semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            GenUiPressable(
              onTap: () {},
              semanticLabel: 'Selected option',
              selected: true,
              child: const Text('Selected'),
            ),
            GenUiPressable(
              onTap: () {},
              semanticLabel: 'Checked option',
              checked: true,
              child: const Text('Checked'),
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Selected option')),
      matchesSemantics(
        label: 'Selected option',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Checked option')),
      matchesSemantics(
        label: 'Checked option',
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('all pressables reserve at least a 44dp target', (tester) async {
    await tester.pumpWidget(
      _host(
        GenUiPressable(
          onTap: () {},
          semanticLabel: 'Tiny icon',
          child: const Icon(Icons.add, size: 12),
        ),
      ),
    );
    final size = tester.getSize(find.byType(FocusableActionDetector));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('model-authored light colors receive readable foregrounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => buildGenUiSpec(context, {
            'type': 'button',
            'label': 'Readable',
            'style': 'primary',
            'color': '#ffffff',
          }, _actions()),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Readable'));
    expect(
      GenUiContrast.ratio(text.style!.color!, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('gallery exposes supplied alternative text', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => buildGenUiSpec(context, {
            'type': 'gallery',
            'images': ['https://example.test/photo.png'],
            'alt': ['A quiet lake at sunrise'],
          }, _actions()),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.semanticLabel, 'A quiet lake at sunrise');
    expect(image.excludeFromSemantics, isFalse);
  });

  testWidgets('timer completion updates its polite live-region label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => buildGenUiSpec(context, {
            'type': 'timer',
            'seconds': 1,
          }, _actions()),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Start timer'));
    await tester.pump(const Duration(seconds: 1));
    final live = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Timer complete',
    );
    expect(live, findsOneWidget);
    expect(tester.getSemantics(live).label, 'Timer complete');
    handle.dispose();
  });

  testWidgets('poll options expand instead of clipping at large text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => buildGenUiSpec(context, {
            'type': 'poll',
            'options': [
              {'label': 'A deliberately long poll option', 'votes': 1},
            ],
          }, _actions()),
        ),
        textScale: 3,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.text('A deliberately long poll option')).height,
      greaterThan(40),
    );
  });

  testWidgets('host localization delegate overrides framework-owned copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        GenUiBlock(raw: '', actions: _actions(), closed: false),
        delegates: [
          GenUiLocalizationsDelegate(
            loadStrings: (_) => const GenUiLocalizations({
              GenUiStringKey.preparing: 'Preparando…',
            }),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preparando…'), findsOneWidget);
  });
}
