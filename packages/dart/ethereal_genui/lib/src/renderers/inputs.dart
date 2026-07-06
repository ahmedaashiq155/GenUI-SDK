import 'package:flutter/material.dart';

import '../genui_theme.dart';
import '../genui_actions.dart';
import '../genui_common.dart';
import '../genui_state.dart';

/// {"type":"input","label":"…","placeholder":"…","submitLabel":"Send"}
class InputRenderer extends StatefulWidget {
  const InputRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<InputRenderer> createState() => _InputRendererState();
}

class _InputRendererState extends State<InputRenderer>
    with GenUiPersistedState<InputRenderer> {
  final _controller = TextEditingController();

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is String) _controller.text = stored;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitLabel = (widget.spec['submitLabel'] ?? 'Send').toString();
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, (widget.spec['label'] ?? widget.spec['title'])?.toString()),
          TextField(
            controller: _controller,
            enabled: widget.actions.enabled,
            minLines: 1,
            maxLines: 4,
            onChanged: (v) {
              setState(() {});
              persist(v);
            },
            decoration: InputDecoration(
              hintText: (widget.spec['placeholder'] ?? 'Type your answer').toString(),
            ),
          ),
          const SizedBox(height: GenUiSpace.md),
          GenUi.submitButton(
            context,
            submitLabel,
            widget.actions.enabled && _controller.text.trim().isNotEmpty
                ? () => widget.actions.sendMessage(_controller.text.trim())
                : null,
          ),
        ],
      ),
    );
  }
}

/// {"type":"multiselect","title":"…","options":["A","B"],"submitLabel":"Submit"}
class MultiSelectRenderer extends StatefulWidget {
  const MultiSelectRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<MultiSelectRenderer> createState() => _MultiSelectRendererState();
}

class _MultiSelectRendererState extends State<MultiSelectRenderer>
    with GenUiPersistedState<MultiSelectRenderer> {
  final _selected = <String>{};

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is List) {
      _selected
        ..clear()
        ..addAll(stored.map((e) => e.toString()));
    }
  }

  void _toggle(String o) {
    setState(() =>
        _selected.contains(o) ? _selected.remove(o) : _selected.add(o));
    persist(_selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final options = genUiOptions(widget.spec['options']);
    final submitLabel = (widget.spec['submitLabel'] ?? 'Submit').toString();
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, widget.spec['title']?.toString()),
          Wrap(
            spacing: GenUiSpace.sm,
            runSpacing: GenUiSpace.sm,
            children: [
              for (final o in options)
                GenUi.pill(
                  context,
                  o.label,
                  widget.actions.enabled ? () => _toggle(o.value) : null,
                  selected: _selected.contains(o.value),
                  icon: _selected.contains(o.value) ? Icons.check_rounded : null,
                ),
            ],
          ),
          const SizedBox(height: GenUiSpace.md),
          GenUi.submitButton(
            context,
            submitLabel,
            widget.actions.enabled && _selected.isNotEmpty
                ? () => widget.actions.sendMessage(_selected.join(', '))
                : null,
          ),
        ],
      ),
    );
  }
}

/// {"type":"slider","label":"…","min":0,"max":100,"step":1,"value":50,"unit":"%"}
class SliderRenderer extends StatefulWidget {
  const SliderRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<SliderRenderer> createState() => _SliderRendererState();
}

class _SliderRendererState extends State<SliderRenderer>
    with GenUiPersistedState<SliderRenderer> {
  late double _value;

  double _num(dynamic v, double fallback) =>
      (v is num) ? v.toDouble() : double.tryParse('$v') ?? fallback;

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is num) _value = stored.toDouble();
  }

  @override
  void initState() {
    super.initState();
    _value = _num(widget.spec['value'], _num(widget.spec['min'], 0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    final rawMin = _num(widget.spec['min'], 0);
    final rawMax = _num(widget.spec['max'], 100);
    // The model may emit min > max (e.g. a reversed "hot→cold" range).
    // `num.clamp` throws if lower > upper (in all build modes), so normalize;
    // if they collapse to a single point, widen by 1 so Slider stays valid.
    var min = rawMin < rawMax ? rawMin : rawMax;
    var max = rawMin < rawMax ? rawMax : rawMin;
    if (min == max) max = min + 1;
    final step = _num(widget.spec['step'], 1);
    // divisions must be null or >= 1; a large step vs range rounds to 0.
    final rawDivisions = step > 0 ? ((max - min) / step).round() : 0;
    final divisions = rawDivisions >= 1 ? rawDivisions : null;
    final unit = (widget.spec['unit'] ?? '').toString();
    final display = (_value == _value.roundToDouble())
        ? _value.toInt().toString()
        : _value.toStringAsFixed(1);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: GenUi.title(context, (widget.spec['label'] ?? widget.spec['title'])?.toString())),
              Text('$display$unit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.accent)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accent,
              inactiveTrackColor: colors.accent.withValues(alpha: 0.18),
              thumbColor: colors.accent,
              overlayColor: colors.accentGlow,
            ),
            child: Slider(
              value: _value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: widget.actions.enabled
                  ? (v) {
                      setState(() => _value = v);
                      persist(v);
                    }
                  : null,
            ),
          ),
          GenUi.submitButton(
            context,
            (widget.spec['submitLabel'] ?? 'Submit').toString(),
            widget.actions.enabled
                ? () => widget.actions.sendMessage('$display$unit')
                : null,
          ),
        ],
      ),
    );
  }
}

