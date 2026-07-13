import 'dart:async';

import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_common.dart';
import '../genui_localizations.dart';

const _keyLabels = {
  '×': 'multiply',
  '÷': 'divide',
  '−': 'minus',
  '+': 'plus',
  '=': 'equals',
  'C': 'clear',
  '.': 'point',
};

/// {"type":"calculator"} — a fully local calculator (no model round-trip).
class CalculatorRenderer extends StatefulWidget {
  const CalculatorRenderer({super.key});

  @override
  State<CalculatorRenderer> createState() => _CalculatorRendererState();
}

class _CalculatorRendererState extends State<CalculatorRenderer> {
  String _display = '0';
  double? _acc;
  String? _op;
  bool _resetNext = true;

  double get _current => double.tryParse(_display) ?? 0;

  void _digit(String d) => setState(() {
    if (_resetNext || _display == '0') {
      _display = d == '.' ? '0.' : d;
      _resetNext = false;
    } else if (!(d == '.' && _display.contains('.'))) {
      _display += d;
    }
  });

  void _setOp(String op) => setState(() {
    if (_op != null && !_resetNext) _compute();
    _acc = _current;
    _op = op;
    _resetNext = true;
  });

  void _compute() {
    if (_op == null || _acc == null) return;
    final b = _current;
    final r = switch (_op) {
      '+' => _acc! + b,
      '−' => _acc! - b,
      '×' => _acc! * b,
      '÷' => b == 0 ? double.nan : _acc! / b,
      _ => b,
    };
    _display = r.isNaN
        ? 'Error'
        : (r == r.roundToDouble() ? r.toInt().toString() : r.toString());
    _acc = null;
    _op = null;
    _resetNext = true;
  }

