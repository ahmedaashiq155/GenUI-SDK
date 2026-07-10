import 'package:flutter/material.dart';
import 'package:ethereal_genui_core/ethereal_genui_core.dart';

import 'genui_theme.dart';
import 'genui_actions.dart';
import 'genui_registry.dart';

/// Maximum nesting depth for a single spec tree. A malicious or buggy model
/// can emit a spec nested thousands of levels deep (e.g. a box inside a box…);
/// without a cap that overflows the widget-build stack and crashes the app
/// past any Flutter error boundary. 24 is far deeper than any real layout.
const int kGenUiMaxDepth = 24;

/// Propagates the current nesting depth down the widget tree so
/// [buildGenUiSpec] can refuse to recurse past [kGenUiMaxDepth].
class _GenUiDepth extends InheritedWidget {
  const _GenUiDepth({required this.depth, required super.child});
  final int depth;

  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GenUiDepth>()?.depth ?? 0;

  @override
  bool updateShouldNotify(_GenUiDepth old) => old.depth != depth;
}

/// Shares one synchronous message-dispatch lock across a whole rendered spec
/// tree. Local interactions still use their normal callbacks; only
/// [GenUiActions.sendMessage] passes through this scope.
class _GenUiDispatchScope extends InheritedWidget {
  const _GenUiDispatchScope({required this.actions, required super.child});

  final GenUiActions actions;

  static _GenUiDispatchScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_GenUiDispatchScope>();

  @override
  bool updateShouldNotify(_GenUiDispatchScope old) =>
      old.actions.enabled != actions.enabled || old.actions != actions;
}

class _GenUiDispatchBoundary extends StatefulWidget {
  const _GenUiDispatchBoundary({required this.spec, required this.actions});

  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<_GenUiDispatchBoundary> createState() => _GenUiDispatchBoundaryState();
}

class _GenUiDispatchBoundaryState extends State<_GenUiDispatchBoundary> {
  bool _dispatched = false;

  @override
  void didUpdateWidget(_GenUiDispatchBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.actions.enabled && widget.actions.enabled) {
      _dispatched = false;
    }
  }

  void _sendMessage(String text) {
    if (!widget.actions.enabled || _dispatched) return;
    setState(() => _dispatched = true);
    widget.actions.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final actions = GenUiActions(
      sendMessage: _sendMessage,
      setAccent: widget.actions.setAccent,
      setShortcuts: widget.actions.setShortcuts,
      openArtifact: widget.actions.openArtifact,
      enabled: widget.actions.enabled && !_dispatched,
    );
    return _GenUiDispatchScope(
      actions: actions,
      child: Builder(
        builder: (context) => _buildGenUiSpec(context, widget.spec, actions),
      ),
    );
  }
}

/// Builds the widget for a parsed `ui` spec by looking the type up in the
/// pluggable [defaultGenUiRegistry]. Top-level so layout containers can render
/// their children recursively. Unknown types degrade to a calm placeholder,
/// and nesting past [kGenUiMaxDepth] degrades the same way instead of
/// overflowing the stack.
Widget buildGenUiSpec(
  BuildContext context,
  Map<String, dynamic> spec,
  GenUiActions actions,
) {
  final dispatchScope = _GenUiDispatchScope.maybeOf(context);
  if (dispatchScope == null) {
    return _GenUiDispatchBoundary(spec: spec, actions: actions);
  }
  return _buildGenUiSpec(context, spec, dispatchScope.actions);
}

Widget _buildGenUiSpec(
  BuildContext context,
  Map<String, dynamic> spec,
  GenUiActions actions,
) {
  final depth = _GenUiDepth.of(context);
  if (depth >= kGenUiMaxDepth) {
    return genUiPlaceholder(context, malformed: true);
  }
  final type = (spec['type'] ?? '').toString();
  final builder = defaultGenUiRegistry.builderFor(type);
  final child = builder != null
      ? builder(context, spec, actions)
      : genUiPlaceholder(context, type: type);
  return _GenUiDepth(depth: depth + 1, child: child);
}

/// Calm fallback. With no [type] and not [malformed] (still streaming/unparsed)
/// it reads as "Preparing…"; with [malformed] set (closed fence that still
/// failed to parse/repair) it reads as "Couldn't render this block", danger-
/// tinted; with a fully-parsed but unsupported [type] it names it, so the
/// failure is legible rather than silent.
Widget genUiPlaceholder(
  BuildContext context, {
  String? type,
  bool malformed = false,
}) {
  final colors = GenUiColors.of(context);
  final label = malformed
      ? "Couldn't render this block"
      : (type != null && type.isNotEmpty)
      ? 'Unsupported block: $type'
      : 'Preparing…';
  final iconColor = malformed ? colors.danger : colors.textTertiary;
  return Container(
    margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
    padding: const EdgeInsets.symmetric(
      horizontal: GenUiSpace.md,
      vertical: GenUiSpace.sm,
    ),
    decoration: ShapeDecoration(
      color: colors.surface.withValues(alpha: 0.5),
      shape: GenUiShape.shape(
        GenUiRadii.md,
        side: BorderSide(
          color: malformed
              ? colors.danger.withValues(alpha: 0.3)
              : colors.hairline,
        ),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          malformed ? Icons.error_outline_rounded : Icons.widgets_outlined,
          size: 15,
          color: iconColor,
        ),
        const SizedBox(width: GenUiSpace.sm),
        Flexible(
          child: Text(label, style: TextStyle(color: iconColor, fontSize: 13)),
        ),
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
