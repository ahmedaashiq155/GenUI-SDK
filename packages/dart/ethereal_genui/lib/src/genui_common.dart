import 'package:flutter/material.dart';

import 'genui_theme.dart';

export 'package:ethereal_genui_core/ethereal_genui_core.dart'
    show GenUiOption, genUiOptions;

enum GenUiFrameVariant { elevated, flat }

/// Suppresses redundant child frames inside an already-framed composition.
class GenUiFrameScope extends InheritedWidget {
  const GenUiFrameScope({
    super.key,
    this.suppress = true,
    required super.child,
  });

  final bool suppress;

  static GenUiFrameScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GenUiFrameScope>();

  @override
  bool updateShouldNotify(GenUiFrameScope oldWidget) =>
      suppress != oldWidget.suppress;
}

/// Supplies a readable default foreground to freeform descendants placed on a
/// model-authored background. Explicit text/icon colors still take precedence.
class GenUiForegroundScope extends InheritedWidget {
  const GenUiForegroundScope({
    super.key,
    required this.color,
    required super.child,
  });

  final Color color;

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GenUiForegroundScope>()?.color;

  @override
  bool updateShouldNotify(GenUiForegroundScope oldWidget) =>
      color != oldWidget.color;
}

/// WCAG contrast utilities used when an untrusted spec supplies a color.
abstract final class GenUiContrast {
  static double ratio(Color a, Color b) {
    final aLuminance = a.computeLuminance();
    final bLuminance = b.computeLuminance();
    final lighter = aLuminance > bLuminance ? aLuminance : bLuminance;
    final darker = aLuminance > bLuminance ? bLuminance : aLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static Color readableForeground(
    Color background, {
    required Color preferred,
    Color surface = Colors.white,
    double minimumRatio = 4.5,
  }) {
    final opaque = Color.alphaBlend(background, surface);
    if (ratio(preferred, opaque) >= minimumRatio) return preferred;
    final black = Colors.black;
    final white = Colors.white;
    return ratio(black, opaque) >= ratio(white, opaque) ? black : white;
  }
}

/// Shared ethereal building blocks for generative-UI renderers.
abstract final class GenUi {
  /// The clean card surface every GenUI block sits in. A neutral surface with a
  /// hairline edge and a soft shadow — restrained depth (Apple/Linear-grade)
  /// rather than a washed accent tint.
  static Widget frame(
    BuildContext context, {
    required Widget child,
    GenUiFrameVariant variant = GenUiFrameVariant.elevated,
    bool force = false,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? radius,
    Color? backgroundColor,
    BorderSide? border,
  }) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    if (!force && (GenUiFrameScope.maybeOf(context)?.suppress ?? false)) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.sm),
        child: child,
      );
    }
    final elevated = variant == GenUiFrameVariant.elevated;
    return Container(
      width: double.infinity,
      margin: margin ?? theme.frames.margin,
      padding: padding ?? theme.frames.padding,
      decoration: ShapeDecoration(
        color: backgroundColor ?? colors.surface,
        shape: GenUiShape.shape(
          radius ?? theme.radii.lg,
          side: border ?? BorderSide(color: colors.hairline),
        ),
        shadows: elevated && theme.frames.shadowOpacity > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: theme.frames.shadowOpacity,
                  ),
                  blurRadius: theme.frames.shadowBlur,
                  offset: theme.frames.shadowOffset,
                ),
              ]
            : const [],
      ),
      child: child,
    );
  }

  static Widget flatFrame(BuildContext context, {required Widget child}) =>
      frame(context, child: child, variant: GenUiFrameVariant.flat);

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

  /// A consistent, non-error state for an intentionally empty collection.
  static Widget emptyState(
    BuildContext context,
    String label, {
    IconData icon = Icons.inbox_outlined,
  }) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    return frame(
      context,
      child: Semantics(
        label: label,
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(icon, color: colors.textTertiary, size: 20),
              const SizedBox(width: GenUiSpace.sm),
              Expanded(
                child: Text(
                  label,
                  style: text.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
              ),
            ],
          ),
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
    bool? checked,
    String? semanticLabel,
  }) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final isFilled = filled || selected;
    return GenUiPressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      selected: selected,
      checked: checked,
      child: AnimatedContainer(
        duration: theme.motion.quick,
        curve: theme.motion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.md + 2,
          vertical: theme.spacing.sm,
        ),
        decoration: ShapeDecoration(
          color: isFilled
              ? colors.accent
              : colors.accent.withValues(alpha: 0.10),
          shape: GenUiShape.shape(theme.radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isFilled ? colors.onAccent : colors.accent,
              ),
              SizedBox(width: theme.spacing.sm),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                  color: isFilled ? colors.onAccent : colors.accent,
                  fontWeight: isFilled ? FontWeight.w600 : FontWeight.w500,
                ),
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
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      child: GenUiPressable(
        onTap: onTap,
        haptic: false,
        semanticLabel: semanticLabel,
        child: AnimatedContainer(
          duration: theme.motion.quick,
          curve: theme.motion.curve,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
          decoration: ShapeDecoration(
            color: enabled
                ? colors.accent
                : colors.textTertiary.withValues(alpha: 0.16),
            shape: GenUiShape.shape(theme.radii.md),
          ),
          child: Text(
            label,
            style: text.labelLarge?.copyWith(
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
