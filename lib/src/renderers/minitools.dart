import 'dart:async';

import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_common.dart';

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
            alignment: Alignment.centerRight,
            decoration: ShapeDecoration(
              color: colors.surface.withValues(alpha: 0.6),
              shape: GenUiShape.shape(GenUiRadii.md),
            ),
            child: Text(_display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          const SizedBox(height: GenUiSpace.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: GenUiSpace.sm),
              child: Row(
                children: [
                  for (final key in row) ...[
                    Expanded(flex: key == '0' ? 1 : 1, child: _key(context, key, colors)),
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
        height: 46,
        alignment: Alignment.center,
        decoration: ShapeDecoration(color: bg, shape: GenUiShape.shape(GenUiRadii.md)),
        child: Text(key,
            style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w600)),
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

  late final List<String> _labels;
  late final List<double> _factors;

  @override
  void initState() {
    super.initState();
    final units = (widget.spec['units'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    if (units.length >= 2) {
      _labels = units.map((u) => (u['label'] ?? '').toString()).toList();
      _factors = units
          .map((u) => (u['factor'] is num) ? (u['factor'] as num).toDouble() : 1.0)
          .toList();
    } else {
      _labels = ['m', 'km', 'mi', 'ft'];
      _factors = [1, 1000, 1609.344, 0.3048];
    }
    _to = _labels.length > 1 ? 1 : 0;
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
          GenUi.title(context, widget.spec['title'] as String?),
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
              _unitMenu(colors, _from, (v) => setState(() => _from = v)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: GenUiSpace.sm),
            child: Icon(Icons.swap_vert_rounded),
          ),
          Row(
            children: [
              Expanded(
                child: Text(resultStr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.accent)),
              ),
              const SizedBox(width: GenUiSpace.sm),
              _unitMenu(colors, _to, (v) => setState(() => _to = v)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unitMenu(GenUiColors colors, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GenUiSpace.sm),
      decoration: ShapeDecoration(
        color: colors.accent.withValues(alpha: 0.14),
        shape: GenUiShape.shape(GenUiRadii.sm),
      ),
      child: DropdownButton<int>(
        value: value,
        underline: const SizedBox.shrink(),
        dropdownColor: colors.surfaceRaised,
        style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600),
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

class _TimerRendererState extends State<TimerRenderer> {
  late int _total;
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _total = (widget.spec['seconds'] is num)
        ? (widget.spec['seconds'] as num).toInt()
        : 60;
    _remaining = _total;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    setState(() {
      if (_remaining == 0) _remaining = _total;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remaining <= 1) {
          t.cancel();
          setState(() {
            _remaining = 0;
            _timer = null;
          });
        } else {
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

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    return GenUi.frame(
      context,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.spec['label'] != null)
                  Text('${widget.spec['label']}',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.textTertiary)),
                Text(_formatted,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: _remaining == 0 ? colors.celadon : colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
          ),
          GenUi.pill(
            context,
            _timer != null ? 'Pause' : (_remaining == 0 ? 'Restart' : 'Start'),
            _toggle,
            filled: true,
            icon: _timer != null ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
        ],
      ),
    );
  }
}