  void _clear() => setState(() {
    _display = '0';
    _acc = null;
    _op = null;
    _resetNext = true;
  });

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    const rows = [
      ['C', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];
    return GenUi.frame(
      context,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(GenUiSpace.md),
            alignment: AlignmentDirectional.centerEnd,
            decoration: ShapeDecoration(
              color: colors.surface.withValues(alpha: 0.6),
              shape: GenUiShape.shape(GenUiRadii.md),
            ),
            child: Text(
              _display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: GenUiSpace.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: GenUiSpace.sm),
              child: Row(
                children: [
                  for (final key in row) ...[
                    Expanded(
                      flex: key == '0' ? 1 : 1,
                      child: _key(context, key, colors),
                    ),
                    if (key != row.last) const SizedBox(width: GenUiSpace.sm),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, String key, GenUiColors colors) {
    final theme = GenUiTheme.of(context);
    final text = Theme.of(context).textTheme;
    final isOp = '+−×÷='.contains(key);
    final isClear = key == 'C';
    final bg = isClear
        ? colors.danger.withValues(alpha: 0.16)
        : isOp
        ? colors.accent.withValues(alpha: 0.18)
        : colors.surface.withValues(alpha: 0.5);
    final fg = isClear
        ? colors.danger
        : isOp
        ? colors.accent
        : colors.textPrimary;
    return GenUiPressable(
      haptic: false,
      semanticLabel: _keyLabels[key] ?? key,
      onTap: () {
        if (key == 'C') {
          _clear();
        } else if (key == '=') {
          setState(_compute);
        } else if (isOp) {
          _setOp(key);
        } else {
          _digit(key);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(vertical: GenUiSpace.sm),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: bg,
          shape: GenUiShape.shape(theme.radii.md),
        ),
        child: Text(
          key,
          style: text.titleMedium?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// {"type":"converter","title":"Length","units":[{"label":"m","factor":1},{"label":"km","factor":1000}]}
class ConverterRenderer extends StatefulWidget {
  const ConverterRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  State<ConverterRenderer> createState() => _ConverterRendererState();
}

class _ConverterRendererState extends State<ConverterRenderer> {
  final _controller = TextEditingController(text: '1');
  int _from = 0;
  int _to = 1;

  late List<String> _labels;
  late List<double> _factors;

  @override
  void initState() {
    super.initState();
    _readUnits(widget.spec);
  }

  void _readUnits(Map<String, dynamic> spec) {
    final units =
        (spec['units'] is List ? spec['units'] as List<dynamic> : const [])
            .whereType<Map<String, dynamic>>()
            .toList();
    if (units.length >= 2) {
      _labels = units.map((u) => (u['label'] ?? '').toString()).toList();
      _factors = units
          .map(
            (u) => (u['factor'] is num) ? (u['factor'] as num).toDouble() : 1.0,
          )
          .toList();
    } else {
      _labels = ['m', 'km', 'mi', 'ft'];
      _factors = [1, 1000, 1609.344, 0.3048];
    }
    _to = _labels.length > 1 ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant ConverterRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousFrom = _from >= 0 && _from < _labels.length
        ? _labels[_from]
        : null;
    final previousTo = _to >= 0 && _to < _labels.length ? _labels[_to] : null;
    _readUnits(widget.spec);
    final nextFrom = previousFrom == null ? -1 : _labels.indexOf(previousFrom);
    final nextTo = previousTo == null ? -1 : _labels.indexOf(previousTo);
    _from = nextFrom >= 0 ? nextFrom : 0;
    _to = nextTo >= 0 ? nextTo : (_labels.length > 1 ? 1 : 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final input = double.tryParse(_controller.text) ?? 0;
    final result = _factors[_to] == 0
        ? 0
        : input * _factors[_from] / _factors[_to];
    final resultStr = result == result.roundToDouble()
        ? result.toInt().toString()
        : result.toStringAsFixed(4);

    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, widget.spec['title']?.toString()),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
              const SizedBox(width: GenUiSpace.sm),
              _unitMenu(
                context,
                colors,
                _from,
                (v) => setState(() => _from = v),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: GenUiSpace.sm),
            child: Icon(Icons.swap_vert_rounded),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  resultStr,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: colors.accent),
                ),
              ),
              const SizedBox(width: GenUiSpace.sm),
              _unitMenu(context, colors, _to, (v) => setState(() => _to = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitMenu(
    BuildContext context,
    GenUiColors colors,
    int value,
    ValueChanged<int> onChanged,
  ) {
    final theme = GenUiTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.sm),
      decoration: ShapeDecoration(
        color: colors.accent.withValues(alpha: 0.14),
        shape: GenUiShape.shape(theme.radii.sm),
      ),
      child: DropdownButton<int>(
        value: value,
        underline: const SizedBox.shrink(),
        dropdownColor: colors.surfaceRaised,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w600,
        ),
        items: [
          for (var i = 0; i < _labels.length; i++)
            DropdownMenuItem(value: i, child: Text(_labels[i])),
        ],
        onChanged: (v) => v == null ? null : onChanged(v),
      ),
    );
  }
}

/// {"type":"timer","seconds":60,"label":"Steep tea"} — local countdown.
class TimerRenderer extends StatefulWidget {
  const TimerRenderer({super.key, required this.spec});
  final Map<String, dynamic> spec;

  @override
  State<TimerRenderer> createState() => _TimerRendererState();
}

enum _TimerPhase { idle, running, paused, done }

class _TimerRendererState extends State<TimerRenderer> {
  late int _total;
  late int _remaining;
  Timer? _timer;
  _TimerPhase _phase = _TimerPhase.idle;

  @override
  void initState() {
    super.initState();
    _total = _readTotal(widget.spec);
    _remaining = _total;
  }

  int _readTotal(Map<String, dynamic> spec) {
    final raw = spec['seconds'] is num ? (spec['seconds'] as num).toInt() : 60;
    return raw.clamp(0, 86400).toInt();
  }

  @override
  void didUpdateWidget(covariant TimerRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextTotal = _readTotal(widget.spec);
    if (nextTotal == _total) return;
    _timer?.cancel();
    _timer = null;
    _total = nextTotal;
    _remaining = nextTotal;
    _phase = _TimerPhase.idle;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() {
        _timer = null;
        _phase = _TimerPhase.paused;
      });
      return;
    }
    setState(() {
      if (_remaining == 0) _remaining = _total;
      _phase = _TimerPhase.running;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 1) {
          t.cancel();
          setState(() {
            _remaining = 0;
            _timer = null;
            _phase = _TimerPhase.done;
          });
        } else {
          // Only _remaining changes on a tick — _phase must stay untouched so
          // the live region doesn't re-announce every second.
          setState(() => _remaining -= 1);
        }
      });
    });
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Note: only the idle/paused cases interpolate `_formatted` — those phases
  // don't tick. `running`'s label is intentionally static (no countdown
  // baked in): `_formatted` changes every second, and if it were embedded
  // here the liveRegion label would change every tick and re-announce every
  // second (the exact spam this design avoids). The ticking countdown is
  // already excluded from semantics via ExcludeSemantics below.
  String _phaseAnnouncement(BuildContext context) {
    final strings = GenUiLocalizations.of(context);
    return switch (_phase) {
      _TimerPhase.idle => strings.text(
        GenUiStringKey.timerReady,
        'Timer ready, {time}',
        replacements: {'time': _formatted},
      ),
      _TimerPhase.running => strings.text(
        GenUiStringKey.timerStarted,
        'Timer started',
      ),
      _TimerPhase.paused => strings.text(
        GenUiStringKey.timerPaused,
        'Timer paused at {time}',
        replacements: {'time': _formatted},
      ),
      _TimerPhase.done => strings.text(
        GenUiStringKey.timerComplete,
        'Timer complete',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final strings = GenUiLocalizations.of(context);
    return GenUi.frame(
      context,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.spec['label'] != null)
                  Text(
                    '${widget.spec['label']}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                Semantics(
                  liveRegion: true,
                  label: _phaseAnnouncement(context),
                  child: ExcludeSemantics(
                    child: Text(
                      _formatted,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: _remaining == 0
                            ? colors.celadon
                            : colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GenUi.pill(
            context,
            _timer != null
                ? strings.text(GenUiStringKey.pause, 'Pause')
                : (_remaining == 0
                      ? strings.text(GenUiStringKey.restart, 'Restart')
                      : strings.text(GenUiStringKey.start, 'Start')),
            _toggle,
            filled: true,
            icon: _timer != null
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            semanticLabel: _timer != null
                ? strings.text(GenUiStringKey.pauseTimer, 'Pause timer')
                : strings.text(GenUiStringKey.startTimer, 'Start timer'),
          ),
        ],
      ),
    );
  }
}
