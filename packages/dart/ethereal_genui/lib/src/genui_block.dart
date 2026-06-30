import 'dart:convert';

import 'package:flutter/material.dart';

import 'genui_theme.dart';
import 'genui_actions.dart';
import 'genui_registry.dart';

/// Builds the widget for a parsed `ui` spec by looking the type up in the
/// pluggable [defaultGenUiRegistry]. Top-level so layout containers can render
/// their children recursively. Unknown types degrade to a calm placeholder.
Widget buildGenUiSpec(
  BuildContext context,
  Map<String, dynamic> spec,
  GenUiActions actions,
) {
  final type = (spec['type'] ?? '').toString();
  final builder = defaultGenUiRegistry.builderFor(type);
  if (builder != null) return builder(context, spec, actions);
  return genUiPlaceholder(context, type: type);
}

/// Calm fallback. With no [type] (still streaming/unparsed) it reads as
/// "Preparing…"; with a fully-parsed but unsupported [type] it names it, so the
/// failure is legible rather than silent.
Widget genUiPlaceholder(BuildContext context, {String? type}) {
  final colors = GenUiColors.of(context);
  final label = (type != null && type.isNotEmpty) ? 'Unsupported block: $type' : 'Preparing…';
  return Container(
    margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
    padding: const EdgeInsets.symmetric(horizontal: GenUiSpace.md, vertical: GenUiSpace.sm),
    decoration: ShapeDecoration(
      color: colors.surface.withValues(alpha: 0.5),
      shape: GenUiShape.shape(GenUiRadii.md, side: BorderSide(color: colors.hairline)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.widgets_outlined, size: 15, color: colors.textTertiary),
        const SizedBox(width: GenUiSpace.sm),
        Flexible(
          child: Text(label,
              style: TextStyle(color: colors.textTertiary, fontSize: 13)),
        ),
      ],
    ),
  );
}

/// Parses a model-authored `ui` JSON block and renders it. Tolerant of partial
/// JSON during streaming (shows the placeholder until it parses).
class GenUiBlock extends StatelessWidget {
  const GenUiBlock({super.key, required this.raw, required this.actions});

  final String raw;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return genUiPlaceholder(context);
    Map<String, dynamic>? spec;
    try {
      final value = jsonDecode(trimmed);
      if (value is Map<String, dynamic>) spec = value;
    } catch (_) {
      spec = null;
    }
    if (spec == null) return genUiPlaceholder(context);
    return buildGenUiSpec(context, spec, actions);
  }
}
