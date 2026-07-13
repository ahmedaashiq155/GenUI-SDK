import 'package:flutter/widgets.dart';

import 'genui_actions.dart';
import 'renderers/artifact.dart';
import 'renderers/animation.dart';
import 'renderers/charts.dart';
import 'renderers/containers.dart';
import 'renderers/decisions.dart';
import 'renderers/directives.dart';
import 'renderers/display.dart';
import 'renderers/inputs.dart';
import 'renderers/interactive.dart';
import 'renderers/minitools.dart';
import 'renderers/primitives.dart';
import 'renderers/tool_call.dart';

/// Builds the widget for a single parsed `ui` block. Every renderer conforms to
/// this signature; display-only renderers simply ignore [actions].
typedef GenUiBuilder =
    Widget Function(
      BuildContext context,
      Map<String, dynamic> spec,
      GenUiActions actions,
    );

/// A `type` → renderer map. Adding a block type is one `register` call — no
/// edits to a central switch — so host apps can extend the catalog without
/// forking. The built-in catalog is [defaultGenUiRegistry].
class GenUiRegistry {
  final Map<String, GenUiBuilder> _builders = {};

  /// Register (or override) the renderer for [type].
  void register(String type, GenUiBuilder builder) => _builders[type] = builder;

  /// Register one builder under several type strings (canonical + aliases).
  void registerAll(Iterable<String> types, GenUiBuilder builder) {
    for (final type in types) {
      _builders[type] = builder;
    }
  }

  bool contains(String type) => _builders.containsKey(type);

  GenUiBuilder? builderFor(String type) => _builders[type];

  /// All registered type strings (for drift checks / docs).
  Set<String> get types => _builders.keys.toSet();
}

/// The built-in registry. Mirrors the catalog in `genui_schema.dart`; the
/// internal `tool_call` card (produced by the tool loop, not emitted by the
/// model) is also registered here.
final GenUiRegistry defaultGenUiRegistry = GenUiRegistry()
  // Decisions & quick replies
  ..register('choices', (c, s, a) => ChoicesRenderer(spec: s, actions: a))
  ..register('actions', (c, s, a) => ActionsRenderer(spec: s, actions: a))
  ..register('confirm', (c, s, a) => ConfirmRenderer(spec: s, actions: a))
  ..register(
    'suggestions',
    (c, s, a) => SuggestionsRenderer(spec: s, actions: a),
  )
  // Inputs & forms
  ..register('input', (c, s, a) => InputRenderer(spec: s, actions: a))
  ..register(
    'multiselect',
    (c, s, a) => MultiSelectRenderer(spec: s, actions: a),
  )
  ..register('slider', (c, s, a) => SliderRenderer(spec: s, actions: a))
  ..register('form', (c, s, a) => FormRenderer(spec: s, actions: a))
  // More interactive
  ..register('rating', (c, s, a) => RatingRenderer(spec: s, actions: a))
  ..register('segmented', (c, s, a) => SegmentedRenderer(spec: s, actions: a))
  ..register('stepper', (c, s, a) => StepperRenderer(spec: s, actions: a))
  ..register('checklist', (c, s, a) => ChecklistRenderer(spec: s, actions: a))
  ..register('poll', (c, s, a) => PollRenderer(spec: s, actions: a))
  ..register('quiz', (c, s, a) => QuizRenderer(spec: s, actions: a))
  // Display
  ..register('card', (c, s, a) => CardRenderer(spec: s))
  ..register('callout', (c, s, a) => CalloutRenderer(spec: s))
  ..registerAll(['stat', 'kpi'], (c, s, a) => StatRenderer(spec: s))
  ..register('table', (c, s, a) => TableRenderer(spec: s))
  ..register('chart', (c, s, a) => ChartRenderer(spec: s))
  ..register('artifact', (c, s, a) => ArtifactRenderer(spec: s, actions: a))
  ..register('tool_call', (c, s, a) => ToolCallRenderer(spec: s))
  // App-adaptive directives
  ..register('theme', (c, s, a) => ThemeDirectiveRenderer(spec: s, actions: a))
  ..register(
    'shortcuts',
    (c, s, a) => ShortcutsDirectiveRenderer(spec: s, actions: a),
  )
  // More display
  ..registerAll(['timeline', 'steps'], (c, s, a) => TimelineRenderer(spec: s))
  ..register('progress', (c, s, a) => ProgressRenderer(spec: s))
  ..registerAll(['badges', 'chips'], (c, s, a) => BadgesRenderer(spec: s))
  ..register('gallery', (c, s, a) => GalleryRenderer(spec: s))
  ..register('divider', (c, s, a) => const DividerRenderer())
  // Client-side mini-tools (zero round-trip)
  ..register('calculator', (c, s, a) => const CalculatorRenderer())
  ..register('converter', (c, s, a) => ConverterRenderer(spec: s))
  ..register('timer', (c, s, a) => TimerRenderer(spec: s))
  // Layout containers (recursive)
  ..register('section', (c, s, a) => SectionRenderer(spec: s, actions: a))
  ..register('grid', (c, s, a) => GridRenderer(spec: s, actions: a))
  ..register('columns', (c, s, a) => ColumnsRenderer(spec: s, actions: a))
  ..register('accordion', (c, s, a) => AccordionRenderer(spec: s, actions: a))
  ..register('tabs', (c, s, a) => TabsRenderer(spec: s, actions: a))
  ..register('when', (c, s, a) => WhenRenderer(spec: s, actions: a))
  ..register('animate', (c, s, a) => AnimationRenderer(spec: s, actions: a))
  // Freeform primitives
  ..registerAll([
    'box',
    'container',
  ], (c, s, a) => BoxRenderer(spec: s, actions: a))
  ..register('row', (c, s, a) => RowRenderer(spec: s, actions: a))
  ..register('column', (c, s, a) => ColumnRenderer(spec: s, actions: a))
  ..register('stack', (c, s, a) => StackRenderer(spec: s, actions: a))
  ..register('text', (c, s, a) => TextRenderer(spec: s))
  ..register('icon', (c, s, a) => IconRenderer(spec: s))
  ..register('button', (c, s, a) => ButtonRenderer(spec: s, actions: a))
  ..register('spacer', (c, s, a) => SpacerRenderer(spec: s));
