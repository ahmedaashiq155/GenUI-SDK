import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Map<String, dynamic> spec, GenUiActions actions) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Builder(
        builder: (context) => buildGenUiSpec(context, spec, actions),
      ),
    ),
  ),
);

GenUiActions _actions({
  void Function(String)? onSend,
  void Function(Map<String, dynamic>)? openArtifact,
}) => GenUiActions(sendMessage: onSend ?? (_) {}, openArtifact: openArtifact);

void main() {
  testWidgets('form rejects empty submissions and enforces required fields', (
    tester,
  ) async {
    String? sent;
    final spec = <String, dynamic>{
      'type': 'form',
      'fields': [
        {'key': 'name', 'label': 'Name', 'type': 'text', 'required': true},
        {
          'key': 'seat',
          'label': 'Seating',
          'type': 'select',
          'required': true,
          'options': ['Inside', 'Outside'],
        },
      ],
    };
    await tester.pumpWidget(
      _host(spec, _actions(onSend: (value) => sent = value)),
    );

    GenUiPressable submit() => tester.widget<GenUiPressable>(
      find
          .ancestor(
            of: find.text('Submit'),
            matching: find.byType(GenUiPressable),
          )
          .first,
    );

    expect(submit().onTap, isNull);
    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.pump();
    expect(submit().onTap, isNull);
    await tester.tap(find.text('Inside'));
    await tester.pump();
    expect(submit().onTap, isNotNull);
    await tester.tap(find.text('Submit'));
    expect(sent, 'Name: Alice\nSeating: Inside');
  });

  testWidgets('checklist keeps checked values when patched items reorder', (
    tester,
  ) async {
    var spec = <String, dynamic>{
      'type': 'checklist',
      'items': [
        {'label': 'First', 'value': 'first'},
        {'label': 'Second', 'value': 'second'},
      ],
    };
    final actions = _actions();
    await tester.pumpWidget(_host(spec, actions));
    await tester.tap(find.text('Second'));
    await tester.pump();

    spec = {
      ...spec,
      'items': [
        {'label': 'Second', 'value': 'second'},
        {'label': 'First', 'value': 'first'},
      ],
    };
    await tester.pumpWidget(_host(spec, actions));
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('Second')).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(
      tester.widget<Text>(find.text('First')).style?.decoration,
      isNot(TextDecoration.lineThrough),
    );
  });

  testWidgets('stepper resyncs when a patch changes its value', (tester) async {
    var spec = <String, dynamic>{
      'type': 'stepper',
      'min': 1,
      'max': 9,
      'value': 2,
    };
    final actions = _actions();
    await tester.pumpWidget(_host(spec, actions));
    await tester.tap(find.bySemanticsLabel('Increase'));
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    spec = {...spec, 'value': 7};
    await tester.pumpWidget(_host(spec, actions));
    await tester.pump();
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('poll preserves the answered lock by stable option value', (
    tester,
  ) async {
    final sent = <String>[];
    var spec = <String, dynamic>{
      'type': 'poll',
      'options': [
        {'label': 'Alpha', 'value': 'a', 'votes': 1},
        {'label': 'Beta', 'value': 'b', 'votes': 2},
      ],
    };
    final actions = _actions(onSend: sent.add);
    await tester.pumpWidget(_host(spec, actions));
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    expect(sent, ['a']);

    spec = {
      ...spec,
      'options': [
        {'label': 'Beta updated', 'value': 'b', 'votes': 3},
        {'label': 'Alpha updated', 'value': 'a', 'votes': 2},
      ],
    };
    await tester.pumpWidget(_host(spec, actions));
    await tester.pump();
    await tester.tap(find.text('Beta updated'));
    expect(sent, ['a']);
  });

  testWidgets('converter and timer reset their derived state after patches', (
    tester,
  ) async {
    var converter = <String, dynamic>{
      'type': 'converter',
      'units': [
        {'label': 'm', 'factor': 1},
        {'label': 'km', 'factor': 1000},
      ],
    };
    final actions = _actions();
    await tester.pumpWidget(_host(converter, actions));
    converter = {
      ...converter,
      'units': [
        {'label': 'cm', 'factor': 0.01},
        {'label': 'm', 'factor': 1},
      ],
    };
    await tester.pumpWidget(_host(converter, actions));
    await tester.pump();
    final menu = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>).first,
    );
    expect(menu.items!.map((item) => (item.child as Text).data), ['cm', 'm']);

    var timer = <String, dynamic>{'type': 'timer', 'seconds': 60};
    await tester.pumpWidget(_host(timer, actions));
    await tester.tap(find.bySemanticsLabel('Start timer'));
    await tester.pump();
    timer = {...timer, 'seconds': 90};
    await tester.pumpWidget(_host(timer, actions));
    await tester.pump();
    expect(find.text('01:30'), findsOneWidget);
    expect(find.bySemanticsLabel('Start timer'), findsOneWidget);
  });

  testWidgets('artifact is not interactive without a host opener', (
    tester,
  ) async {
    final spec = <String, dynamic>{
      'type': 'artifact',
      'kind': 'code',
      'title': 'Example',
      'content': 'print(1)',
    };
    await tester.pumpWidget(_host(spec, _actions()));
    expect(find.text('code'), findsOneWidget);
    expect(find.textContaining('tap to open'), findsNothing);
    expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);

    Map<String, dynamic>? opened;
    await tester.pumpWidget(
      _host(spec, _actions(openArtifact: (value) => opened = value)),
    );
    expect(find.textContaining('tap to open'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Open Example'));
    expect(opened, same(spec));
  });

  testWidgets('collection renderers explain empty content consistently', (
    tester,
  ) async {
    for (final spec in <Map<String, dynamic>>[
      {'type': 'chart', 'data': const []},
      {'type': 'gallery', 'images': const []},
      {'type': 'badges', 'items': const []},
    ]) {
      await tester.pumpWidget(_host(spec, _actions()));
      final label = switch (spec['type']) {
        'chart' => 'No chart data',
        'gallery' => 'No images',
        _ => 'No badges',
      };
      expect(find.text(label), findsOneWidget);
    }
  });
}
