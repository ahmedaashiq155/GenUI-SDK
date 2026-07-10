import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter barrel exports GenUiOption and genUiOptions', () {
    const option = GenUiOption(label: 'Daily', value: 'daily');
    final normalized = genUiOptions([
      {'label': 'Weekly', 'value': 'weekly'},
    ]);

    expect(option.value, 'daily');
    expect(normalized.single.label, 'Weekly');
  });
}
