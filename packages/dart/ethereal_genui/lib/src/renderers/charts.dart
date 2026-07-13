import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_common.dart';
import '../genui_localizations.dart';

/// Builds a spoken-word summary of chart data for accessibility, since
/// fl_chart emits no native semantics. Pure function.
String chartSemanticLabel({
  required String variant,
  String? title,
  required List<({String label, double value})> data,
}) {
  final kind = switch (variant) {
    'pie' => 'Pie chart',
    'line' => 'Line chart',
    'area' => 'Area chart',
    _ => 'Bar chart',
  };
  String fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  final points = data.map((d) => '${d.label} ${fmt(d.value)}').join(', ');
  final titlePart = (title != null && title.isNotEmpty) ? '$title. ' : '';
  return '$titlePart$kind: $points';
}

/// {"type":"chart","chart":"bar|line|area|pie","title":"…","data":[{"label":"Mon","value":3}]}
class ChartRenderer extends StatelessWidget {
  const ChartRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  Widget build(BuildContext context) {
    final variant = (spec['chart'] ?? spec['variant'] ?? 'bar').toString();
    final data =
        (spec['data'] is List ? spec['data'] as List<dynamic> : const [])
            .whereType<Map<String, dynamic>>()
            .map(
              (e) => (
                label: (e['label'] ?? '').toString(),
                value: (e['value'] is num)
                    ? (e['value'] as num).toDouble()
                    : 0.0,
              ),
            )
            .toList();
    if (data.isEmpty) {
      return GenUi.emptyState(
        context,
        GenUiLocalizations.of(
          context,
        ).text(GenUiStringKey.noChartData, 'No chart data'),
        icon: Icons.bar_chart_rounded,
      );
    }

    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, spec['title']?.toString()),
          Semantics(
            label: chartSemanticLabel(
              variant: variant,
              title: spec['title']?.toString(),
              data: data,
            ),
            child: SizedBox(
              height: 200,
              child: ExcludeSemantics(
                child: switch (variant) {
                  'pie' => _pie(context, data),
                  'line' => _line(context, data, area: false),
                  'area' => _line(context, data, area: true),
                  _ => _bar(context, data),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _palette(GenUiColors c) => [
    c.accent,
    c.celadon,
    c.accentSoft,
    c.danger,
    c.textSecondary,
  ];

  AxisTitles _bottomTitles(
    BuildContext context,
    List<({String label, double value})> data,
  ) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= data.length) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: GenUiSpace.sm),
            child: Text(
              data[i].label,
              style: text.labelSmall?.copyWith(color: colors.textTertiary),
            ),
          );
        },
      ),
    );
  }

  FlTitlesData _titles(
    BuildContext context,
    List<({String label, double value})> data,
  ) => FlTitlesData(
    show: true,
    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: _bottomTitles(context, data),
  );

  Widget _bar(BuildContext context, List<({String label, double value})> data) {
    final colors = GenUiColors.of(context);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: _titles(context, data),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].value,
                  color: colors.accent,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    List<({String label, double value})> data, {
    required bool area,
  }) {
    final colors = GenUiColors.of(context);
    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: _titles(context, data),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i].value),
            ],
            isCurved: true,
            color: colors.accent,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: area,
              color: colors.accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pie(BuildContext context, List<({String label, double value})> data) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final palette = _palette(colors);
    final total = data
        .fold<double>(0, (a, b) => a + b.value)
        .clamp(1, double.infinity);
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (var i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].value,
                    color: palette[i % palette.length],
                    title: '${(data[i].value / total * 100).round()}%',
                    radius: 48,
                    titleStyle:
                        (text.labelSmall ?? DefaultTextStyle.of(context).style)
                            .copyWith(
                              color: colors.onAccent,
                              fontWeight: FontWeight.w700,
                            ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: GenUiSpace.md),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < data.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: GenUiSpace.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: palette[i % palette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: GenUiSpace.sm),
                    Text(
                      data[i].label,
                      style: text.labelMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
