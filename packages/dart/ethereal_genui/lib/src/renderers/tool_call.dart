import 'dart:convert';

import 'package:flutter/material.dart';

import '../genui_common.dart';
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
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final name = (widget.spec['name'] ?? 'tool').toString();
    final result = (widget.spec['result'] ?? '').toString();
    final running = widget.spec['result'] == null;
    final args = widget.spec['args'];
    final argsText = args is Map || args is List
        ? jsonEncode(args)
        : '${args ?? ''}';

    return GenUi.frame(
      context,
      variant: GenUiFrameVariant.flat,
      margin: EdgeInsets.symmetric(vertical: theme.spacing.sm),
      padding: EdgeInsets.zero,
      radius: theme.radii.md,
      backgroundColor: colors.surface.withValues(alpha: 0.5),
      child: Column(
        children: [
          GenUiPressable(
            haptic: false,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: EdgeInsets.all(theme.spacing.md),
              child: Row(
                children: [
                  Icon(
                    running ? Icons.bolt_rounded : Icons.check_circle_rounded,
                    size: 18,
                    color: running ? colors.accent : colors.celadon,
                  ),
                  const SizedBox(width: GenUiSpace.sm),
                  Text(
                    'Tool · $name',
                    style: text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (running)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accent,
                      ),
                    )
                  else
                    Icon(
                      _open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: colors.textTertiary,
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: theme.motion.standard,
            curve: theme.motion.curve,
            alignment: AlignmentDirectional.topStart,
            child: _open || running
                ? Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      theme.spacing.md,
                      0,
                      theme.spacing.md,
                      theme.spacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (argsText.isNotEmpty)
                          Text(
                            argsText,
                            style: text.bodySmall?.copyWith(
                              color: colors.textTertiary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if (!running && result.isNotEmpty) ...[
                          SizedBox(height: theme.spacing.xs),
                          Text(
                            result,
                            style: text.bodyLarge?.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
