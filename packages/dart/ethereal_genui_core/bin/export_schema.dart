/// Exports `schema/genui.schema.json` from the genUiCatalog.
///
/// Run from the repo root:
///   dart run packages/dart/ethereal_genui_core/bin/export_schema.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:ethereal_genui_core/ethereal_genui_core.dart';

void main() {
  final properties = <String, dynamic>{};

  for (final block in genUiCatalog) {
    final fieldProps = <String, dynamic>{};
    for (final field in block.fields) {
      fieldProps[field.name] = _fieldSchema(field);
    }

    final required = block.fields
        .where((f) => f.required)
        .map((f) => f.name)
        .toList();

    final blockSchema = <String, dynamic>{
      'type': 'object',
      'properties': {
        'type': {'type': 'string', 'const': block.type},
        ...fieldProps,
      },
      if (required.isNotEmpty) 'required': ['type', ...required],
    };

    properties[block.type] = blockSchema;
    for (final alias in block.aliases) {
      properties[alias] = {
        ...blockSchema,
        'properties': {
          ...blockSchema['properties'] as Map<String, dynamic>,
          'type': {'type': 'string', 'const': alias},
        },
      };
    }
  }

  final schema = {
    r'$schema': 'http://json-schema.org/draft-07/schema#',
    'title': 'GenUI Block',
    'description': 'JSON Schema for Ethereal GenUI blocks (v$genUiSchemaVersion)',
    'oneOf': [
      for (final key in properties.keys)
        {r'$ref': '#/definitions/$key'},
    ],
    'definitions': properties,
  };

  // bin/ is two levels below the package root; schema/ is at the repo root
  // (two levels above the package root = four levels above bin/).
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final outFile = File('${scriptDir.path}/../../../../schema/genui.schema.json');
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(schema),
  );
  print('Wrote ${outFile.path}');
}

Map<String, dynamic> _fieldSchema(GenUiField field) {
  return switch (field.type) {
    'string' => {'type': 'string'},
    'int' || 'num' || 'double' => {'type': 'number'},
    'bool' => {'type': 'boolean'},
    'list' => {'type': 'array'},
    'map' => {'type': 'object'},
    'color' => {'type': 'string', 'format': 'color'},
    'enum' => {
        'type': 'string',
        'enum': field.enumValues ?? const <String>[],
      },
    _ => {'type': 'string'},
  };
}
