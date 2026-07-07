// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import '../lib/src/genui_schema.dart';
import '../lib/src/genui_options.dart';

String serializeValidation(GenUiValidation v) {
  return jsonEncode({
    'isValid': v.isValid,
    'issues': v.issues.map((i) => {'path': i.path, 'message': i.message}).toList(),
  });
}

void main() {
  final schemaDir = Directory('schema');
  if (!schemaDir.existsSync()) schemaDir.createSync();

  // Prompt catalogue fixture
  final prompt = buildGenUiPromptCatalogue();
  File('schema/genui_prompt_fixture.txt').writeAsStringSync(prompt);
  print('Wrote prompt fixture (${prompt.length} chars)');

  // Validate fixtures
  final goodSpec = {
    'type': 'choices',
    'title': 'Pick one',
    'options': [
      {'label': 'A', 'value': 'a'},
      {'label': 'B', 'value': 'b'},
    ],
  };
  final goodResult = validateGenUiSpec(goodSpec);
  print('Good spec validation: ${serializeValidation(goodResult)}');

  final badSpec = {'type': 'unknown_block_type'};
  final badResult = validateGenUiSpec(badSpec);
  print('Bad spec validation: ${serializeValidation(badResult)}');

  final missingTypeSpec = {'title': 'No type'};
  final missingResult = validateGenUiSpec(missingTypeSpec);
  print('Missing type validation: ${serializeValidation(missingResult)}');

  // genUiOptions fixture
  final options = genUiOptions([
    {'label': 'Alpha', 'value': 'a'},
    {'text': 'Beta', 'value': 'b'},
    {'name': 'Gamma', 'value': 'c'},
    {'value': 'd'},
  ]);
  final optionsJson = jsonEncode(options.map((o) => {'label': o.label, 'value': o.value}).toList());
  File('schema/genui_options_fixture.json').writeAsStringSync(optionsJson);
  print('Options fixture: $optionsJson');

  // Catalog block types fixture
  final types = genUiCatalog.map((s) => s.type).toList()..sort();
  File('schema/genui_block_types_fixture.json').writeAsStringSync(jsonEncode(types));
  print('Block types (${types.length}): ${types.join(', ')}');
}
