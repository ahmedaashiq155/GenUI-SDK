import 'package:flutter/material.dart';

import '../genui_actions.dart';
import '../genui_theme.dart';

/// {"type":"artifact","kind":"code|markdown|table|text","title":"…","content":"…","language":"dart"}
/// A compact card in the chat that opens a focused artifact view via the host's
/// [GenUiActions.openArtifact] callback (so the engine needs no app route).
class ArtifactRenderer extends StatelessWidget {
  const ArtifactRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final kind = (spec['kind'] ?? 'text').toString();
    final title = (spec['title'] ?? 'Artifact').toString();
    final icon = switch (kind) {
      'code' => Icons.code_rounded,
      'markdown' => Icons.article_outlined,
      'table' => Icons.table_chart_outlined,
      'html' => Icons.web_rounded,
      _ => Icons.description_outlined,
    };
    return GenUiPressable(
      onTap: () => actions.openArtifact?.call(spec),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
        padding: const EdgeInsets.all(GenUiSpace.md),
        decoration: ShapeDecoration(
          color: colors.surface.withValues(alpha: 0.6),
          shape: GenUiShape.shape(GenUiRadii.lg,
              side: BorderSide(color: colors.glassBorder)),
        ),
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
            const SizedBox(width: GenUiSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text('$kind · tap to open',
                      style: text.bodyMedium?.copyWith(color: colors.textTertiary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.open_in_full_rounded, size: 16, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}
