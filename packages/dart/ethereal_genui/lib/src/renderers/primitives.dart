import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_block.dart';
import '../genui_common.dart';
import '../genui_localizations.dart';
import '../genui_state.dart';
import 'directives.dart' show parseHexColor;

/// Low-level, freeform building blocks. These let the model compose *arbitrary*
/// layouts — not just the fixed catalog — by nesting boxes, text, rows, columns,
/// stacks, icons and buttons with its own colors, spacing and rounding. Every
/// block still draws from the ethereal tokens (squircle corners, the theme
/// accent) so model-built UI stays on-brand.

List<Map<String, dynamic>> _kids(dynamic v) =>
    (v is List ? v : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

double? _num(dynamic v) => v is num ? v.toDouble() : null;

/// A non-negative dimension, or null. A negative size/gap/padding trips
/// Flutter's BoxConstraints assertions (debug) or corrupts layout (release),
/// so a hostile or typo'd negative value is dropped to the default.
double? _dim(dynamic v) {
  final n = _num(v);
  return (n != null && n >= 0) ? n : null;
}

FontWeight _weight(dynamic v) => switch ('$v') {
  'bold' || 'w700' => FontWeight.w700,
  'semibold' || 'w600' => FontWeight.w600,
  'medium' || 'w500' => FontWeight.w500,
  'light' || 'w300' => FontWeight.w300,
  _ => FontWeight.w400,
};

TextAlign _textAlign(dynamic v) => switch ('$v') {
  'center' => TextAlign.center,
  'end' || 'right' => TextAlign.right,
  'justify' => TextAlign.justify,
  _ => TextAlign.left,
};

MainAxisAlignment _mainAlign(dynamic v) => switch ('$v') {
  'center' => MainAxisAlignment.center,
  'end' => MainAxisAlignment.end,
  'between' || 'spaceBetween' => MainAxisAlignment.spaceBetween,
  'around' || 'spaceAround' => MainAxisAlignment.spaceAround,
  _ => MainAxisAlignment.start,
};

CrossAxisAlignment _crossAlign(dynamic v) => switch ('$v') {
  'center' => CrossAxisAlignment.center,
  'end' => CrossAxisAlignment.end,
  'stretch' => CrossAxisAlignment.stretch,
  _ => CrossAxisAlignment.start,
};

/// A curated set of Material icons addressable by name (const so they survive
/// tree-shaking). Unknown names fall back to a neutral dot.
const _icons = <String, IconData>{
  'star': Icons.star_rounded,
  'heart': Icons.favorite_rounded,
  'check': Icons.check_circle_rounded,
  'close': Icons.cancel_rounded,
  'info': Icons.info_rounded,
  'warning': Icons.warning_rounded,
  'bolt': Icons.bolt_rounded,
  'spark': Icons.auto_awesome_rounded,
  'fire': Icons.local_fire_department_rounded,
  'sun': Icons.wb_sunny_rounded,
  'moon': Icons.nightlight_rounded,
  'cloud': Icons.cloud_rounded,
  'rain': Icons.water_drop_rounded,
  'time': Icons.schedule_rounded,
  'calendar': Icons.calendar_today_rounded,
  'location': Icons.place_rounded,
  'home': Icons.home_rounded,
  'search': Icons.search_rounded,
  'settings': Icons.settings_rounded,
  'person': Icons.person_rounded,
  'group': Icons.groups_rounded,
  'chat': Icons.chat_bubble_rounded,
  'mail': Icons.mail_rounded,
  'phone': Icons.phone_rounded,
  'play': Icons.play_arrow_rounded,
  'pause': Icons.pause_rounded,
  'music': Icons.music_note_rounded,
  'image': Icons.image_rounded,
  'camera': Icons.photo_camera_rounded,
  'code': Icons.code_rounded,
  'terminal': Icons.terminal_rounded,
  'rocket': Icons.rocket_launch_rounded,
  'trophy': Icons.emoji_events_rounded,
  'gift': Icons.card_giftcard_rounded,
  'cart': Icons.shopping_cart_rounded,
  'money': Icons.payments_rounded,
  'chart': Icons.insights_rounded,
  'trending_up': Icons.trending_up_rounded,
  'trending_down': Icons.trending_down_rounded,
  'arrow_right': Icons.arrow_forward_rounded,
  'arrow_left': Icons.arrow_back_rounded,
  'up': Icons.keyboard_arrow_up_rounded,
  'down': Icons.keyboard_arrow_down_rounded,
  'lock': Icons.lock_rounded,
  'key': Icons.key_rounded,
  'flag': Icons.flag_rounded,
  'bell': Icons.notifications_rounded,
  'book': Icons.menu_book_rounded,
  'bulb': Icons.lightbulb_rounded,
  'leaf': Icons.eco_rounded,
  'globe': Icons.public_rounded,
  'map': Icons.map_rounded,
  'food': Icons.restaurant_rounded,
  'coffee': Icons.local_cafe_rounded,
  'pin': Icons.push_pin_rounded,
  'link': Icons.link_rounded,
  'download': Icons.download_rounded,
  'upload': Icons.upload_rounded,
  'refresh': Icons.refresh_rounded,
  'add': Icons.add_rounded,
  'remove': Icons.remove_rounded,
  'edit': Icons.edit_rounded,
  'delete': Icons.delete_rounded,
};

IconData iconByName(dynamic name) => _icons['$name'] ?? Icons.circle;

/// {"type":"text","text":"Hi","size":18,"weight":"bold","color":"#hex","align":"center"}
class TextRenderer extends StatelessWidget {
  const TextRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final size = _dim(spec['size']) ?? 15;
    final inheritedForeground = GenUiForegroundScope.maybeOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GenUiSpace.xs),
      child: Text(
        '${spec['text'] ?? ''}',
        textAlign: _textAlign(spec['align']),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: size,
          height: 1.4,
          fontWeight: _weight(spec['weight']),
          color:
              parseHexColor(spec['color']?.toString()) ??
              inheritedForeground ??
              colors.textPrimary,
        ),
      ),
    );
  }
}

