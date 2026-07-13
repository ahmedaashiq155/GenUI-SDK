/// Theme + primitives for the generative-UI engine, with NO dependency on the
/// host app's design system. This is what lets the engine be lifted out as a
/// standalone package: renderers read colours, spacing, radii, motion and the
/// shape/press primitives from here, never from `app/theme` or `app/widgets`.
///
/// Colours follow the nearest Material [Theme] by default. Hosts that need a
/// custom mapping can still override resolution through [genUiColorResolver].
library;

import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// Host-injected bridge from the app's theme to [GenUiColors]. Set once at
/// startup, e.g. `genUiColorResolver = (c) => GenUiColors(accent: c.colors.accent, …);`.
/// Called with the renderer's own context, so it picks up any nearer Theme
/// override (per-conversation / Live App accent) automatically.
@Deprecated(
  'Use ThemeData.extensions with GenUiTheme for subtree-scoped overrides.',
)
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

  /// Calm Ethereal dark preset. Opt into it through [genUiColorResolver] when a
  /// host wants the original nocturne appearance regardless of its own theme.
  static const GenUiColors nocturne = GenUiColors(
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

  /// Backwards-compatible name for the original dark preset.
  @Deprecated('Use GenUiColors.nocturne instead.')
  static const GenUiColors fallback = nocturne;

  /// Derives renderer roles from the nearest Material color scheme. The color
  /// scheme already encodes light/dark brightness, so no separate brightness
  /// branch is needed here.
  factory GenUiColors.fromTheme(BuildContext context) {
    return GenUiColors.fromColorScheme(Theme.of(context).colorScheme);
  }

  /// Derives renderer roles from a Material [ColorScheme]. Useful when a host
  /// creates a [GenUiTheme] alongside its [ThemeData].
  factory GenUiColors.fromColorScheme(ColorScheme scheme) {
    return GenUiColors(
      accent: scheme.primary,
      accentSoft: scheme.secondary,
      accentGlow: scheme.primary.withValues(alpha: 0.30),
      onAccent: scheme.onPrimary,
      celadon: scheme.tertiary,
      danger: scheme.error,
      surface: scheme.surface,
      surfaceRaised: Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.05),
        scheme.surface,
      ),
      glassBorder: scheme.outline.withValues(alpha: 0.32),
      hairline: scheme.outline.withValues(alpha: 0.18),
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurface.withValues(alpha: 0.72),
      textTertiary: scheme.onSurface.withValues(alpha: 0.56),
    );
  }

  GenUiColors copyWith({
    Color? accent,
    Color? accentSoft,
    Color? accentGlow,
    Color? onAccent,
    Color? celadon,
    Color? danger,
    Color? surface,
    Color? surfaceRaised,
    Color? glassBorder,
    Color? hairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
  }) => GenUiColors(
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    accentGlow: accentGlow ?? this.accentGlow,
    onAccent: onAccent ?? this.onAccent,
    celadon: celadon ?? this.celadon,
    danger: danger ?? this.danger,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    glassBorder: glassBorder ?? this.glassBorder,
    hairline: hairline ?? this.hairline,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
  );

  static GenUiColors lerp(GenUiColors a, GenUiColors b, double t) =>
      GenUiColors(
        accent: Color.lerp(a.accent, b.accent, t)!,
        accentSoft: Color.lerp(a.accentSoft, b.accentSoft, t)!,
        accentGlow: Color.lerp(a.accentGlow, b.accentGlow, t)!,
        onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
        celadon: Color.lerp(a.celadon, b.celadon, t)!,
        danger: Color.lerp(a.danger, b.danger, t)!,
        surface: Color.lerp(a.surface, b.surface, t)!,
        surfaceRaised: Color.lerp(a.surfaceRaised, b.surfaceRaised, t)!,
        glassBorder: Color.lerp(a.glassBorder, b.glassBorder, t)!,
        hairline: Color.lerp(a.hairline, b.hairline, t)!,
        textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
        textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
        textTertiary: Color.lerp(a.textTertiary, b.textTertiary, t)!,
      );

  /// The colours for [context]: a host override when provided, otherwise roles
  /// derived from the nearest Material theme.
  static GenUiColors of(BuildContext context) =>
      Theme.of(context).extension<GenUiTheme>()?.colors ??
      // ignore: deprecated_member_use_from_same_package
      genUiColorResolver?.call(context) ??
      GenUiColors.fromTheme(context);
}

