import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders the generative-UI engine without a device. The engine draws its own
/// colours from [GenUiColors] (fallback here) and uses the Material text theme,
/// so a plain MaterialApp is all that's needed — no app shell, no network fonts.
Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  GenUiActions actions({void Function(String)? onSend, bool enabled = true}) =>
      GenUiActions(sendMessage: onSend ?? (_) {}, enabled: enabled);

  testWidgets('choices renders options and a tap sends', (tester) async {
    String? sent;
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(
        c,
        {'type': 'choices', 'options': ['Yes', 'No']},
        actions(onSend: (s) => sent = s),
      ),
    )));
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('No'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pump();
    expect(sent, 'Yes');
  });

  testWidgets('freeform primitives (box/text/button) render', (tester) async {
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(
        c,
        {
          'type': 'box',
          'children': [
            {'type': 'text', 'text': 'Hello world'},
            {'type': 'button', 'label': 'Go', 'send': 'go'},
          ],
        },
        actions(),
      ),
    )));
    expect(find.text('Hello world'), findsOneWidget);
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('choices accept object options and never show raw JSON',
      (tester) async {
    String? sent;
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(
        c,
        {
          'type': 'choices',
          'options': [
            {'label': 'Daily', 'value': 'daily'},
            {'label': 'Weekly', 'value': 'weekly'},
          ],
        },
        actions(onSend: (s) => sent = s),
      ),
    )));
    expect(find.text('Daily'), findsOneWidget);
    expect(find.textContaining('{label'), findsNothing); // no raw map leak
    await tester.tap(find.text('Daily'));
    await tester.pump();
    expect(sent, 'daily'); // sends value, not the rendered label
  });

  testWidgets('checklist accepts object items and honours checked',
      (tester) async {
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(
        c,
        {
          'type': 'checklist',
          'items': [
            {'label': 'Morning Walk', 'checked': false, 'send': 'log_walk'},
            {'label': 'Read 10 Pages', 'checked': true, 'send': 'log_read'},
          ],
        },
        actions(),
      ),
    )));
    await tester.pump();
    expect(find.text('Morning Walk'), findsOneWidget);
    expect(find.text('Read 10 Pages'), findsOneWidget);
    expect(find.textContaining('{label'), findsNothing);
    // "checked": true should render struck-through on first build.
    final read = tester.widget<Text>(find.text('Read 10 Pages'));
    expect(read.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('unknown type degrades to a legible placeholder', (tester) async {
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(c, {'type': 'totally-unknown'}, actions()),
    )));
    expect(find.text('Unsupported block: totally-unknown'), findsOneWidget);
  });

  testWidgets('a host can register a custom block type', (tester) async {
    // Use a fresh registry so the global stays pristine for the drift guard.
    final registry = GenUiRegistry()
      ..register('custom_hello', (c, s, a) => Text('${s['greeting']}'));
    expect(registry.contains('custom_hello'), isTrue);
    final builder = registry.builderFor('custom_hello')!;
    await tester.pumpWidget(_host(Builder(
      builder: (c) => builder(
        c,
        {'type': 'custom_hello', 'greeting': 'Hi from a plugin'},
        actions(),
      ),
    )));
    expect(find.text('Hi from a plugin'), findsOneWidget);
  });

  test('registry covers exactly the schema types (plus internal tool_call)', () {
    final registered = defaultGenUiRegistry.types..remove('tool_call');
    expect(registered, equals(genUiKnownTypes));
  });

  testWidgets('GenUiBlock parses raw JSON and renders', (tester) async {
    await tester.pumpWidget(_host(GenUiBlock(
      raw: '{"type":"callout","title":"Heads up","text":"A note"}',
      actions: actions(),
    )));
    expect(find.text('Heads up'), findsOneWidget);
  });

  testWidgets('GenUiBlock renders a still-streaming partial spec progressively',
      (tester) async {
    await tester.pumpWidget(_host(GenUiBlock(
      raw: '{"type":"card","title":"Users"',
      actions: actions(),
      closed: false,
    )));
    expect(find.text('Users'), findsOneWidget);
  });

  testWidgets(
      'GenUiBlock shows the streaming placeholder for unrepairable partial JSON '
      'while still open', (tester) async {
    await tester.pumpWidget(_host(GenUiBlock(
      raw: 'garbage {{{',
      actions: actions(),
      closed: false,
    )));
    expect(find.text('Preparing…'), findsOneWidget);
    expect(find.text("Couldn't render this block"), findsNothing);
  });

  testWidgets(
      'GenUiBlock shows the malformed placeholder for unrepairable JSON once closed',
      (tester) async {
    await tester.pumpWidget(_host(GenUiBlock(
      raw: 'garbage {{{',
      actions: actions(),
      closed: true,
    )));
    expect(find.text("Couldn't render this block"), findsOneWidget);
    expect(find.text('Preparing…'), findsNothing);
  });

  testWidgets('disabled actions do not send', (tester) async {
    String? sent;
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(
        c,
        {'type': 'choices', 'options': ['A']},
        actions(onSend: (s) => sent = s, enabled: false),
      ),
    )));
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(sent, isNull);
  });

  testWidgets('a rendered spec synchronously rejects duplicate sends',
      (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(
        c,
        {'type': 'choices', 'options': ['Yes', 'No']},
        actions(onSend: sent.add),
      ),
    )));

    await tester.tap(find.text('Yes'));
    await tester.tap(find.text('No'));
    await tester.pump();
    expect(sent, ['Yes']);
  });

  testWidgets('nested send controls share the root dispatch lock',
      (tester) async {
    final sent = <String>[];
    await tester.pumpWidget(_host(Builder(
      builder: (c) => buildGenUiSpec(
        c,
        {
          'type': 'column',
          'children': [
            {'type': 'choices', 'options': ['First']},
            {'type': 'choices', 'options': ['Second']},
          ],
        },
        actions(onSend: sent.add),
      ),
    )));

    await tester.tap(find.text('First'));
    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(sent, ['First']);
  });

  testWidgets('dispatch lock resets after enabled changes false then true',
      (tester) async {
    final sent = <String>[];
    Widget subject(bool enabled) => _host(Builder(
          builder: (c) => buildGenUiSpec(
            c,
            {'type': 'choices', 'options': ['Again']},
            actions(onSend: sent.add, enabled: enabled),
          ),
        ));

    await tester.pumpWidget(subject(true));
    await tester.tap(find.text('Again'));
    await tester.pump();
    expect(sent, ['Again']);

    await tester.pumpWidget(subject(false));
    await tester.pumpWidget(subject(true));
    await tester.tap(find.text('Again'));
    await tester.pump();
    expect(sent, ['Again', 'Again']);
  });

  testWidgets('disabled pressables expose a subdued pending affordance',
      (tester) async {
    await tester.pumpWidget(_host(const GenUiPressable(
      child: Text('Pending'),
    )));
    final opacity = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(opacity.opacity, 0.55);
  });

  testWidgets('checklist restores persisted state from GenUiStateScope',
      (tester) async {
    await tester.pumpWidget(_host(GenUiStateScope(
      state: const {
        'todo': [0, 2],
      },
      onChanged: (_) {},
      child: Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {
            'type': 'checklist',
            'id': 'todo',
            'items': ['One', 'Two', 'Three'],
          },
          actions(),
        ),
      ),
    )));
    await tester.pump();
    // Items 0 and 2 should render checked (line-through), item 1 unchecked.
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
    final one = tester.widget<Text>(find.text('One'));
    expect(one.style?.decoration, TextDecoration.lineThrough);
    final two = tester.widget<Text>(find.text('Two'));
    expect(two.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  group('durable state (GenUiStateScope)', () {
    Widget scoped(Map<String, dynamic> state, Map<String, dynamic> spec,
            {void Function(Map<String, dynamic>)? onChanged}) =>
        _host(GenUiStateScope(
          state: state,
          onChanged: onChanged ?? (_) {},
          child: Builder(builder: (c) => buildGenUiSpec(c, spec, actions())),
        ));

    testWidgets('rating restores its value', (tester) async {
      await tester.pumpWidget(scoped(
        {'r': 3},
        {'type': 'rating', 'id': 'r', 'max': 5},
      ));
      await tester.pump();
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
    });

    testWidgets('slider restores its value', (tester) async {
      await tester.pumpWidget(scoped(
        {'s': 42},
        {'type': 'slider', 'id': 's', 'min': 0, 'max': 100, 'unit': '%'},
      ));
      await tester.pump();
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('input restores its text', (tester) async {
      await tester.pumpWidget(scoped(
        {'q': 'hello there'},
        {'type': 'input', 'id': 'q', 'label': 'Q'},
      ));
      await tester.pump();
      expect(find.text('hello there'), findsOneWidget);
    });

    testWidgets('form restores a text field value', (tester) async {
      await tester.pumpWidget(scoped(
        {'f': {'name': 'Alice'}},
        {
          'type': 'form',
          'id': 'f',
          'fields': [
            {'key': 'name', 'label': 'Name', 'type': 'text'},
          ],
        },
      ));
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('rating persists back through the scope', (tester) async {
      Map<String, dynamic>? written;
      await tester.pumpWidget(scoped(
        const {},
        {'type': 'rating', 'id': 'r', 'max': 5},
        onChanged: (next) => written = next,
      ));
      await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3)); // 4th star
      await tester.pump();
      expect(written?['r'], 4);
    });
  });

  group('client-side interactivity (self-contained apps)', () {
    testWidgets('when shows its child only when state matches', (tester) async {
      await tester.pumpWidget(_host(GenUiStateScope(
        state: const {'view': 'new'},
        onChanged: (_) {},
        child: Builder(
          builder: (c) => buildGenUiSpec(
            c,
            {
              'type': 'when',
              'key': 'view',
              'equals': 'new',
              'child': {'type': 'text', 'text': 'New Habit Form'},
            },
            actions(),
          ),
        ),
      )));
      expect(find.text('New Habit Form'), findsOneWidget);
    });

    testWidgets('when hides its child when state does not match',
        (tester) async {
      await tester.pumpWidget(_host(GenUiStateScope(
        state: const {'view': 'list'},
        onChanged: (_) {},
        child: Builder(
          builder: (c) => buildGenUiSpec(
            c,
            {
              'type': 'when',
              'key': 'view',
              'equals': 'new',
              'child': {'type': 'text', 'text': 'New Habit Form'},
            },
            actions(),
          ),
        ),
      )));
      expect(find.text('New Habit Form'), findsNothing);
    });

    testWidgets('a set button reveals a when view in place, without sending',
        (tester) async {
      // The exact scenario from the bug: tapping "Add Habit" should reveal the
      // form inline, not send a chat message and spawn a new UI.
      String? sent;
      var state = <String, dynamic>{};
      await tester.pumpWidget(_host(StatefulBuilder(
        builder: (context, setLocal) => GenUiStateScope(
          state: state,
          onChanged: (next) => setLocal(() => state = next),
          child: Builder(
            builder: (c) => buildGenUiSpec(
              c,
              {
                'type': 'column',
                'children': [
                  {'type': 'button', 'label': 'Add Habit', 'set': {'view': 'new'}},
                  {
                    'type': 'when',
                    'key': 'view',
                    'equals': 'new',
                    'child': {'type': 'text', 'text': 'New Habit Form'},
                  },
                ],
              },
              actions(onSend: (s) => sent = s),
            ),
          ),
        ),
      )));
      expect(find.text('New Habit Form'), findsNothing); // hidden initially
      await tester.tap(find.text('Add Habit'));
      await tester.pumpAndSettle();
      expect(find.text('New Habit Form'), findsOneWidget); // revealed in place
      expect(sent, isNull); // no chat turn sent
    });
  });

  group('accessibility (Semantics)', () {
    testWidgets('GenUiPressable with semanticLabel exposes label and button flag',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(GenUiPressable(
        onTap: () {},
        semanticLabel: 'Send',
        child: const Icon(Icons.send_rounded),
      )));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Send')),
        matchesSemantics(label: 'Send', isButton: true, hasEnabledState: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('a disabled GenUiPressable still announces as a button',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const GenUiPressable(
        onTap: null,
        semanticLabel: 'Send',
        child: Icon(Icons.send_rounded),
      )));

      expect(
        tester.getSemantics(find.bySemanticsLabel('Send')),
        matchesSemantics(label: 'Send', isButton: true, hasEnabledState: true),
      );
      handle.dispose();
    });

    testWidgets('RatingRenderer stars expose spoken labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {'type': 'rating', 'max': 5},
          actions(),
        ),
      )));

      expect(find.bySemanticsLabel('1 of 5 stars'), findsOneWidget);
      expect(find.bySemanticsLabel('5 of 5 stars'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ProgressRenderer exposes a value matching the percent',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {'type': 'progress', 'label': 'Uploading', 'percent': 42},
          actions(),
        ),
      )));

      final node = tester.getSemantics(
          find.ancestor(of: find.byType(LinearProgressIndicator), matching: find.byType(Semantics)).first);
      expect(node.label, 'Uploading');
      expect(node.value, '42%');
      handle.dispose();
    });

    testWidgets('StepperRenderer increase/decrease/send buttons expose labels',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(
          c,
          {'type': 'stepper', 'label': 'Guests', 'min': 1, 'max': 9, 'value': 2},
          actions(),
        ),
      )));

      expect(find.bySemanticsLabel('Decrease'), findsOneWidget);
      expect(find.bySemanticsLabel('Increase'), findsOneWidget);
      expect(find.bySemanticsLabel('Send'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('CalculatorRenderer operator keys expose spoken-word labels',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(c, {'type': 'calculator'}, actions()),
      )));

      expect(find.bySemanticsLabel('multiply'), findsOneWidget);
      expect(find.bySemanticsLabel('divide'), findsOneWidget);
      expect(find.bySemanticsLabel('clear'), findsOneWidget);
      handle.dispose();
    });

    testWidgets(
        "TimerRenderer's live region does not change its label on every "
        'per-second tick (only on phase transitions)', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Builder(
        builder: (c) => buildGenUiSpec(c, {'type': 'timer', 'seconds': 5}, actions()),
      )));

      Finder liveRegion() => find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.label ?? '').startsWith('Timer'));

      expect(tester.getSemantics(liveRegion()).label, 'Timer ready, 00:05');

      // Start the timer -> phase transition, label should update once.
      expect(find.bySemanticsLabel('Start timer'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Start timer'));
      await tester.pump();
      expect(tester.getSemantics(liveRegion()).label, 'Timer started');

      // Per-second ticks must NOT change the live-region label.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getSemantics(liveRegion()).label, 'Timer started');
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getSemantics(liveRegion()).label, 'Timer started');

      // Pausing is a phase transition and should update the label.
      expect(find.bySemanticsLabel('Pause timer'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Pause timer'));
      await tester.pump();
      expect(tester.getSemantics(liveRegion()).label, startsWith('Timer paused at'));

      handle.dispose();
    });
  });
}
