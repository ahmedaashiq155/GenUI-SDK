import 'dart:async';

import 'package:flutter/widgets.dart';

/// Keys for every framework-owned string. Model-authored labels remain the
/// model's responsibility; hosts can translate these fallbacks with
/// [GenUiLocalizationsDelegate].
abstract final class GenUiStringKey {
  static const preparing = 'preparing';
  static const renderError = 'renderError';
  static const unsupportedBlock = 'unsupportedBlock';
  static const noChartData = 'noChartData';
  static const noImages = 'noImages';
  static const noBadges = 'noBadges';
  static const noTabs = 'noTabs';
  static const requiredField = 'requiredField';
  static const send = 'send';
  static const submit = 'submit';
  static const button = 'button';
  static const artifact = 'artifact';
  static const openArtifact = 'openArtifact';
  static const tapToOpen = 'tapToOpen';
  static const decrease = 'decrease';
  static const increase = 'increase';
  static const timerReady = 'timerReady';
  static const timerStarted = 'timerStarted';
  static const timerPaused = 'timerPaused';
  static const timerComplete = 'timerComplete';
  static const pause = 'pause';
  static const restart = 'restart';
  static const start = 'start';
  static const pauseTimer = 'pauseTimer';
  static const startTimer = 'startTimer';
  static const messageHint = 'messageHint';
  static const apply = 'apply';
  static const save = 'save';
  static const suggestedAccent = 'suggestedAccent';
  static const appliedAccent = 'appliedAccent';
  static const suggestedShortcuts = 'suggestedShortcuts';
  static const savedShortcuts = 'savedShortcuts';
  static const addAttachment = 'addAttachment';
  static const removeAttachment = 'removeAttachment';
  static const startVoiceInput = 'startVoiceInput';
  static const stopListening = 'stopListening';
}

/// Subtree-aware localization hook for framework-owned UI copy.
///
/// Add a [GenUiLocalizationsDelegate] to the host app's
/// `localizationsDelegates`. Missing keys deliberately fall back to the
/// renderer's English text, so partial translations are safe.
@immutable
class GenUiLocalizations {
  const GenUiLocalizations([this.values = const <String, String>{}]);

  final Map<String, String> values;

  static GenUiLocalizations of(BuildContext context) =>
      Localizations.of<GenUiLocalizations>(context, GenUiLocalizations) ??
      const GenUiLocalizations();

  String text(
    String key,
    String fallback, {
    Map<String, Object> replacements = const <String, Object>{},
  }) {
    var result = values[key] ?? fallback;
    for (final entry in replacements.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }
}

typedef GenUiLocalizationLoader =
    FutureOr<GenUiLocalizations> Function(Locale locale);

/// A host-supplied delegate that loads localized GenUI strings for a locale.
class GenUiLocalizationsDelegate
    extends LocalizationsDelegate<GenUiLocalizations> {
  const GenUiLocalizationsDelegate({
    required this.loadStrings,
    this.isLocaleSupported,
    this.shouldReloadDelegate = false,
  });

  final GenUiLocalizationLoader loadStrings;
  final bool Function(Locale locale)? isLocaleSupported;
  final bool shouldReloadDelegate;

  @override
  bool isSupported(Locale locale) => isLocaleSupported?.call(locale) ?? true;

  @override
  Future<GenUiLocalizations> load(Locale locale) async => loadStrings(locale);

  @override
  bool shouldReload(covariant GenUiLocalizationsDelegate old) =>
      shouldReloadDelegate ||
      old.loadStrings != loadStrings ||
      old.isLocaleSupported != isLocaleSupported;
}
