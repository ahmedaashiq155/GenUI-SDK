import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_common.dart';

Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var h = hex.trim().replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final value = int.tryParse(h, radix: 16);
  return value == null ? null : Color(value);
}

/// {"type":"theme","accent":"#8B93FF"} — recolors this conversation.
class ThemeDirectiveRenderer extends StatefulWidget {
  const ThemeDirectiveRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<ThemeDirectiveRenderer> createState() => _ThemeDirectiveRendererState();
}

class _ThemeDirectiveRendererState extends State<ThemeDirectiveRenderer> {
  @override
  void initState() {
    super.initState();
    final hex = widget.spec['accent']?.toString();
    if (hex != null && parseHexColor(hex) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.actions.setAccent?.call(hex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final swatch = parseHexColor(widget.spec['accent']?.toString()) ?? colors.accent;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
      padding: const EdgeInsets.all(GenUiSpace.md),
      decoration: ShapeDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        shape: GenUiShape.shape(GenUiRadii.md, side: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
          ),
          const SizedBox(width: GenUiSpace.sm),
          Text('Accent tuned for this chat',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

/// {"type":"shortcuts","items":["Plan my week","Summarize a doc"]}
/// Saves quick-actions to the home screen and offers them inline too.
class ShortcutsDirectiveRenderer extends StatefulWidget {
  const ShortcutsDirectiveRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<ShortcutsDirectiveRenderer> createState() =>
      _ShortcutsDirectiveRendererState();
}

class _ShortcutsDirectiveRendererState extends State<ShortcutsDirectiveRenderer> {
  late final List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = (widget.spec['items'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (_items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.actions.setShortcuts?.call(_items);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final colors = GenUiColors.of(context);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Text('Saved to your shortcuts',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary)),
            ],
          ),
          const SizedBox(height: GenUiSpace.sm),
          Wrap(
            spacing: GenUiSpace.sm,
            runSpacing: GenUiSpace.sm,
            children: [
              for (final s in _items)
                GenUi.pill(context, s,
                    widget.actions.enabled ? () => widget.actions.sendMessage(s) : null),
            ],
          ),
        ],
      ),
    );
  }
}
