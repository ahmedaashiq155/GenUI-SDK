import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_block.dart';
import '../genui_common.dart';
import '../genui_localizations.dart';
import '../genui_state.dart';

List<Map<String, dynamic>> _children(dynamic v) =>
    (v is List ? v : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

/// {"type":"when","key":"view","equals":"new","child":{…}} — renders its child
/// only when the scoped state[key] matches `equals` (or is truthy when `equals`
/// is omitted). The enabler for self-contained apps: a `set` action flips state,
/// a `when` block reveals the matching view — all client-side, no round-trip.
class WhenRenderer extends StatelessWidget {
  const WhenRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final key = spec['key']?.toString();
    final value = GenUiStateScope.maybeOf(context)?.valueFor(key);
    final matches = spec.containsKey('equals')
        ? value == spec['equals']
        : (value != null &&
              value != false &&
              value != 0 &&
              '$value'.isNotEmpty);
    if (!matches) return const SizedBox.shrink();
    final child = spec['child'];
    if (child is Map<String, dynamic>) {
      return buildGenUiSpec(context, child, actions);
    }
    final kids = _children(spec['children']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final c in kids) buildGenUiSpec(context, c, actions)],
    );
  }
}

/// {"type":"section","title":"…","children":[ {…}, {…} ]}
class SectionRenderer extends StatelessWidget {
  const SectionRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final children = _children(spec['children']);
    final theme = GenUiTheme.of(context);
    return GenUi.frame(
      context,
      variant: GenUiFrameVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spec['title'] != null)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: theme.spacing.sm),
              child: Text(
                '${spec['title']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          for (final c in children)
            GenUiFrameScope(child: buildGenUiSpec(context, c, actions)),
        ],
      ),
    );
  }
}

/// {"type":"grid","columns":2,"children":[…]}
class GridRenderer extends StatelessWidget {
  const GridRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final children = _children(spec['children']);
    // Clamp to a sane range: a non-positive column count divides by zero /
    // goes negative, and an absurdly large one makes gap*(cols-1) exceed the
    // available width — both yield a negative SizedBox width (layout assert).
    final cols =
        ((spec['columns'] is num) ? (spec['columns'] as num).toInt() : 2).clamp(
          1,
          12,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = GenUiSpace.sm;
        final rawWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final width = (rawWidth.isFinite && rawWidth > 0) ? rawWidth : null;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in children)
              SizedBox(
                width: width,
                child: buildGenUiSpec(context, c, actions),
              ),
          ],
        );
      },
    );
  }
}

/// {"type":"columns","children":[…]} — children share the row evenly.
class ColumnsRenderer extends StatelessWidget {
  const ColumnsRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final children = _children(spec['children']);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: GenUiSpace.sm),
          Expanded(child: buildGenUiSpec(context, children[i], actions)),
        ],
      ],
    );
  }
}

/// {"type":"accordion","items":[{"title":"…","content":{…} | "text":"…"}]}
class AccordionRenderer extends StatefulWidget {
  const AccordionRenderer({
    super.key,
    required this.spec,
    required this.actions,
  });
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<AccordionRenderer> createState() => _AccordionRendererState();
}

class _AccordionRendererState extends State<AccordionRenderer> {
  final _open = <int>{};

  @override
  Widget build(BuildContext context) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final items = _children(widget.spec['items']);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          GenUi.frame(
            context,
            variant: GenUiFrameVariant.flat,
            margin: EdgeInsets.symmetric(vertical: theme.spacing.xs),
            padding: EdgeInsets.zero,
            radius: theme.radii.md,
            backgroundColor: colors.surface.withValues(alpha: 0.5),
            child: Column(
              children: [
                GenUiPressable(
                  onTap: () => setState(
                    () => _open.contains(i) ? _open.remove(i) : _open.add(i),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(theme.spacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${items[i]['title'] ?? ''}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Icon(
                          _open.contains(i)
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: theme.motion.standard,
                  curve: theme.motion.curve,
                  alignment: AlignmentDirectional.topStart,
                  child: _open.contains(i)
                      ? Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                            theme.spacing.md,
                            0,
                            theme.spacing.md,
                            theme.spacing.md,
                          ),
                          child: _body(context, items[i]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> item) {
    final content = item['content'];
    if (content is Map<String, dynamic>) {
      return GenUiFrameScope(
        child: buildGenUiSpec(context, content, widget.actions),
      );
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        '${item['text'] ?? ''}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// {"type":"tabs","tabs":[{"label":"…","content":{…} | "text":"…"}]}
class TabsRenderer extends StatefulWidget {
  const TabsRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<TabsRenderer> createState() => _TabsRendererState();
}

class _TabsRendererState extends State<TabsRenderer> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final tabs = _children(widget.spec['tabs']);
    if (tabs.isEmpty) {
      return GenUi.emptyState(
        context,
        GenUiLocalizations.of(context).text(GenUiStringKey.noTabs, 'No tabs'),
        icon: Icons.tab_outlined,
      );
    }
    final i = _index.clamp(0, tabs.length - 1);
    return GenUi.frame(
      context,
      variant: GenUiFrameVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var t = 0; t < tabs.length; t++)
                  GenUiPressable(
                    selected: t == i,
                    onTap: () => setState(() => _index = t),
                    child: Container(
                      margin: EdgeInsetsDirectional.only(end: theme.spacing.sm),
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.spacing.md,
                        vertical: theme.spacing.sm,
                      ),
                      decoration: ShapeDecoration(
                        color: t == i
                            ? colors.accent.withValues(alpha: 0.16)
                            : Colors.transparent,
                        shape: GenUiShape.shape(
                          theme.radii.pill,
                          side: BorderSide(
                            color: t == i
                                ? colors.accent.withValues(alpha: 0.4)
                                : colors.hairline,
                          ),
                        ),
                      ),
                      child: Text(
                        '${tabs[t]['label'] ?? 'Tab ${t + 1}'}',
                        style: text.labelMedium?.copyWith(
                          color: t == i ? colors.accent : colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: theme.spacing.sm),
          Builder(
            builder: (context) {
              final content = tabs[i]['content'];
              if (content is Map<String, dynamic>) {
                return GenUiFrameScope(
                  child: buildGenUiSpec(context, content, widget.actions),
                );
              }
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  '${tabs[i]['text'] ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
