/// Theme + primitives for the generative-UI engine, with NO dependency on the
/// host app's design system. This is what lets the engine be lifted out as a
/// standalone package: renderers read colours, spacing, radii, motion and the
/// shape/press primitives from here, never from `app/theme` or `app/widgets`.
///
/// Colours are resolved through [genUiColorResolver], an optional hook the host
/// sets once at startup to bridge its own theme (so live accent theming is
/// preserved). When unset, the calm Ethereal defaults are used.
library;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Host-injected bridge from the app's theme to [GenUiColors]. Set once at
/// startup, e.g. `genUiColorResolver = (c) => GenUiColors(accent: c.colors.accent, …);`.
/// Called with the renderer's own context, so it picks up any nearer Theme
/// override (per-conversation / Live App accent) automatically.
GenUiColors Function(BuildContext context)? genUiColorResolver;

/// The colour roles the renderers use. A small, stable surface — the host maps
/// its palette onto these via [genUiColorResolver].
@immutable
class GenUiColors {
  const GenUiColors({
    required this.accent,
    required this.accentSoft,
    required this.accentGlow,
    required this.onAccent,
    required this.celadon,
    required this.danger,
    required this.surface,
    required this.surfaceRaised,
    required this.glassBorder,
    required this.hairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
  });

  final Color accent;
  final Color accentSoft;
  final Color accentGlow;
  final Color onAccent;
  final Color celadon;
  final Color danger;
  final Color surface;
  final Color surfaceRaised;
  final Color glassBorder;
  final Color hairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Calm Ethereal "nocturne" defaults, used when no [genUiColorResolver] is set.
  static const GenUiColors fallback = GenUiColors(
    accent: Color(0xFF8B93FF),
    accentSoft: Color(0xFF6E76E0),
    accentGlow: Color(0x4D6E76E0),
    onAccent: Color(0xFF0B0D12),
    celadon: Color(0xFF7FE3D0),
    danger: Color(0xFFE5708B),
    surface: Color(0xFF14171F),
    surfaceRaised: Color(0xFF1A1E28),
    glassBorder: Color(0x1FFFFFFF),
    hairline: Color(0x14FFFFFF),
    textPrimary: Color(0xFFECEEF2),
    textSecondary: Color(0xFF9AA1AE),
    textTertiary: Color(0xFF7C8696),
  );

  /// The colours for [context]: the host bridge if set, else [fallback].
  static GenUiColors of(BuildContext context) =>
      genUiColorResolver?.call(context) ?? fallback;
}

/// 4pt spacing scale (mirrors the host scale by value).
abstract final class GenUiSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. Continuous ("squircle") curvature via [GenUiShape].
abstract final class GenUiRadii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;

  /// Sentinel meaning "fully rounded pill".
  static const double pill = 999;
}

/// Motion durations for fades/reveals.
abstract final class GenUiMotion {
  static const Duration quick = Duration(milliseconds: 220);
}

/// iPhone-style continuous ("squircle") corners — continuous curvature that
/// flows into the edges rather than a plain circular radius.
abstract final class GenUiShape {
  static const double _continuousScale = 1.18;

  static BorderRadius radius(double r) =>
      BorderRadius.circular(r * _continuousScale);

  static ShapeBorder shape(double r, {BorderSide side = BorderSide.none}) {
    if (r >= GenUiRadii.pill) return StadiumBorder(side: side);
    return ContinuousRectangleBorder(borderRadius: radius(r), side: side);
  }

  static ShapeBorder only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
    BorderSide side = BorderSide.none,
  }) {
    const s = _continuousScale;
    return ContinuousRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(topLeft * s),
        topRight: Radius.circular(topRight * s),
        bottomLeft: Radius.circular(bottomLeft * s),
        bottomRight: Radius.circular(bottomRight * s),
      ),
      side: side,
    );
  }
}

const SpringDescription _snappy =
    SpringDescription(mass: 1, stiffness: 520, damping: 30);

/// A tap target that responds with a soft spring-driven scale instead of a
/// Material ripple. Honors the platform reduce-motion setting. Self-contained
/// copy so the engine needs no app widget.
class GenUiPressable extends StatefulWidget {
  const GenUiPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;

  /// Overrides the spoken accessibility label for this pressable. Use when
  /// [child] is icon-only, or when its text is an unsuitable spoken label
  /// (e.g. a glyph like `×`).
  final String? semanticLabel;

  @override
  State<GenUiPressable> createState() => _GenUiPressableState();
}

class _GenUiPressableState extends State<GenUiPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, lowerBound: 0, upperBound: 1, value: 0);

  bool get _reduceMotion => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _setPressed(bool pressed) {
    if (_reduceMotion) return;
    _c.animateWith(SpringSimulation(_snappy, _c.value, pressed ? 1 : 0, 0));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final gesture = GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onLongPress!.call();
            },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.scale(
          scale: 1 - (1 - widget.scale) * _c.value,
          child: child,
        ),
        child: widget.child,
      ),
    );

    if (widget.semanticLabel != null) {
      return Semantics(
        button: true,
        enabled: enabled,
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: gesture,
      );
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        child: gesture,
      ),
    );
  }
}
