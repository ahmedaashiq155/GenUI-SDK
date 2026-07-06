import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_common.dart';

Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var h = hex.trim().replaceAll('#', '');
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  // 8-digit input follows the CSS RRGGBBAA convention (the schema's own
  // examples use e.g. "#ffffff22"); Color() expects AARRGGBB, so move the
  // trailing alpha byte to the front.
  if (h.length == 8) h = h.substring(6) + h.substring(0, 6);
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final value = int.tryParse(h, radix: 16);
  return value == null ? null : Color(value);
}

/// {"type":"theme","accent":"#8B93FF"} — offers to recolor this conversation.
///
/// The accent is only applied after an explicit user tap. Directives must
/// never fire host side effects just by being rendered: the spec is untrusted
/// model output, and silently restyling the app on render is a prompt-
/// injection foothold.
class ThemeDirectiveRenderer extends StatefulWidget {
  const ThemeDirectiveRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<ThemeDirectiveRenderer> createState() => _ThemeDirectiveRendererState();
}

class _ThemeDirectiveRendererState extends State<ThemeDirectiveRenderer> {
  bool _applied = false;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final hex = widget.spec['accent']?.toString();
    final swatch = parseHexColor(hex);
    final canApply = swatch != null &&
        widget.actions.setAccent != null &&
        widget.actions.enabled &&
        !_applied;
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
            decoration: BoxDecoration(color: swatch ?? colors.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: GenUiSpace.sm),
          Expanded(
            child: Text(
                _applied ? 'Accent tuned for this chat' : 'Suggested accent for this chat',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.textSecondary)),
          ),
          if (_applied)
            Icon(Icons.check_rounded, size: 18, color: colors.accent)
          else if (canApply)
            GenUi.pill(context, 'Apply', () {
              setState(() => _applied = true);
              widget.actions.setAccent?.call(hex!);
            }),
        ],
      ),
    );
  }
}

/// {"type":"shortcuts","items":["Plan my week","Summarize a doc"]}
/// Offers quick-actions inline and, after an explicit user tap, saves them
/// via the host's setShortcuts callback.
///
/// Persisting is gated on a user tap for the same reason as the theme
/// directive — saved shortcuts replay their text as a user message later, so
/// letting a rendered spec store them silently would give an injected prompt
/// a durable, cross-session foothold.
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
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.spec['items'];
    _items = (raw is List ? raw : const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final colors = GenUiColors.of(context);
    final canSave = widget.actions.setShortcuts != null &&
        widget.actions.enabled &&
        !_saved;
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                    _saved ? 'Saved to your shortcuts' : 'Suggested shortcuts',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.textSecondary)),
              ),
              if (_saved)
                Icon(Icons.check_rounded, size: 18, color: colors.accent)
              else if (canSave)
                GenUi.pill(context, 'Save', () {
                  setState(() => _saved = true);
                  widget.actions.setShortcuts?.call(_items);
                }),
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
