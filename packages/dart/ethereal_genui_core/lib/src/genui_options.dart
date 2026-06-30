/// A normalized choice/option. The model may emit a plain string (`"Daily"`) OR
/// an object (`{"label":"Daily","value":"daily"}`, `{"label":"x","checked":true,
/// "send":"y"}`). Renderers must never show the raw map — always read [label]
/// for display and [value] for the action.
class GenUiOption {
  const GenUiOption({required this.label, required this.value, this.checked = false});
  final String label;
  final String value;
  final bool checked;
}

/// Normalize a model-supplied list of options/items into [GenUiOption]s,
/// tolerating both string and object forms.
List<GenUiOption> genUiOptions(dynamic raw) {
  final list = raw is List ? raw : const [];
  final out = <GenUiOption>[];
  for (final e in list) {
    if (e is Map) {
      final label =
          (e['label'] ?? e['text'] ?? e['title'] ?? e['name'] ?? e['value'] ?? '')
              .toString();
      final value = (e['value'] ?? e['send'] ?? e['label'] ?? label).toString();
      out.add(GenUiOption(label: label, value: value, checked: e['checked'] == true));
    } else {
      final s = e.toString();
      out.add(GenUiOption(label: s, value: s));
    }
  }
  return out;
}