/// {"type":"form","title":"…","fields":[{"key","label","type":"text|number|select|toggle","options":[]}],"submitLabel":"Submit"}
class FormRenderer extends StatefulWidget {
  const FormRenderer({super.key, required this.spec, required this.actions});
  final Map<String, dynamic> spec;
  final GenUiActions actions;

  @override
  State<FormRenderer> createState() => _FormRendererState();
}

class _FormRendererState extends State<FormRenderer>
    with GenUiPersistedState<FormRenderer> {
  final _values = <String, dynamic>{};
  final _controllers = <String, TextEditingController>{};

  @override
  String? get persistId => widget.spec['id']?.toString();

  @override
  void restorePersisted(Object? stored) {
    if (stored is Map) {
      _values.addAll(stored.map((k, v) => MapEntry(k.toString(), v)));
    }
  }

  List<Map<String, dynamic>> get _fields =>
      (widget.spec['fields'] is List ? widget.spec['fields'] as List<dynamic> : const [])
          .whereType<Map<String, dynamic>>()
          .toList();

  // Text/number fields seed their controller from any restored value.
  TextEditingController _controllerFor(String key) =>
      _controllers.putIfAbsent(key, () {
        final c = TextEditingController();
        final v = _values[key];
        if (v != null) c.text = v.toString();
        return c;
      });

  void _set(String key, dynamic value) {
    setState(() => _values[key] = value);
    persist({..._values});
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GenUiColors.of(context);
    return GenUi.frame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GenUi.title(context, widget.spec['title']?.toString()),
          for (final f in _fields) ...[
            _field(context, f, colors),
            const SizedBox(height: GenUiSpace.md),
          ],
          GenUi.submitButton(
            context,
            (widget.spec['submitLabel'] ?? 'Submit').toString(),
            widget.actions.enabled ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, Map<String, dynamic> f, GenUiColors colors) {
    final key = (f['key'] ?? f['label'] ?? '').toString();
    final label = (f['label'] ?? key).toString();
    final type = (f['type'] ?? 'text').toString();

    switch (type) {
      case 'toggle':
        final value = _values[key] is bool ? _values[key] as bool : (f['value'] == true);
        return Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            Switch(
              value: value,
              activeThumbColor: colors.accent,
              onChanged: widget.actions.enabled ? (v) => _set(key, v) : null,
            ),
          ],
        );
      case 'select':
        final options = genUiOptions(f['options']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: GenUiSpace.xs),
            Wrap(
              spacing: GenUiSpace.sm,
              runSpacing: GenUiSpace.sm,
              children: [
                for (final o in options)
                  GenUi.pill(
                    context,
                    o.label,
                    widget.actions.enabled ? () => _set(key, o.value) : null,
                    selected: _values[key] == o.value,
                  ),
              ],
            ),
          ],
        );
      default: // text | number
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: GenUiSpace.xs),
            TextField(
              controller: _controllerFor(key),
              enabled: widget.actions.enabled,
              keyboardType: type == 'number' ? TextInputType.number : null,
              onChanged: (v) {
                _values[key] = v;
                persist({..._values});
              },
              decoration: InputDecoration(
                hintText: (f['placeholder'] ?? '').toString(),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: GenUiSpace.md, vertical: GenUiSpace.sm + 2),
                border: OutlineInputBorder(borderRadius: GenUiShape.radius(GenUiRadii.sm)),
              ),
            ),
          ],
        );
    }
  }

  void _submit() {
    final lines = <String>[];
    for (final f in _fields) {
      final key = (f['key'] ?? f['label'] ?? '').toString();
      final label = (f['label'] ?? key).toString();
      // `_values` is the single source of truth (text fields write to it via
      // onChanged); fall back to the controller for any unedited text field.
      var value = _values[key];
      if (value == null && _controllers.containsKey(key)) {
        value = _controllers[key]!.text.trim();
      }
      if (value != null && value.toString().trim().isNotEmpty) {
        lines.add('$label: ${value.toString().trim()}');
      }
    }
    widget.actions.sendMessage(lines.join('\n'));
  }
}
