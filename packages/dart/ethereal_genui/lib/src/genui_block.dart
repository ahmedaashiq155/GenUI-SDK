import 'package:flutter/material.dart';
import 'package:ethereal_genui_core/ethereal_genui_core.dart';

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

/// Calm fallback. With no [type] and not [malformed] (still streaming/unparsed)
/// it reads as "Preparing…"; with [malformed] set (closed fence that still
/// failed to parse/repair) it reads as "Couldn't render this block", danger-
/// tinted; with a fully-parsed but unsupported [type] it names it, so the
/// failure is legible rather than silent.
Widget genUiPlaceholder(BuildContext context, {String? type, bool malformed = false}) {
  final colors = GenUiColors.of(context);
  final label = malformed
      ? "Couldn't render this block"
      : (type != null && type.isNotEmpty)
          ? 'Unsupported block: $type'
          : 'Preparing…';
  final iconColor = malformed ? colors.danger : colors.textTertiary;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
    padding: const EdgeInsets.symmetric(horizontal: GenUiSpace.md, vertical: GenUiSpace.sm),
    decoration: ShapeDecoration(
      color: colors.surface.withValues(alpha: 0.5),
      shape: GenUiShape.shape(GenUiRadii.md,
          side: BorderSide(color: malformed ? colors.danger.withValues(alpha: 0.3) : colors.hairline)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(malformed ? Icons.error_outline_rounded : Icons.widgets_outlined,
            size: 15, color: iconColor),
        const SizedBox(width: GenUiSpace.sm),
        Flexible(child: Text(label, style: TextStyle(color: iconColor, fontSize: 13))),
      ],
    ),
  );
}

/// Parses a model-authored `ui` JSON block and renders it. Tolerant of partial
/// JSON during streaming: [tryParsePartialJson] repairs a still-open fence so
/// it renders progressively instead of waiting for the closing brace.
class GenUiBlock extends StatelessWidget {
  const GenUiBlock({
    super.key,
    required this.raw,
    required this.actions,
    this.closed = true,
  });

  final String raw;
  final GenUiActions actions;

  /// Whether the source fence has finished streaming. Defaults to `true` so
  /// existing call sites that don't know about streaming keep their old
  /// behaviour (an unparseable block reads as malformed, not "Preparing…").
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return genUiPlaceholder(context);

    final spec = tryParsePartialJson(trimmed);
    if (spec == null) {
      return closed
          ? genUiPlaceholder(context, malformed: true)
          : genUiPlaceholder(context);
    }
    return buildGenUiSpec(context, spec, actions);
  }
}
