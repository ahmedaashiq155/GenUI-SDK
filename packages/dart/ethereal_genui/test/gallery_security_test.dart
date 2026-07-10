import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Map<String, dynamic> spec) => MaterialApp(
    home: Builder(
      builder: (context) =>
          buildGenUiSpec(context, spec, GenUiActions(sendMessage: (_) {})),
    ),
  );

  testWidgets('gallery rejects plaintext HTTP images', (tester) async {
    await tester.pumpWidget(
      host({
        'type': 'gallery',
        'images': ['http://example.test/tracker.png'],
      }),
    );
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('gallery accepts HTTPS images', (tester) async {
    await tester.pumpWidget(
      host({
        'type': 'gallery',
        'images': ['https://example.test/image.png'],
      }),
    );
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    final resized = image.image as ResizeImage;
    expect((resized.imageProvider as NetworkImage).url, startsWith('https://'));
  });
}
