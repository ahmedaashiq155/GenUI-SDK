import 'package:flutter/material.dart';

import 'genui_theme.dart';

/// A normalized choice/option. The model may emit a plain string (`"Daily"`) OR
/// an object (`{"label":"Daily","value":"daily"}`, `{"label":"x","checked":true,
/// "send":"y"}`). Renderers must never show the raw map — always read [label]
/// for display and [value] for the action.
class GenUiOption {
  const GenUiOption({required this.label, required this.value, this.checked = false});
  final String label;
  final String value;
  final bool checked;
}

/// Normalize a model-supplied list of options/items into [GenUiOption]s,
/// tolerating both string and object forms.
List<GenUiOption> genUiOptions(dynamic raw) {
  final list = raw is List ? raw : const [];
  final out = <GenUiOption>[];
  for (final e in list) {
    if (e is Map) {
      final label =
          (e['label'] ?? e['text'] ?? e['title'] ?? e['name'] ?? e['value'] ?? '')
              .toString();
      final value = (e['value'] ?? e['send'] ?? e['label'] ?? label).toString();
      out.add(GenUiOption(label: label, value: value, checked: e['checked'] == true));
    } else {
      final s = e.toString();
      out.add(GenUiOption(label: s, value: s));
    }
  }
  return out;
}

/// Shared ethereal building blocks for generative-UI renderers.
abstract final class GenUi {
  /// The clean card surface every GenUI block sits in. A neutral surface with a
  /// hairline edge and a soft shadow — restrained depth (Apple/Linear-grade)
  /// rather than a washed accent tint.
  static Widget frame(BuildContext context, {required Widget child}) {
    final colors = GenUiColors.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
      padding: const EdgeInsets.all(GenUiSpace.lg),
      decoration: ShapeDecoration(
        color: colors.surface,
        shape: GenUiShape.shape(
          GenUiRadii.lg,
          side: BorderSide(color: colors.hairline),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget title(BuildContext context, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final colors = GenUiColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: GenUiSpace.md),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
      ),
    );
  }

  /// A pill button. [filled]/[selected] give the accent treatment; otherwise a
  /// light, calm chip — accent is reserved for the active state.
  static Widget pill(
    BuildContext context,
    String label,
    VoidCallback? onTap, {
    bool filled = false,
    IconData? icon,
    bool selected = false,
  }) {
    final colors = GenUiColors.of(context);
    final isFilled = filled || selected;
    return GenUiPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GenUiMotion.quick,
        padding: const EdgeInsets.symmetric(
          horizontal: GenUiSpace.md + 2,
          vertical: GenUiSpace.sm + 1,
        ),
        decoration: ShapeDecoration(
          color: isFilled
              ? colors.accent
              : colors.accent.withValues(alpha: 0.10),
          shape: GenUiShape.shape(GenUiRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: isFilled ? colors.onAccent : colors.accent),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isFilled ? colors.onAccent : colors.accent,
                fontWeight: isFilled ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A submit/primary action button spanning the row.
  static Widget submitButton(
    BuildContext context,
    String label,
    VoidCallback? onTap,
  ) {
    final colors = GenUiColors.of(context);
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: GenUiPressable(
        onTap: onTap,
        haptic: false,
        child: AnimatedContainer(
          duration: GenUiMotion.quick,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: GenUiSpace.md + 2),
          decoration: ShapeDecoration(
            color: enabled
                ? colors.accent
                : colors.textTertiary.withValues(alpha: 0.16),
            shape: GenUiShape.shape(GenUiRadii.md),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? colors.onAccent : colors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
