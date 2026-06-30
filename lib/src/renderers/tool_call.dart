import 'dart:convert';

import 'package:flutter/material.dart';

import '../genui_theme.dart';

/// {"type":"tool_call","name":"calculator","args":{…},"result":"…"}
/// A collapsible card showing a tool invocation and its result.
class ToolCallRenderer extends StatefulWidget {
  const ToolCallRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  State<ToolCallRenderer> createState() => _ToolCallRendererState();
}

class _ToolCallRendererState extends State<ToolCallRenderer> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final name = (widget.spec['name'] ?? 'tool').toString();
    final result = (widget.spec['result'] ?? '').toString();
    final running = widget.spec['result'] == null;
    final args = widget.spec['args'];
    final argsText = args is Map || args is List ? jsonEncode(args) : '${args ?? ''}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
      decoration: ShapeDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        shape: GenUiShape.shape(GenUiRadii.md, side: BorderSide(color: colors.hairline)),
      ),
      child: Column(
        children: [
          GenUiPressable(
            haptic: false,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(GenUiSpace.md),
              child: Row(
                children: [
                  Icon(running ? Icons.bolt_rounded : Icons.check_circle_rounded,
                      size: 18, color: running ? colors.accent : colors.celadon),
                  const SizedBox(width: GenUiSpace.sm),
                  Text('Tool · $name',
                      style: text.bodyMedium?.copyWith(
                          color: colors.textSecondary, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (running)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                    )
                  else
                    Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 18, color: colors.textTertiary),
                ],
              ),
            ),
          ),
          if (_open || running)
            Padding(
              padding: const EdgeInsets.fromLTRB(GenUiSpace.md, 0, GenUiSpace.md, GenUiSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (argsText.isNotEmpty)
                    Text(argsText,
                        style: TextStyle(
                            color: colors.textTertiary,
                            fontFamily: 'RobotoMono',
                            fontSize: 12)),
                  if (!running && result.isNotEmpty) ...[
                    const SizedBox(height: GenUiSpace.xs),
                    Text(result,
                        style: text.bodyLarge?.copyWith(color: colors.textPrimary)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
