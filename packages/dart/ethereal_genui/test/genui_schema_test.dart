import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prompt catalogue (single source of truth)', () {
    final catalogue = buildGenUiPromptCatalogue();

    test('mentions every canonical block type', () {
      // Aliases (kpi/container/steps/chips) are tolerant-render only and are not
      // advertised to the model — only canonical forms appear in the catalogue.
      for (final block in genUiCatalog) {
        expect(catalogue, contains('"type":"${block.type}"'),
            reason: 'catalogue is missing type "${block.type}"');
      }
    });

    test('keeps the key framing lines', () {
      expect(catalogue, contains('language `ui`'));
      expect(catalogue, contains('use UI sparingly'));
      expect(catalogue, contains('Freeform primitives'));
      expect(catalogue, contains('Prefer the high-level components'));
      // The icon-name hint must survive (it lives in the icon block note).
      expect(catalogue, contains('rocket trophy'));
    });

    test('is reasonably compact', () {
      // Guard against accidental bloat (the hand-written blob was ~3.5k chars).
      expect(catalogue.length, lessThan(5500));
    });
  });

  group('catalog ↔ renderer drift guard', () {
    // The exact set of model-facing types rendered by buildGenUiSpec()
    // (genui_block.dart), excluding `tool_call` which is produced internally by
    // the tool loop, not emitted by the model. If a renderer is added/removed,
    // this list and the catalog must change together.
    const renderableTypes = {
      'choices', 'actions', 'confirm', 'suggestions', 'input', 'multiselect',
      'slider', 'form', 'rating', 'segmented', 'stepper', 'checklist', 'poll',
      'quiz', 'card', 'callout', 'stat', 'kpi', 'table', 'chart', 'artifact',
      'theme', 'shortcuts', 'timeline', 'steps', 'progress', 'badges', 'chips',
      'gallery', 'divider', 'calculator', 'converter', 'timer', 'section',
      'grid', 'columns', 'accordion', 'tabs', 'when', 'box', 'container', 'row',
      'column', 'stack', 'text', 'icon', 'button', 'spacer',
    };

    test('catalog covers exactly the renderable types', () {
      expect(genUiKnownTypes, equals(renderableTypes));
    });
  });

  group('validateGenUiSpec', () {
    test('accepts a nested spec without false positives', () {
      // A section containing a form, a poll, and a card — whose field/option
      // descriptors legitimately have no block "type". None should be flagged.
      final spec = {
        'type': 'section',
        'title': 'Booking',
        'children': [
          {
            'type': 'form',
            'fields': [
              {'key': 'name', 'label': 'Name', 'type': 'text'},
              {'key': 'guests', 'label': 'Guests', 'type': 'number'},
            ],
          },
          {
            'type': 'poll',
            'options': [
              {'label': 'A', 'votes': 3},
              {'label': 'B', 'votes': 1},
            ],
          },
          {
            'type': 'card',
            'items': [
              {'label': 'Key', 'value': 'Val'},
            ],
          },
        ],
      };
      final result = validateGenUiSpec(spec);
      expect(result.isValid, isTrue, reason: result.issues.join('; '));
    });

    test('validates nested blocks inside tabs/accordion content', () {
      final spec = {
        'type': 'tabs',
        'tabs': [
          {
            'label': 'One',
            'content': {'type': 'totally-bogus'},
          },
        ],
      };
      final result = validateGenUiSpec(spec);
      expect(result.hasUnknownType, isTrue);
    });

    test('validates a nested block in when.child', () {
      final result = validateGenUiSpec({
        'type': 'when',
        'key': 'view',
        'child': {'type': 'totally-bogus'},
      });
      expect(result.hasUnknownType, isTrue);
      expect(result.issues.single.path, r'$.child');
    });

    test('flags an unknown type', () {
      final result = validateGenUiSpec({'type': 'no-such-block'});
      expect(result.isValid, isFalse);
      expect(result.hasUnknownType, isTrue);
    });

    test('flags a missing required field', () {
      // `confirm` requires "prompt".
      final result = validateGenUiSpec({'type': 'confirm'});
      expect(result.isValid, isFalse);
      expect(result.issues.map((i) => i.message).join(),
          contains('required field "prompt"'));
    });

    test('resolves aliases (kpi → stat)', () {
      expect(genUiSchemaFor('kpi')?.type, 'stat');
      expect(genUiSchemaFor('container')?.type, 'box');
    });
  });
}
