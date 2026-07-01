import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chartSemanticLabel', () {
    test('bar chart without title, integer values', () {
      expect(
        chartSemanticLabel(
          variant: 'bar',
          title: null,
          data: const [(label: 'Mon', value: 3), (label: 'Tue', value: 5)],
        ),
        'Bar chart: Mon 3, Tue 5',
      );
    });

    test('bar chart with title', () {
      expect(
        chartSemanticLabel(
          variant: 'bar',
          title: 'Weekly Sales',
          data: const [(label: 'Mon', value: 3), (label: 'Tue', value: 5)],
        ),
        'Weekly Sales. Bar chart: Mon 3, Tue 5',
      );
    });

    test('line chart without title, decimal values', () {
      expect(
        chartSemanticLabel(
          variant: 'line',
          title: null,
          data: const [(label: 'Jan', value: 1.5), (label: 'Feb', value: 2.25)],
        ),
        'Line chart: Jan 1.5, Feb 2.3',
      );
    });

    test('pie chart with title and integer values', () {
      expect(
        chartSemanticLabel(
          variant: 'pie',
          title: 'Market Share',
          data: const [(label: 'A', value: 60), (label: 'B', value: 40)],
        ),
        'Market Share. Pie chart: A 60, B 40',
      );
    });

    test('unknown variant falls back to bar chart', () {
      expect(
        chartSemanticLabel(
          variant: 'scatter',
          title: null,
          data: const [(label: 'X', value: 1)],
        ),
        'Bar chart: X 1',
      );
    });

    test('empty title is treated as no title', () {
      expect(
        chartSemanticLabel(
          variant: 'bar',
          title: '',
          data: const [(label: 'Mon', value: 3)],
        ),
        'Bar chart: Mon 3',
      );
    });

    test('single data point', () {
      expect(
        chartSemanticLabel(
          variant: 'pie',
          title: null,
          data: const [(label: 'Only', value: 100)],
        ),
        'Pie chart: Only 100',
      );
    });
  });
}