/// {"type":"icon","icon":"star","size":20,"color":"#hex"}
class IconRenderer extends StatelessWidget {
  const IconRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final inheritedForeground = GenUiForegroundScope.maybeOf(context);
    return Icon(
      iconByName(spec['icon']),
      size: _dim(spec['size']) ?? 22,
      color:
          parseHexColor(spec['color']?.toString()) ??
          inheritedForeground ??
          colors.accent,
    );
  }
}

/// {"type":"spacer","size":12}
class SpacerRenderer extends StatelessWidget {
  const SpacerRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final s = _dim(spec['size']) ?? GenUiSpace.md;
    return SizedBox(width: s, height: s);
  }
}

/// {"type":"button","label":"Go","send":"do it","style":"primary|soft|ghost","icon":"bolt"}
class ButtonRenderer extends StatelessWidget {
  const ButtonRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final label =
        '${spec['label'] ?? GenUiLocalizations.of(context).text(GenUiStringKey.button, 'Button')}';
    // Client-side state patch (no round-trip). When present, the button does NOT
    // fall back to sending the label — that fallback is what made app buttons
    // fire a chat turn and spawn a new UI.
    final set = spec['set'];
    final hasSet = set is Map && set.isNotEmpty;
    final explicitSend = (spec['send'] ?? '').toString();
    final send = explicitSend.isNotEmpty
        ? explicitSend
        : (hasSet ? '' : (spec['label'] ?? '').toString());
    final style = '${spec['style'] ?? 'soft'}';
    final tint = parseHexColor(spec['color']?.toString()) ?? colors.accent;
    final primary = style == 'primary';
    final ghost = style == 'ghost';

