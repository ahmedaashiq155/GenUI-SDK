import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_common.dart';

List<Map<String, dynamic>> _maps(dynamic v) =>
    (v is List ? v : const <dynamic>[]).whereType<Map<String, dynamic>>().toList();

/// {"type":"card","title":"…","subtitle":"…","items":[{"label","value"}]}
class CardRenderer extends StatelessWidget {
  const CardRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final items = _maps(spec['items']);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spec['title'] != null)
            Text('${spec['title']}',
                style: text.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2)),
          if (spec['subtitle'] != null) ...[
            const SizedBox(height: 2),
            Text('${spec['subtitle']}',
                style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: GenUiSpace.md),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: GenUiSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text('${it['label'] ?? ''}',
                          style: text.bodyMedium?.copyWith(color: colors.textTertiary)),
                    ),
                    const SizedBox(width: GenUiSpace.sm),
                    Expanded(
                      child: Text('${it['value'] ?? ''}',
                          style: text.bodyLarge?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// {"type":"callout","style":"info|warn|success","title":"…","text":"…"}
class CalloutRenderer extends StatelessWidget {
  const CalloutRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final style = (spec['style'] ?? 'info').toString();
    final (color, icon) = switch (style) {
      'warn' || 'warning' => (colors.danger, Icons.warning_amber_rounded),
      'success' => (colors.celadon, Icons.check_circle_outline_rounded),
      _ => (colors.accent, Icons.info_outline_rounded),
    };
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
      padding: const EdgeInsets.all(GenUiSpace.md),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.10),
        shape: GenUiShape.shape(GenUiRadii.lg,
            side: BorderSide(color: color.withValues(alpha: 0.22))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: GenUiSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (spec['title'] != null)
                  Text('${spec['title']}',
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (spec['text'] != null)
                  Text('${spec['text']}',
                      style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// {"type":"stat","title":"…","stats":[{"label","value"}]}
class StatRenderer extends StatelessWidget {
  const StatRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final stats = _maps(spec['stats'] ?? spec['items']);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, spec['title']?.toString()),
          Wrap(
            spacing: GenUiSpace.lg,
            runSpacing: GenUiSpace.md,
            children: [
              for (final s in stats)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${s['value'] ?? ''}',
                        style: text.headlineSmall?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        )),
                    const SizedBox(height: 2),
                    Text('${s['label'] ?? ''}'.toUpperCase(),
                        style: text.labelSmall?.copyWith(
                          color: colors.textTertiary,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// {"type":"table","columns":["A","B"],"rows":[["1","2"]]}
class TableRenderer extends StatelessWidget {
  const TableRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final columns = (spec['columns'] is List ? spec['columns'] as List<dynamic> : const [])
        .map((e) => e.toString())
        .toList();
    final rows = (spec['rows'] is List ? spec['rows'] as List<dynamic> : const [])
        .map((r) => (r is List ? r : const <dynamic>[]).map((e) => e.toString()).toList())
        .toList();
    // DataTable asserts columns.isNotEmpty; rows without headers can't render
    // meaningfully anyway, so collapse whenever there are no columns.
    if (columns.isEmpty) return const SizedBox.shrink();

    return GenUi.frame(
      context,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: text.bodyMedium?.copyWith(
              color: colors.textPrimary, fontWeight: FontWeight.w700),
          dataTextStyle: text.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()]),
          dividerThickness: 0.5,
          columns: [
            for (final c in columns) DataColumn(label: Text(c)),
          ],
          rows: [
            for (final r in rows)
              DataRow(cells: [
                for (var i = 0; i < columns.length; i++)
                  DataCell(Text(i < r.length ? r[i] : '')),
              ]),
          ],
        ),
      ),
    );
  }
}

/// {"type":"timeline","items":[{"title":"…","subtitle":"…","done":true}]}
class TimelineRenderer extends StatelessWidget {
  const TimelineRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final items = _maps(spec['items'] ?? spec['steps']);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, spec['title']?.toString()),
          for (var i = 0; i < items.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: items[i]['done'] == true
                              ? colors.celadon
                              : colors.accent.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i != items.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: colors.hairline,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: GenUiSpace.md),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: GenUiSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${items[i]['title'] ?? ''}',
                              style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          if (items[i]['subtitle'] != null)
                            Text('${items[i]['subtitle']}',
                                style: text.bodyMedium?.copyWith(color: colors.textTertiary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// {"type":"progress","label":"…","value":0.6}  (value 0–1, or "percent":60)
class ProgressRenderer extends StatelessWidget {
  const ProgressRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    double value;
    if (spec['percent'] is num) {
      value = (spec['percent'] as num).toDouble() / 100.0;
    } else if (spec['value'] is num) {
      value = (spec['value'] as num).toDouble();
    } else {
      value = 0;
    }
    value = value.clamp(0.0, 1.0);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${spec['label'] ?? ''}', style: Theme.of(context).textTheme.bodyLarge),
              Text('${(value * 100).round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.accent)),
            ],
          ),
          const SizedBox(height: GenUiSpace.sm),
          Semantics(
            label: '${spec['label'] ?? ''}',
            value: '${(value * 100).round()}%',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: colors.accent.withValues(alpha: 0.14),
                valueColor: AlwaysStoppedAnimation(colors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// {"type":"badges","items":["new","beta"]}
class BadgesRenderer extends StatelessWidget {
  const BadgesRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final items = (spec['items'] is List ? spec['items'] as List<dynamic> : const [])
        .map((e) => e.toString())
        .toList();
    return GenUi.frame(
      context,
      child: Wrap(
        spacing: GenUiSpace.sm,
        runSpacing: GenUiSpace.sm,
        children: [
          for (final b in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: GenUiSpace.md, vertical: 6),
              decoration: ShapeDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                shape: GenUiShape.shape(GenUiRadii.pill),
              ),
              child: Text(b,
                  style: TextStyle(
                      color: colors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// {"type":"gallery","images":["https://…"]}
class GalleryRenderer extends StatelessWidget {
  const GalleryRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final urls = (spec['images'] is List ? spec['images'] as List<dynamic> : const [])
        .map((e) => e.toString())
        .where((u) => u.startsWith('https://'))
        .toList();
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: GenUiSpace.sm),
        itemBuilder: (context, i) => ClipPath(
          clipper: ShapeBorderClipper(shape: GenUiShape.shape(GenUiRadii.md)),
          child: Image.network(
            urls[i],
            width: 200,
            cacheWidth: 400,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 200,
              color: colors.surface,
              child: Icon(Icons.broken_image_outlined, color: colors.textTertiary),
            ),
          ),
        ),
      ),
    );
  }
}

/// {"type":"divider"}
class DividerRenderer extends StatelessWidget {
  const DividerRenderer({super.key});

  @override
  Widget build(BuildContext context) =>
      Divider(height: GenUiSpace.lg, color: GenUiColors.of(context).hairline);
}