@immutable
class GenUiSpacingTheme {
  const GenUiSpacingTheme({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  GenUiSpacingTheme copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) => GenUiSpacingTheme(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xxl: xxl ?? this.xxl,
  );

  static GenUiSpacingTheme lerp(
    GenUiSpacingTheme a,
    GenUiSpacingTheme b,
    double t,
  ) => GenUiSpacingTheme(
    xs: _lerpDouble(a.xs, b.xs, t),
    sm: _lerpDouble(a.sm, b.sm, t),
    md: _lerpDouble(a.md, b.md, t),
    lg: _lerpDouble(a.lg, b.lg, t),
    xl: _lerpDouble(a.xl, b.xl, t),
    xxl: _lerpDouble(a.xxl, b.xxl, t),
  );
}

@immutable
class GenUiRadiiTheme {
  const GenUiRadiiTheme({
    this.xs = 8,
    this.sm = 12,
    this.md = 16,
    this.lg = 20,
    this.xl = 28,
    this.pill = 999,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double pill;

  GenUiRadiiTheme copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? pill,
  }) => GenUiRadiiTheme(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    pill: pill ?? this.pill,
  );

  static GenUiRadiiTheme lerp(GenUiRadiiTheme a, GenUiRadiiTheme b, double t) =>
      GenUiRadiiTheme(
        xs: _lerpDouble(a.xs, b.xs, t),
        sm: _lerpDouble(a.sm, b.sm, t),
        md: _lerpDouble(a.md, b.md, t),
        lg: _lerpDouble(a.lg, b.lg, t),
        xl: _lerpDouble(a.xl, b.xl, t),
        pill: _lerpDouble(a.pill, b.pill, t),
      );
}

@immutable
class GenUiMotionTheme {
  const GenUiMotionTheme({
    this.quick = const Duration(milliseconds: 150),
    this.standard = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
  });

  final Duration quick;
  final Duration standard;
  final Duration slow;
  final Curve curve;

  GenUiMotionTheme copyWith({
    Duration? quick,
    Duration? standard,
    Duration? slow,
    Curve? curve,
  }) => GenUiMotionTheme(
    quick: quick ?? this.quick,
    standard: standard ?? this.standard,
    slow: slow ?? this.slow,
    curve: curve ?? this.curve,
  );

  static GenUiMotionTheme lerp(
    GenUiMotionTheme a,
    GenUiMotionTheme b,
    double t,
  ) => GenUiMotionTheme(
    quick: _lerpDuration(a.quick, b.quick, t),
    standard: _lerpDuration(a.standard, b.standard, t),
    slow: _lerpDuration(a.slow, b.slow, t),
    curve: t < 0.5 ? a.curve : b.curve,
  );
}

@immutable
class GenUiFrameTheme {
  const GenUiFrameTheme({
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = const EdgeInsets.all(16),
    this.shadowOpacity = 0.06,
    this.shadowBlur = 18,
    this.shadowOffset = const Offset(0, 6),
  });

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double shadowOpacity;
  final double shadowBlur;
  final Offset shadowOffset;

  GenUiFrameTheme copyWith({
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? shadowOpacity,
    double? shadowBlur,
    Offset? shadowOffset,
  }) => GenUiFrameTheme(
    margin: margin ?? this.margin,
    padding: padding ?? this.padding,
    shadowOpacity: shadowOpacity ?? this.shadowOpacity,
    shadowBlur: shadowBlur ?? this.shadowBlur,
    shadowOffset: shadowOffset ?? this.shadowOffset,
  );

  static GenUiFrameTheme lerp(GenUiFrameTheme a, GenUiFrameTheme b, double t) =>
      GenUiFrameTheme(
        margin: EdgeInsetsGeometry.lerp(a.margin, b.margin, t)!,
        padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t)!,
        shadowOpacity: _lerpDouble(a.shadowOpacity, b.shadowOpacity, t),
        shadowBlur: _lerpDouble(a.shadowBlur, b.shadowBlur, t),
        shadowOffset: Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
      );
}

/// Subtree-scoped design tokens for GenUI renderers. Hosts may install this in
/// [ThemeData.extensions]; without one, renderers still derive colors from the
/// nearest Material theme and use the package token defaults.
@immutable
class GenUiTheme extends ThemeExtension<GenUiTheme> {
  const GenUiTheme({
    required this.colors,
    this.spacing = const GenUiSpacingTheme(),
    this.radii = const GenUiRadiiTheme(),
    this.motion = const GenUiMotionTheme(),
    this.frames = const GenUiFrameTheme(),
  });