    final bg = primary
        ? tint
        : ghost
        ? Colors.transparent
        : tint.withValues(alpha: 0.14);
    final fg = GenUiContrast.readableForeground(
      bg,
      preferred: primary ? colors.onAccent : tint,
      surface: colors.surface,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
      child: GenUiPressable(
        onTap: actions.enabled && (send.isNotEmpty || hasSet)
            ? () {
                if (hasSet) {
                  GenUiStateScope.maybeOf(
                    context,
                  )?.merge((set).map((k, v) => MapEntry(k.toString(), v)));
                }
                if (send.isNotEmpty) actions.sendMessage(send);
              }
            : null,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.lg,
            vertical: theme.spacing.md,
          ),
          decoration: ShapeDecoration(
            color: bg,
            shape: GenUiShape.shape(
              theme.radii.pill,
              side: ghost
                  ? BorderSide(color: tint.withValues(alpha: 0.4))
                  : BorderSide.none,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (spec['icon'] != null) ...[
                Icon(iconByName(spec['icon']), size: 18, color: fg),
                const SizedBox(width: GenUiSpace.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// {"type":"box","bg":"#hex","padding":12,"radius":16,"border":"#hex","gradient":["#a","#b"],
///  "width":..,"height":..,"align":"center","child":{…} | "children":[…]}
class BoxRenderer extends StatelessWidget {
  const BoxRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final children = _resolveChildren(context);
    final padding = _dim(spec['padding']) ?? theme.spacing.md;
    final radius = _num(spec['radius']) ?? theme.radii.md;
    final border = parseHexColor(spec['border']?.toString());
    final bg = parseHexColor(spec['bg']?.toString());

    final gradient = (spec['gradient'] is List)
        ? (spec['gradient'] as List)
              .map((e) => parseHexColor(e.toString()))
              .whereType<Color>()
              .toList()
        : const <Color>[];

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAlign(spec['align']),
      children: children,
    );

    final align = spec['align'];
    if (align == 'center') content = Center(child: content);

    final authoredBackground = gradient.length >= 2
        ? Color.lerp(gradient.first, gradient.last, 0.5)!
        : bg;
    final foreground = authoredBackground == null
        ? null
        : GenUiContrast.readableForeground(
            authoredBackground,
            preferred: colors.textPrimary,
            surface: colors.surface,
          );
    final scopedContent = foreground == null
        ? content
        : GenUiForegroundScope(color: foreground, child: content);

    final box = Container(
      width: _dim(spec['width']),
      height: _dim(spec['height']),
      padding: EdgeInsets.all(padding),
      decoration: ShapeDecoration(
        color: gradient.isEmpty
            ? (bg ?? colors.surface.withValues(alpha: 0.5))
            : null,
        gradient: gradient.length >= 2
            ? LinearGradient(
                colors: gradient,
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
              )
            : null,
        shape: GenUiShape.shape(
          radius,
          side: border != null
              ? BorderSide(color: border)
              : BorderSide(color: colors.hairline),
        ),
      ),
      child: scopedContent,
    );

    final tap = (spec['send'] ?? '').toString();
    final set = spec['set'];
    final hasSet = set is Map && set.isNotEmpty;
    final wrapped = (tap.isNotEmpty || hasSet) && actions.enabled
        ? GenUiPressable(
            onTap: () {
              if (hasSet) {
                GenUiStateScope.maybeOf(
                  context,
                )?.merge((set).map((k, v) => MapEntry(k.toString(), v)));
              }
              if (tap.isNotEmpty) actions.sendMessage(tap);
            },
            child: box,
          )
        : box;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
      child: wrapped,
    );
  }

  List<Widget> _resolveChildren(BuildContext context) {
    final single = spec['child'];
    final list = single is Map<String, dynamic>
        ? [single]
        : _kids(spec['children']);
    return [
      for (final c in list)
        GenUiFrameScope(child: buildGenUiSpec(context, c, actions)),
    ];
  }
}

/// {"type":"row","children":[…],"align":"between","cross":"center","gap":8}
class RowRenderer extends StatelessWidget {
  const RowRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final kids = _kids(spec['children']);
    final align = _mainAlign(spec['align']);
    final gap = _dim(spec['gap']) ?? GenUiSpace.sm;
    final spaced =
        align == MainAxisAlignment.spaceBetween ||
        align == MainAxisAlignment.spaceAround;
    final expand = spec['expand'] == true;

    Widget wrap(Widget c) => expand ? Expanded(child: c) : Flexible(child: c);

    return Row(
      mainAxisAlignment: align,
      crossAxisAlignment: _crossAlign(spec['cross'] ?? 'center'),
      children: [
        for (var i = 0; i < kids.length; i++) ...[
          if (i > 0 && !spaced) SizedBox(width: gap),
          wrap(
            GenUiFrameScope(child: buildGenUiSpec(context, kids[i], actions)),
          ),
        ],
      ],
    );
  }
}

/// {"type":"column","children":[…],"cross":"start","gap":8}
class ColumnRenderer extends StatelessWidget {
  const ColumnRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final kids = _kids(spec['children']);
    final gap = _dim(spec['gap']) ?? GenUiSpace.xs;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAlign(
        spec['cross'] ?? spec['align'] ?? 'start',
      ),
      children: [
        for (var i = 0; i < kids.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          GenUiFrameScope(child: buildGenUiSpec(context, kids[i], actions)),
        ],
      ],
    );
  }
}

/// {"type":"stack","align":"center","children":[…]} — layered overlay.
class StackRenderer extends StatelessWidget {
  const StackRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final kids = _kids(spec['children']);
    final AlignmentGeometry alignment = switch ('${spec['align']}') {
      'topLeft' => AlignmentDirectional.topStart,
      'topRight' => AlignmentDirectional.topEnd,
      'bottomLeft' => AlignmentDirectional.bottomStart,
      'bottomRight' => AlignmentDirectional.bottomEnd,
      'bottom' => AlignmentDirectional.bottomCenter,
      'top' => AlignmentDirectional.topCenter,
      _ => AlignmentDirectional.center,
    };
    return Stack(
      alignment: alignment,
      children: [
        for (final c in kids)
          GenUiFrameScope(child: buildGenUiSpec(context, c, actions)),
      ],
    );
  }
}
