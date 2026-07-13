import 'package:flutter/material.dart';

import '../genui_actions.dart';
import '../genui_common.dart';
import '../genui_localizations.dart';
import '../genui_theme.dart';

/// {"type":"artifact","kind":"code|markdown|table|text","title":"…","content":"…","language":"dart"}
/// A compact card in the chat that opens a focused artifact view via the host's
/// [GenUiActions.openArtifact] callback (so the engine needs no app route).
class ArtifactRenderer extends StatelessWidget {
  const ArtifactRenderer({
    super.key,
    required this.spec,
    required this.actions,
  });
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final strings = GenUiLocalizations.of(context);
    final kind = (spec['kind'] ?? 'text').toString();
    final title =
        (spec['title'] ?? strings.text(GenUiStringKey.artifact, 'Artifact'))
            .toString();
    final canOpen = actions.openArtifact != null;
    final icon = switch (kind) {
      'code' => Icons.code_rounded,
      'markdown' => Icons.article_outlined,
      'table' => Icons.table_chart_outlined,
      'html' => Icons.web_rounded,
      _ => Icons.description_outlined,
    };
    final card = GenUi.frame(
      context,
      variant: GenUiFrameVariant.flat,
      margin: EdgeInsets.symmetric(vertical: theme.spacing.sm),
      padding: EdgeInsets.all(theme.spacing.md),
      radius: theme.radii.lg,
      backgroundColor: colors.surface.withValues(alpha: 0.6),
      border: BorderSide(color: colors.glassBorder),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: colors.accent.withValues(alpha: 0.16),
              shape: GenUiShape.shape(GenUiRadii.md),
            ),
            child: Icon(icon, color: colors.accent, size: 20),
          ),
          SizedBox(width: theme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  canOpen
                      ? '$kind · ${strings.text(GenUiStringKey.tapToOpen, 'tap to open')}'
                      : kind,
                  style: text.bodyMedium?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (canOpen)
            Icon(
              Icons.open_in_full_rounded,
              size: 16,
              color: colors.textTertiary,
            ),
        ],
      ),
    );
    if (!canOpen) return card;
    return GenUiPressable(
      onTap: () => actions.openArtifact!(spec),
      semanticLabel: strings.text(
        GenUiStringKey.openArtifact,
        'Open {title}',
        replacements: {'title': title},
      ),
      child: card,
    );
  }
}
