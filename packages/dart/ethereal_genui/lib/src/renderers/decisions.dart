import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_common.dart';

/// {"type":"choices","title":"…","options":["A","B"]}
class ChoicesRenderer extends StatelessWidget {
  const ChoicesRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final options = genUiOptions(spec['options']);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, spec['title']?.toString()),
          Wrap(
            spacing: GenUiSpace.sm,
            runSpacing: GenUiSpace.sm,
            children: [
              for (final o in options)
                GenUi.pill(context, o.label,
                    actions.enabled ? () => actions.sendMessage(o.value) : null),
            ],
          ),
        ],
      ),
    );
  }
}

/// {"type":"actions","actions":[{"label":"Yes","send":"Yes please"}]}
class ActionsRenderer extends StatelessWidget {
  const ActionsRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final items = (spec['actions'] is List ? spec['actions'] as List<dynamic> : const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, spec['title']?.toString()),
          Wrap(
            spacing: GenUiSpace.sm,
            runSpacing: GenUiSpace.sm,
            children: [
              for (final a in items)
                GenUi.pill(
                  context,
                  (a['label'] ?? '').toString(),
                  actions.enabled
                      ? () => actions.sendMessage(
                          (a['send'] ?? a['label'] ?? '').toString())
                      : null,
                  filled: a['primary'] == true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// {"type":"confirm","prompt":"…","confirmLabel":"Yes","cancelLabel":"No"}
class ConfirmRenderer extends StatelessWidget {
  const ConfirmRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final prompt = (spec['prompt'] ?? spec['title'] ?? 'Confirm?').toString();
    final confirmLabel = (spec['confirmLabel'] ?? 'Yes').toString();
    final cancelLabel = (spec['cancelLabel'] ?? 'No').toString();
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: GenUiSpace.md),
          Row(
            children: [
              GenUi.pill(context, confirmLabel,
                  actions.enabled ? () => actions.sendMessage(confirmLabel) : null,
                  filled: true),
              const SizedBox(width: GenUiSpace.sm),
              GenUi.pill(context, cancelLabel,
                  actions.enabled ? () => actions.sendMessage(cancelLabel) : null),
            ],
          ),
        ],
      ),
    );
  }
}

/// {"type":"suggestions","options":["…"]} — quick-reply chips (lighter style).
class SuggestionsRenderer extends StatelessWidget {
  const SuggestionsRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final options =
        genUiOptions(spec['options'] ?? spec['suggestions'] ?? spec['prompts']);
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
      child: Wrap(
        spacing: GenUiSpace.sm,
        runSpacing: GenUiSpace.sm,
        children: [
          for (final o in options)
            GenUi.pill(
              context,
              o.label,
              actions.enabled ? () => actions.sendMessage(o.value) : null,
              icon: Icons.north_east_rounded,
            ),
        ],
      ),
    );
  }
}