  const GenUiTheme.nocturne({
    this.colors = GenUiColors.nocturne,
    this.spacing = const GenUiSpacingTheme(),
    this.radii = const GenUiRadiiTheme(),
    this.motion = const GenUiMotionTheme(),
    this.frames = const GenUiFrameTheme(),
  });

  factory GenUiTheme.fromColorScheme(ColorScheme scheme) =>
      GenUiTheme(colors: GenUiColors.fromColorScheme(scheme));

  final GenUiColors colors;
  final GenUiSpacingTheme spacing;
  final GenUiRadiiTheme radii;
  final GenUiMotionTheme motion;
  final GenUiFrameTheme frames;

  static GenUiTheme of(BuildContext context) {
    final extension = Theme.of(context).extension<GenUiTheme>();
    if (extension != null) return extension;
    // ignore: deprecated_member_use_from_same_package
    final legacy = genUiColorResolver?.call(context);
    return GenUiTheme(colors: legacy ?? GenUiColors.fromTheme(context));
  }

  @override
  GenUiTheme copyWith({
    GenUiColors? colors,
    GenUiSpacingTheme? spacing,
    GenUiRadiiTheme? radii,
    GenUiMotionTheme? motion,
    GenUiFrameTheme? frames,
  }) => GenUiTheme(
    colors: colors ?? this.colors,
    spacing: spacing ?? this.spacing,
    radii: radii ?? this.radii,
    motion: motion ?? this.motion,
    frames: frames ?? this.frames,
  );

  @override
  GenUiTheme lerp(covariant GenUiTheme? other, double t) {
    if (other == null) return this;
    return GenUiTheme(
      colors: GenUiColors.lerp(colors, other.colors, t),
      spacing: GenUiSpacingTheme.lerp(spacing, other.spacing, t),
      radii: GenUiRadiiTheme.lerp(radii, other.radii, t),
      motion: GenUiMotionTheme.lerp(motion, other.motion, t),
      frames: GenUiFrameTheme.lerp(frames, other.frames, t),
    );
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

Duration _lerpDuration(Duration a, Duration b, double t) => Duration(
  microseconds: _lerpDouble(
    a.inMicroseconds.toDouble(),
    b.inMicroseconds.toDouble(),
    t,
  ).round(),
);

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
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
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

const SpringDescription _snappy = SpringDescription(
  mass: 1,
  stiffness: 520,
  damping: 30,
);

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
    this.selected,
    this.checked,
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

  /// Exposes selection/check state without relying on color alone.
  final bool? selected;
  final bool? checked;

  @override
  State<GenUiPressable> createState() => _GenUiPressableState();
}

class _GenUiPressableState extends State<GenUiPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    lowerBound: 0,
    upperBound: 1,
    value: 0,
  );

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  bool _focused = false;

  void _setPressed(bool pressed) {
    if (_reduceMotion) return;
    _c.animateWith(SpringSimulation(_snappy, _c.value, pressed ? 1 : 0, 0));
  }

  void _activate({bool haptic = true}) {
    if (widget.onTap == null) return;
    if (haptic && widget.haptic) HapticFeedback.lightImpact();
    widget.onTap!.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final theme = GenUiTheme.of(context);
    final gesture = GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onTap == null ? null : _activate,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onLongPress!.call();
            },
      child: AnimatedOpacity(
        duration: theme.motion.quick,
        opacity: enabled ? 1 : 0.55,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.scale(
              scale: 1 - (1 - widget.scale) * _c.value,
              child: child,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    final focusable = FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowFocusHighlight: (focused) {
        if (_focused != focused) setState(() => _focused = focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate(haptic: false);
            return null;
          },
        ),
      },
      child: AnimatedContainer(
        duration: theme.motion.quick,
        curve: theme.motion.curve,
        decoration: BoxDecoration(
          border: Border.all(
            color: _focused ? theme.colors.accent : Colors.transparent,
            width: 2,
          ),
          borderRadius: GenUiShape.radius(theme.radii.sm),
        ),
        child: gesture,
      ),
    );

    if (widget.semanticLabel != null) {
      return Semantics(
        button: true,
        enabled: enabled,
        selected: widget.selected,
        checked: widget.checked,
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: focusable,
      );
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: widget.selected,
        checked: widget.checked,
        child: focusable,
      ),
    );
  }
}
