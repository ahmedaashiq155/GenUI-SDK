import 'package:ethereal_genui/ethereal_genui.dart';
import 'package:flutter/material.dart';

/// A tiny demo of the generative-UI engine: it renders a few model-style `ui`
/// specs and echoes whatever a tapped/submitted control would send back.
void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  String _lastSent = 'tap a control…';

  // A handful of specs the way a model would emit them.
  static const _specs = <Map<String, dynamic>>[
    {
      'type': 'choices',
      'title': 'Pick a plan',
      'options': ['Free', 'Pro', 'Team'],
    },
    {
      'type': 'rating',
      'id': 'score',
      'label': 'Rate this demo',
      'max': 5,
    },
    {
      'type': 'box',
      'padding': 16,
      'gradient': ['#8B93FF', '#7FE3D0'],
      'radius': 20,
      'children': [
        {'type': 'text', 'text': 'Freeform primitives', 'weight': 'bold', 'color': '#0B0D12'},
        {'type': 'spacer', 'size': 8},
        {'type': 'button', 'label': 'Say hi', 'send': 'hi from a primitive'},
      ],
    },
    {'type': 'calculator'},
  ];

  @override
  Widget build(BuildContext context) {
    final actions = GenUiActions(
      sendMessage: (text) => setState(() => _lastSent = 'sent: $text'),
    );
    return MaterialApp(
      title: 'ethereal_genui example',
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('ethereal_genui')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final spec in _specs) buildGenUiSpec(context, spec, actions),
            const SizedBox(height: 24),
            Text(_lastSent, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
