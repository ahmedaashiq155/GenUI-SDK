import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => genUiColorResolver = null);

  Future<({GenUiColors colors, ColorScheme scheme})> resolve(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    late GenUiColors colors;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3155CC),
      brightness: brightness,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme, useMaterial3: true),
        home: Builder(
          builder: (context) {
            colors = GenUiColors.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return (colors: colors, scheme: scheme);
  }

  testWidgets('default colors follow a light Material color scheme', (
    tester,
  ) async {
    final result = await resolve(tester, brightness: Brightness.light);
    final colors = result.colors;
    final scheme = result.scheme;

    expect(colors.surface, scheme.surface);
    expect(colors.textPrimary, scheme.onSurface);
    expect(colors.accent, scheme.primary);
    expect(colors.onAccent, scheme.onPrimary);
    expect(
      ThemeData.estimateBrightnessForColor(colors.surface),
      Brightness.light,
    );
  });

  testWidgets('default colors follow a dark Material color scheme', (
    tester,
  ) async {
    final result = await resolve(tester, brightness: Brightness.dark);
    final colors = result.colors;
    final scheme = result.scheme;

    expect(colors.surface, scheme.surface);
    expect(colors.textPrimary, scheme.onSurface);
    expect(colors.danger, scheme.error);
    expect(
      ThemeData.estimateBrightnessForColor(colors.surface),
      Brightness.dark,
    );
  });

  testWidgets('custom resolver takes precedence over the Material theme', (
    tester,
  ) async {
    genUiColorResolver = (_) => GenUiColors.nocturne;
    final result = await resolve(tester, brightness: Brightness.light);
    expect(result.colors, same(GenUiColors.nocturne));
  });

  test('fallback remains an alias for the opt-in nocturne preset', () {
    // ignore: deprecated_member_use_from_same_package
    expect(GenUiColors.fallback, same(GenUiColors.nocturne));
  });
}
