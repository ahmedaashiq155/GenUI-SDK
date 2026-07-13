import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => genUiColorResolver = null);

  Future<({GenUiColors colors, ColorScheme scheme})> resolve(
    WidgetTester tester, {
    required Brightness brightness,
    GenUiTheme? extension,
  }) async {
    late GenUiColors colors;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3155CC),
      brightness: brightness,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          useMaterial3: true,
          extensions: [?extension],
        ),
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

  testWidgets('ThemeExtension overrides the legacy global resolver', (
    tester,
  ) async {
    // ignore: deprecated_member_use_from_same_package
    genUiColorResolver = (_) => GenUiColors.nocturne;
    final custom = GenUiTheme(
      colors: GenUiColors.nocturne.copyWith(accent: const Color(0xFFCC3355)),
      spacing: const GenUiSpacingTheme(md: 20),
    );
    final result = await resolve(
      tester,
      brightness: Brightness.light,
      extension: custom,
    );
    expect(result.colors.accent, const Color(0xFFCC3355));
  });

  testWidgets('nearest ThemeExtension controls frame tokens', (tester) async {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: scheme,
          extensions: [
            GenUiTheme(
              colors: GenUiColors.fromColorScheme(scheme),
              frames: const GenUiFrameTheme(
                padding: EdgeInsets.all(27),
                shadowOpacity: 0,
              ),
            ),
          ],
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                GenUi.frame(context, child: const Text('inside')),
          ),
        ),
      ),
    );
    final containers = tester.widgetList<Container>(
      find.ancestor(of: find.text('inside'), matching: find.byType(Container)),
    );
    expect(
      containers.any(
        (container) => container.padding == const EdgeInsets.all(27),
      ),
      isTrue,
    );
  });

  test('GenUiTheme interpolates custom tokens for animated theme changes', () {
    const a = GenUiTheme(
      colors: GenUiColors.nocturne,
      spacing: GenUiSpacingTheme(md: 8),
      radii: GenUiRadiiTheme(md: 8),
    );
    final b = a.copyWith(
      colors: a.colors.copyWith(accent: Colors.white),
      spacing: const GenUiSpacingTheme(md: 24),
      radii: const GenUiRadiiTheme(md: 24),
    );
    final middle = a.lerp(b, 0.5);
    expect(middle.spacing.md, 16);
    expect(middle.radii.md, 16);
    expect(
      middle.colors.accent,
      Color.lerp(a.colors.accent, Colors.white, 0.5),
    );
  });

  test('fallback remains an alias for the opt-in nocturne preset', () {
    // ignore: deprecated_member_use_from_same_package
    expect(GenUiColors.fallback, same(GenUiColors.nocturne));
  });
}
