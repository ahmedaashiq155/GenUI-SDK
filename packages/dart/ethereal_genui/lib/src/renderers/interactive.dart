import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_common.dart';
import '../genui_localizations.dart';
import '../genui_state.dart';

List<String> _strings(dynamic v) =>
    (v is List ? v : const <dynamic>[]).map((e) => e.toString()).toList();
List<Map<String, dynamic>> _maps(dynamic v) =>
    (v is List ? v : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
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
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    // Clamp: {"max": 100000000} would synchronously build 100M Icon widgets
    // and hang/OOM the UI thread from a single message.
    final max = _int(widget.spec['max'], 5).clamp(1, 20);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(
            context,
            (widget.spec['label'] ?? widget.spec['title'])?.toString(),
          ),
          Row(
            children: [
              for (var i = 1; i <= max; i++)
                GenUiPressable(
                  haptic: false,
                  semanticLabel: '$i of $max stars',
                  selected: i <= _value,
                  onTap: widget.actions.enabled
                      ? () {
                          setState(() => _value = i);
                          persist(i);
                          widget.actions.sendMessage('$i out of $max');
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: GenUiSpace.xs,
                    ),
                    child: Icon(
                      i <= _value
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
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
  const SegmentedRenderer({
    super.key,
    required this.spec,
    required this.actions,
  });
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
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
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
                      selected: i == _index,
                      onTap: widget.actions.enabled
                          ? () {
                              setState(() => _index = i);
                              persist(i);
                              widget.actions.sendMessage(options[i].value);
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: theme.motion.quick,
                        curve: theme.motion.curve,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: GenUiSpace.sm + 2,
                        ),
                        decoration: ShapeDecoration(
                          color: i == _index
                              ? colors.accent
                              : Colors.transparent,
                          shape: GenUiShape.shape(GenUiRadii.sm),
                        ),
                        child: Text(
                          options[i].label,
                          textAlign: TextAlign.center,
                          style: text.labelMedium?.copyWith(
                            color: i == _index
                                ? colors.onAccent
                                : colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  void didUpdateWidget(covariant StepperRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final min = _int(widget.spec['min'], 0);
    final max = _int(widget.spec['max'], 99);
    final lower = min <= max ? min : max;
    final upper = min <= max ? max : min;
    if (oldWidget.spec['value'] != widget.spec['value']) {
      _value = _int(widget.spec['value'], lower).clamp(lower, upper);
    } else {
      _value = _value.clamp(lower, upper);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final min = _int(widget.spec['min'], 0);
    final max = _int(widget.spec['max'], 99);
    final step = _int(widget.spec['step'], 1);
    final unit = (widget.spec['unit'] ?? '').toString();
    final label = (widget.spec['label'] ?? widget.spec['title'] ?? '')
        .toString();

    Widget btn(IconData icon, VoidCallback? onTap, String label) =>
        GenUiPressable(
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
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
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
            GenUiLocalizations.of(
              context,
            ).text(GenUiStringKey.decrease, 'Decrease'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GenUiSpace.md),
            child: Text(
              '$_value$unit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          btn(
            Icons.add_rounded,
            widget.actions.enabled && _value + step <= max
                ? () {
                    setState(() => _value = (_value + step).clamp(min, max));
                    persist(_value);
                  }
                : null,
            GenUiLocalizations.of(
              context,
            ).text(GenUiStringKey.increase, 'Increase'),
          ),
          const SizedBox(width: GenUiSpace.md),
          GenUiPressable(
            onTap: widget.actions.enabled
                ? () =>
                      widget.actions.sendMessage('$label: $_value$unit'.trim())
                : null,
            semanticLabel: GenUiLocalizations.of(
              context,
            ).text(GenUiStringKey.send, 'Send'),
            child: Icon(Icons.send_rounded, color: colors.accent, size: 22),
          ),
        ],
      ),
    );
  }
}

/// {"type":"checklist","title":"…","items":["…"],"submitLabel":"Done"}
class ChecklistRenderer extends StatefulWidget {
  const ChecklistRenderer({
    super.key,
    required this.spec,
    required this.actions,
  });
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<ChecklistRenderer> createState() => _ChecklistRendererState();
}

class _ChecklistRendererState extends State<ChecklistRenderer>
    with GenUiPersistedState<ChecklistRenderer> {
  final _checked = <String>{};
  final _legacyCheckedIndices = <int>{};
  bool _restoredFromScope = false;
  bool _seeded = false;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is List) {
      _restoredFromScope = true;
      _checked.clear();
      _legacyCheckedIndices.clear();
      for (final value in stored) {
        if (value is num) {
          _legacyCheckedIndices.add(value.toInt());
        } else {
          _checked.add(value.toString());
        }
      }
    }
  }

  void _toggle(String value) {
    setState(
      () => _checked.contains(value)
          ? _checked.remove(value)
          : _checked.add(value),
    );
    persist(_checked.toList());
  }

  @override
  void didUpdateWidget(covariant ChecklistRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final available = genUiOptions(
      widget.spec['items'] ?? widget.spec['options'],
    ).map((option) => option.value).toSet();
    _checked.removeWhere((value) => !available.contains(value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final items = genUiOptions(widget.spec['items'] ?? widget.spec['options']);
    if (_legacyCheckedIndices.isNotEmpty) {
      for (final index in _legacyCheckedIndices) {
        if (index >= 0 && index < items.length) {
          _checked.add(items[index].value);
        }
      }
      _legacyCheckedIndices.clear();
      persist(_checked.toList());
    }
    // First build with no persisted state: honour each item's `checked` flag.
    if (!_seeded) {
      _seeded = true;
      if (!_restoredFromScope) {
        for (var i = 0; i < items.length; i++) {
          if (items[i].checked) _checked.add(items[i].value);
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
              checked: _checked.contains(items[i].value),
              onTap: widget.actions.enabled
                  ? () => _toggle(items[i].value)
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GenUiSpace.xs),
                child: Row(
                  children: [
                    Icon(
                      _checked.contains(items[i].value)
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _checked.contains(items[i].value)
                          ? colors.celadon
                          : colors.textTertiary,
                      size: 22,
                    ),
                    const SizedBox(width: GenUiSpace.sm),
                    Expanded(
                      child: Text(
                        items[i].label,
                        style: text.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          decoration: _checked.contains(items[i].value)
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: GenUiSpace.sm),
          GenUi.submitButton(
            context,
            (widget.spec['submitLabel'] ??
                    GenUiLocalizations.of(
                      context,
                    ).text(GenUiStringKey.submit, 'Submit'))
                .toString(),
            widget.actions.enabled && _checked.isNotEmpty
                ? () => widget.actions.sendMessage(
                    [
                      for (final item in items)
                        if (_checked.contains(item.value)) item.label,
                    ].join(', '),
                  )
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
  String? _votedValue;
  late List<int> _baseVotes;
  late List<int> _votes;
  late List<String> _labels;
  late List<String> _values;
  bool _localVotePending = false;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    final value = stored is num
        ? (stored.toInt() >= 0 && stored.toInt() < _values.length
              ? _values[stored.toInt()]
              : null)
        : stored?.toString();
    if (value == null || !_values.contains(value)) return;
    _votedValue = value;
    _localVotePending = true;
    _votes[_values.indexOf(value)] += 1;
  }

  @override
  void initState() {
    super.initState();
    _readOptions(widget.spec);
  }

  void _readOptions(Map<String, dynamic> spec) {
    final opts = _maps(spec['options']);
    if (opts.isNotEmpty) {
      _labels = opts
          .map((o) => (o['label'] ?? o['value'] ?? '').toString())
          .toList();
      _values = opts
          .map((o) => (o['value'] ?? o['send'] ?? o['label'] ?? '').toString())
          .toList();
      _baseVotes = opts
          .map((o) => _int(o['votes'], 0).clamp(0, 1 << 30))
          .toList();
    } else {
      _labels = _strings(spec['options']);
      _values = List<String>.of(_labels);
      _baseVotes = List<int>.filled(_labels.length, 0, growable: true);
    }
    _votes = List<int>.of(_baseVotes, growable: true);
  }

  @override
  void didUpdateWidget(covariant PollRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _votedValue;
    final oldIndex = selected == null ? -1 : _values.indexOf(selected);
    final oldBase = oldIndex < 0 ? null : _baseVotes[oldIndex];
    _readOptions(widget.spec);
    final newIndex = selected == null ? -1 : _values.indexOf(selected);
    if (newIndex < 0) return;
    if (_localVotePending &&
        oldBase != null &&
        _baseVotes[newIndex] > oldBase) {
      // The patch advanced the selected option's server tally, so it has
      // acknowledged the local vote. Do not display the increment twice.
      _localVotePending = false;
    }
    if (_localVotePending) _votes[newIndex] += 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final voted = _votedValue == null ? -1 : _values.indexOf(_votedValue!);
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
                selected: i == voted,
                onTap: widget.actions.enabled && _votedValue == null
                    ? () {
                        setState(() {
                          _votedValue = _values[i];
                          _localVotePending = true;
                          _votes[i] += 1;
                        });
                        persist(_values[i]);
                        widget.actions.sendMessage(_values[i]);
                      }
                    : null,
                child: _bar(context, i, voted, total, colors),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(
    BuildContext context,
    int i,
    int voted,
    int total,
    GenUiColors colors,
  ) {
    final theme = GenUiTheme.of(context);
    final text = Theme.of(context).textTheme;
    final pct = voted < 0 ? 0.0 : _votes[i] / total;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: colors.surface.withValues(alpha: 0.5),
              shape: GenUiShape.shape(GenUiRadii.sm),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedFractionallySizedBox(
            duration: theme.motion.standard,
            curve: theme.motion.curve,
            alignment: AlignmentDirectional.centerStart,
            widthFactor: pct.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: i == voted
                    ? colors.accent.withValues(alpha: 0.28)
                    : colors.accent.withValues(alpha: 0.12),
                shape: GenUiShape.shape(GenUiRadii.sm),
              ),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
            horizontal: GenUiSpace.md,
            vertical: GenUiSpace.sm,
          ),
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _labels[i],
                  style: text.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: i == voted ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (voted >= 0)
                Text(
                  '${(pct * 100).round()}%',
                  style: text.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
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
    final theme = GenUiTheme.of(context);
    final colors = theme.colors;
    final text = Theme.of(context).textTheme;
    final options = genUiOptions(widget.spec['options']);
    final answer = _int(widget.spec['answer'], -1);
    final answered = _picked >= 0;

    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.spec['question'] ?? widget.spec['title'] ?? ''}',
            style: text.titleMedium,
          ),
          const SizedBox(height: GenUiSpace.md),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GenUiSpace.xs),
              child: GenUiPressable(
                haptic: false,
                selected: i == _picked,
                onTap: widget.actions.enabled && !answered
                    ? () {
                        setState(() => _picked = i);
                        persist(i);
                      }
                    : null,
                child: Builder(
                  builder: (context) {
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
                    return AnimatedContainer(
                      duration: theme.motion.quick,
                      curve: theme.motion.curve,
                      padding: const EdgeInsets.symmetric(
                        horizontal: GenUiSpace.md,
                        vertical: GenUiSpace.md,
                      ),
                      decoration: ShapeDecoration(
                        color: fill ?? colors.surface.withValues(alpha: 0.4),
                        shape: GenUiShape.shape(
                          GenUiRadii.md,
                          side: BorderSide(color: border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              options[i].label,
                              style: text.bodyLarge,
                            ),
                          ),
                          if (icon != null)
                            Icon(
                              icon,
                              size: 18,
                              color: i == answer
                                  ? colors.celadon
                                  : colors.danger,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          if (answered && widget.spec['explanation'] != null) ...[
            const SizedBox(height: GenUiSpace.sm),
            Text(
              '${widget.spec['explanation']}',
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
