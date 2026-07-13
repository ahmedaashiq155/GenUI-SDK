import 'dart:async';

import 'package:flutter/material.dart';

import 'genui_localizations.dart';
import 'genui_theme.dart';

/// A host adapter for platform/cloud speech services. GenUI deliberately asks
/// for no microphone permission and ships no vendor SDK.
abstract interface class GenUiVoiceAdapter {
  Stream<String> transcribe({Locale? locale});
  FutureOr<void> stopTranscribing();
  FutureOr<void> speak(String text, {Locale? locale});
  FutureOr<void> stopSpeaking();
}

enum GenUiVoiceState { idle, listening, speaking, error }

class GenUiVoiceController extends ChangeNotifier {
  GenUiVoiceController({required this.adapter});

  final GenUiVoiceAdapter adapter;
  StreamSubscription<String>? _subscription;
  GenUiVoiceState _state = GenUiVoiceState.idle;
  String _transcript = '';
  Object? _error;

  GenUiVoiceState get state => _state;
  String get transcript => _transcript;
  Object? get error => _error;

  Future<void> startListening({Locale? locale}) async {
    await stop();
    _state = GenUiVoiceState.listening;
    _error = null;
    notifyListeners();
    _subscription = adapter
        .transcribe(locale: locale)
        .listen(
          (text) {
            _transcript = text;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error;
            _state = GenUiVoiceState.error;
            notifyListeners();
          },
          onDone: () {
            if (_state == GenUiVoiceState.listening) {
              _state = GenUiVoiceState.idle;
              notifyListeners();
            }
          },
        );
  }

  Future<void> speak(String text, {Locale? locale}) async {
    if (text.trim().isEmpty) return;
    await stop();
    _state = GenUiVoiceState.speaking;
    _error = null;
    notifyListeners();
    try {
      await adapter.speak(text, locale: locale);
      if (_state == GenUiVoiceState.speaking) _state = GenUiVoiceState.idle;
    } catch (error) {
      _error = error;
      _state = GenUiVoiceState.error;
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_state == GenUiVoiceState.listening) {
      await adapter.stopTranscribing();
    } else if (_state == GenUiVoiceState.speaking) {
      await adapter.stopSpeaking();
    }
    _state = GenUiVoiceState.idle;
    notifyListeners();
  }

  void clearTranscript() {
    _transcript = '';
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}

class GenUiVoiceButton extends StatefulWidget {
  const GenUiVoiceButton({
    super.key,
    required this.controller,
    this.locale,
    this.onTranscript,
  });

  final GenUiVoiceController controller;
  final Locale? locale;
  final ValueChanged<String>? onTranscript;

  @override
  State<GenUiVoiceButton> createState() => _GenUiVoiceButtonState();
}

class _GenUiVoiceButtonState extends State<GenUiVoiceButton> {
  String _lastTranscript = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleController);
  }

  @override
  void didUpdateWidget(covariant GenUiVoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleController);
      widget.controller.addListener(_handleController);
      _lastTranscript = '';
    }
  }

  void _handleController() {
    final transcript = widget.controller.transcript;
    if (transcript.isNotEmpty && transcript != _lastTranscript) {
      _lastTranscript = transcript;
      widget.onTranscript?.call(transcript);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final listening = controller.state == GenUiVoiceState.listening;
    final strings = GenUiLocalizations.of(context);
    final label = listening
        ? strings.text(GenUiStringKey.stopListening, 'Stop listening')
        : strings.text(GenUiStringKey.startVoiceInput, 'Start voice input');
    return GenUiPressable(
      semanticLabel: label,
      selected: listening,
      onTap: listening
          ? controller.stop
          : () => controller.startListening(locale: widget.locale),
      child: Icon(
        listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
        color: listening
            ? GenUiColors.of(context).danger
            : GenUiColors.of(context).accent,
      ),
    );
  }
}
