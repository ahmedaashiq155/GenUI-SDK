import 'package:flutter/material.dart';

import 'genui_theme.dart';

export 'package:ethereal_genui_core/ethereal_genui_core.dart' show GenUiOption, genUiOptions;

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
    String? semanticLabel,
  }) {
    final colors = GenUiColors.of(context);
    final isFilled = filled || selected;
    return GenUiPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
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
    VoidCallback? onTap, {
    String? semanticLabel,
  }) {
    final colors = GenUiColors.of(context);
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: GenUiPressable(
        onTap: onTap,
        haptic: false,
        semanticLabel: semanticLabel,
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
