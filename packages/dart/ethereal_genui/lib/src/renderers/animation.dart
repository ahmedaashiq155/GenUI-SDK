import 'dart:async';

import 'package:flutter/material.dart';

import '../genui_actions.dart';
import '../genui_block.dart';
import '../genui_theme.dart';

/// Declarative, reduce-motion-aware entrance/emphasis animation.
///
/// `effect` supports fade, scale, slideUp, slideDown, slideStart, slideEnd and
/// pulse. The wrapper never changes the semantics tree or dispatch behavior.
class AnimationRenderer extends StatefulWidget {
  const AnimationRenderer({
    super.key,
    required this.spec,
    required this.actions,
  });

  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<AnimationRenderer> createState() => _AnimationRendererState();
}

class _AnimationRendererState extends State<AnimationRenderer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  int _generation = 0;
  bool _configured = false;

  int _milliseconds(String key, int fallback) {
    final raw = widget.spec[key];
    return (raw is num ? raw.toInt() : fallback).clamp(0, 10000);
  }

  Duration get _duration =>
      Duration(milliseconds: _milliseconds('duration', 250));

  Duration get _delay => Duration(milliseconds: _milliseconds('delay', 0));

  bool get _repeat => widget.spec['repeat'] == true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_configured) _configure();
  }

  @override
  void didUpdateWidget(covariant AnimationRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec != widget.spec) _configure();
  }

  Future<void> _configure() async {
    _configured = true;
    final generation = ++_generation;
    _controller
      ..stop()
      ..duration = _duration;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    _controller.value = 0;
    if (_delay > Duration.zero) await Future<void>.delayed(_delay);
    if (!mounted || generation != _generation) return;
    if (_repeat) {
      unawaited(_controller.repeat(reverse: true));
    } else {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _generation++;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childSpec = widget.spec['child'];
    if (childSpec is! Map) return const SizedBox.shrink();
    final child = buildGenUiSpec(
      context,
      childSpec.map((key, value) => MapEntry(key.toString(), value)),
      widget.actions,
    );
    final effect = (widget.spec['effect'] ?? 'fade').toString();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: GenUiTheme.of(context).motion.curve,
    );
    final offset = switch (effect) {
      'slideDown' => const Offset(0, -0.08),
      'slideStart' => const Offset(-0.08, 0),
      'slideEnd' => const Offset(0.08, 0),
      _ => const Offset(0, 0.08),
    };

    return switch (effect) {
      'scale' => ScaleTransition(
        scale: Tween(begin: 0.94, end: 1.0).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      ),
      'pulse' => ScaleTransition(
        scale: Tween(begin: 0.97, end: 1.0).animate(curve),
        child: child,
      ),
      'slideUp' || 'slideDown' || 'slideStart' || 'slideEnd' => SlideTransition(
        position: Tween(begin: offset, end: Offset.zero).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      ),
      _ => FadeTransition(opacity: curve, child: child),
    };
  }
}
