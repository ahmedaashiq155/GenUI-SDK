import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_common.dart';
import '../genui_state.dart';

List<String> _strings(dynamic v) =>
    (v is List ? v : const <dynamic>[]).map((e) => e.toString()).toList();
List<Map<String, dynamic>> _maps(dynamic v) =>
    (v is List ? v : const <dynamic>[]).whereType<Map<String, dynamic>>().toList();
int _int(dynamic v, int fallback) =>
    v is num ? v.toInt() : int.tryParse('$v') ?? fallback;

/// {"type":"rating","label":"…","max":5} — tap a star to send the rating.
class RatingRenderer extends StatefulWidget {
  const RatingRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<RatingRenderer> createState() => _RatingRendererState();
}

class _RatingRendererState extends State<RatingRenderer>
    with GenUiPersistedState<RatingRenderer> {
  int _value = 0;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is num) _value = stored.toInt();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    // Clamp: {"max": 100000000} would synchronously build 100M Icon widgets
    // and hang/OOM the UI thread from a single message.
    final max = _int(widget.spec['max'], 5).clamp(1, 20);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, (widget.spec['label'] ?? widget.spec['title'])?.toString()),
          Row(
            children: [
              for (var i = 1; i <= max; i++)
                GenUiPressable(
                  haptic: false,
                  semanticLabel: '$i of $max stars',
                  onTap: widget.actions.enabled
                      ? () {
                          setState(() => _value = i);
                          persist(i);
                          widget.actions.sendMessage('$i out of $max');
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      i <= _value ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: colors.accent,
                      size: 32,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// {"type":"segmented","options":["…"]} — single pick, sends on tap.
class SegmentedRenderer extends StatefulWidget {
  const SegmentedRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<SegmentedRenderer> createState() => _SegmentedRendererState();
}

class _SegmentedRendererState extends State<SegmentedRenderer>
    with GenUiPersistedState<SegmentedRenderer> {
  int _index = -1;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is num) _index = stored.toInt();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final options = genUiOptions(widget.spec['options']);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, widget.spec['title']?.toString()),
          Container(
            decoration: ShapeDecoration(
              color: colors.surface.withValues(alpha: 0.6),
              shape: GenUiShape.shape(GenUiRadii.md),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                for (var i = 0; i < options.length; i++)
                  Expanded(
                    child: GenUiPressable(
                      onTap: widget.actions.enabled
                          ? () {
                              setState(() => _index = i);
                              persist(i);
                              widget.actions.sendMessage(options[i].value);
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: GenUiMotion.quick,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: GenUiSpace.sm + 2),
                        decoration: ShapeDecoration(
                          color: i == _index ? colors.accent : Colors.transparent,
                          shape: GenUiShape.shape(GenUiRadii.sm),
                        ),
                        child: Text(options[i].label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: i == _index ? colors.onAccent : colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// {"type":"stepper","label":"Guests","min":1,"max":9,"value":2,"unit":""}
class StepperRenderer extends StatefulWidget {
  const StepperRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<StepperRenderer> createState() => _StepperRendererState();
}

class _StepperRendererState extends State<StepperRenderer>
    with GenUiPersistedState<StepperRenderer> {
  late int _value;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is num) _value = stored.toInt();
  }

  @override
  void initState() {
    super.initState();
    _value = _int(widget.spec['value'], _int(widget.spec['min'], 0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final min = _int(widget.spec['min'], 0);
    final max = _int(widget.spec['max'], 99);
    final step = _int(widget.spec['step'], 1);
    final unit = (widget.spec['unit'] ?? '').toString();
    final label = (widget.spec['label'] ?? widget.spec['title'] ?? '').toString();

    Widget btn(IconData icon, VoidCallback? onTap, String label) => GenUiPressable(
          onTap: onTap,
          semanticLabel: label,
          child: Container(
            width: 38,
            height: 38,
            decoration: ShapeDecoration(
              color: colors.accent.withValues(alpha: 0.16),
              shape: GenUiShape.shape(GenUiRadii.pill),
            ),
            child: Icon(icon, color: colors.accent, size: 20),
          ),
        );

    return GenUi.frame(
      context,
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          btn(
              Icons.remove_rounded,
              // Guard on the post-step value, not just `> min`, so a step > 1
              // can't overshoot below min (and strand the control disabled).
              widget.actions.enabled && _value - step >= min
                  ? () {
                      setState(() => _value = (_value - step).clamp(min, max));
                      persist(_value);
                    }
                  : null,
              'Decrease'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GenUiSpace.md),
            child: Text('$_value$unit',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          btn(
              Icons.add_rounded,
              widget.actions.enabled && _value + step <= max
                  ? () {
                      setState(() => _value = (_value + step).clamp(min, max));
                      persist(_value);
                    }
                  : null,
              'Increase'),
          const SizedBox(width: GenUiSpace.md),
          GenUiPressable(
            onTap: widget.actions.enabled
                ? () => widget.actions.sendMessage('$label: $_value$unit'.trim())
                : null,
            semanticLabel: 'Send',
            child: Icon(Icons.send_rounded, color: colors.accent, size: 22),
          ),
        ],
      ),
    );
  }
}

/// {"type":"checklist","title":"…","items":["…"],"submitLabel":"Done"}
class ChecklistRenderer extends StatefulWidget {
  const ChecklistRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<ChecklistRenderer> createState() => _ChecklistRendererState();
}

class _ChecklistRendererState extends State<ChecklistRenderer>
    with GenUiPersistedState<ChecklistRenderer> {
  final _checked = <int>{};
  bool _restoredFromScope = false;
  bool _seeded = false;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is List) {
      _restoredFromScope = true;
      _checked
        ..clear()
        ..addAll(stored.whereType<num>().map((n) => n.toInt()));
    }
  }

  void _toggle(int i) {
    setState(() => _checked.contains(i) ? _checked.remove(i) : _checked.add(i));
    persist(_checked.toList());
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final items = genUiOptions(widget.spec['items'] ?? widget.spec['options']);
    // First build with no persisted state: honour each item's `checked` flag.
    if (!_seeded) {
      _seeded = true;
      if (!_restoredFromScope) {
        for (var i = 0; i < items.length; i++) {
          if (items[i].checked) _checked.add(i);
        }
      }
    }
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, widget.spec['title']?.toString()),
          for (var i = 0; i < items.length; i++)
            GenUiPressable(
              haptic: false,
              onTap: widget.actions.enabled ? () => _toggle(i) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      _checked.contains(i)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _checked.contains(i) ? colors.celadon : colors.textTertiary,
                      size: 22,
                    ),
                    const SizedBox(width: GenUiSpace.sm),
                    Expanded(
                      child: Text(items[i].label,
                          style: TextStyle(
                            color: colors.textPrimary,
                            decoration: _checked.contains(i)
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: colors.textTertiary,
                          )),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: GenUiSpace.sm),
          GenUi.submitButton(
            context,
            (widget.spec['submitLabel'] ?? 'Submit').toString(),
            widget.actions.enabled && _checked.isNotEmpty
                ? () => widget.actions.sendMessage(
                    [for (final i in _checked) items[i].label].join(', '))
                : null,
          ),
        ],
      ),
    );
  }
}

/// {"type":"poll","title":"…","options":[{"label":"A","votes":3}]}
class PollRenderer extends StatefulWidget {
  const PollRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<PollRenderer> createState() => _PollRendererState();
}

class _PollRendererState extends State<PollRenderer>
    with GenUiPersistedState<PollRenderer> {
  int _voted = -1;
  late final List<int> _votes;
  late final List<String> _labels;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    // Persist only the chosen index; re-apply its increment so the tally shown
    // matches what the user saw, without storing the whole vote array.
    if (stored is num) {
      final v = stored.toInt();
      if (v >= 0 && v < _votes.length) {
        _voted = v;
        _votes[v] += 1;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final opts = _maps(widget.spec['options']);
    if (opts.isNotEmpty) {
      _labels = opts.map((o) => (o['label'] ?? '').toString()).toList();
      _votes = opts.map((o) => _int(o['votes'], 0)).toList();
    } else {
      _labels = _strings(widget.spec['options']);
      _votes = List<int>.filled(_labels.length, 0, growable: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final total = _votes.fold<int>(0, (a, b) => a + b).clamp(1, 1 << 30);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, widget.spec['title']?.toString()),
          for (var i = 0; i < _labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GenUiPressable(
                haptic: false,
                onTap: widget.actions.enabled && _voted < 0
                    ? () {
                        setState(() {
                          _voted = i;
                          _votes[i] += 1;
                        });
                        persist(i);
                        widget.actions.sendMessage(_labels[i]);
                      }
                    : null,
                child: _bar(context, i, total, colors),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, int i, int total, GenUiColors colors) {
    final pct = _voted < 0 ? 0.0 : _votes[i] / total;
    return Stack(
      children: [
        Container(
          height: 40,
          decoration: ShapeDecoration(
            color: colors.surface.withValues(alpha: 0.5),
            shape: GenUiShape.shape(GenUiRadii.sm),
          ),
        ),
        if (_voted >= 0)
          FractionallySizedBox(
            widthFactor: pct.clamp(0.0, 1.0),
            child: Container(
              height: 40,
              decoration: ShapeDecoration(
                color: i == _voted
                    ? colors.accent.withValues(alpha: 0.28)
                    : colors.accent.withValues(alpha: 0.12),
                shape: GenUiShape.shape(GenUiRadii.sm),
              ),
            ),
          ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: GenUiSpace.md),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(_labels[i],
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: i == _voted ? FontWeight.w700 : FontWeight.w500)),
              ),
              if (_voted >= 0)
                Text('${(pct * 100).round()}%',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

/// {"type":"quiz","question":"…","options":["…"],"answer":1,"explanation":"…"}
class QuizRenderer extends StatefulWidget {
  const QuizRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<QuizRenderer> createState() => _QuizRendererState();
}

class _QuizRendererState extends State<QuizRenderer>
    with GenUiPersistedState<QuizRenderer> {
  int _picked = -1;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is num) _picked = stored.toInt();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final text = Theme.of(context).textTheme;
    final options = genUiOptions(widget.spec['options']);
    final answer = _int(widget.spec['answer'], -1);
    final answered = _picked >= 0;

    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.spec['question'] ?? widget.spec['title'] ?? ''}',
              style: text.titleMedium),
          const SizedBox(height: GenUiSpace.md),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: GenUiPressable(
                haptic: false,
                onTap: widget.actions.enabled && !answered
                    ? () {
                        setState(() => _picked = i);
                        persist(i);
                      }
                    : null,
                child: Builder(builder: (context) {
                  Color border = colors.hairline;
                  Color? fill;
                  IconData? icon;
                  if (answered && i == answer) {
                    border = colors.celadon;
                    fill = colors.celadon.withValues(alpha: 0.14);
                    icon = Icons.check_circle_rounded;
                  } else if (answered && i == _picked) {
                    border = colors.danger;
                    fill = colors.danger.withValues(alpha: 0.12);
                    icon = Icons.cancel_rounded;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: GenUiSpace.md, vertical: GenUiSpace.md),
                    decoration: ShapeDecoration(
                      color: fill ?? colors.surface.withValues(alpha: 0.4),
                      shape: GenUiShape.shape(GenUiRadii.md, side: BorderSide(color: border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(options[i].label, style: text.bodyLarge)),
                        if (icon != null)
                          Icon(icon, size: 18,
                              color: i == answer ? colors.celadon : colors.danger),
                      ],
                    ),
                  );
                }),
              ),
            ),
          if (answered && widget.spec['explanation'] != null) ...[
            const SizedBox(height: GenUiSpace.sm),
            Text('${widget.spec['explanation']}',
                style: text.bodyMedium?.copyWith(color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}
