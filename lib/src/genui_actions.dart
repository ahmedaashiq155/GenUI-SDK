import 'package:flutter/widgets.dart';

/// Callbacks every generative-UI renderer can use to act on the app.
@immutable
class GenUiActions {
  const GenUiActions({
    required this.sendMessage,
    this.setAccent,
    this.setShortcuts,
    this.openArtifact,
    this.enabled = true,
  });

  /// Send [text] as the next user turn (choices/actions/forms/etc.).
  final void Function(String text) sendMessage;

  /// Apply a per-conversation accent (a `theme` directive); hex like "#8B93FF".
  final void Function(String hex)? setAccent;

  /// Persist home-screen quick-action prompts (a `shortcuts` directive).
  final void Function(List<String> shortcuts)? setShortcuts;

  /// Open an `artifact` spec in a focused full-screen view. The host wires this
  /// (e.g. to a route); when null, the artifact card renders but doesn't open.
  final void Function(Map<String, dynamic> spec)? openArtifact;

  /// Whether interactive controls are enabled (false while streaming or for
  /// historical, superseded messages).
  final bool enabled;
}
