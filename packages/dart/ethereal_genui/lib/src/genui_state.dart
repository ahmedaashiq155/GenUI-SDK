import 'package:flutter/widgets.dart';

/// Provides durable, id-keyed state to generative-UI renderers. Present when a
/// composition runs as a saved **Live App** (state is persisted), and absent in
/// normal chat (renderers keep ephemeral local state, as before).
///
/// Renderers that carry an `id` read their initial value via [valueFor] and
/// persist changes via [setValue]; when no scope is present these are no-ops.
class GenUiStateScope extends InheritedWidget {
  const GenUiStateScope({
    super.key,
    required this.state,
    required this.onChanged,
    required super.child,
  });

  /// The current per-widget state map (keyed by widget `id`).
  final Map<String, dynamic> state;

  /// Called with the full, updated map whenever a widget writes its state.
  final void Function(Map<String, dynamic> next) onChanged;

  static GenUiStateScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GenUiStateScope>();

  dynamic valueFor(String? id) => id == null ? null : state[id];

  void setValue(String? id, dynamic value) {
    if (id == null) return;
    onChanged({...state, id: value});
  }

  /// Merge a patch of keys into the state at once — used by client-side `set`
  /// actions (e.g. a button that switches the app's view without a round-trip).
  void merge(Map<String, dynamic> patch) {
    if (patch.isEmpty) return;
    onChanged({...state, ...patch});
  }

  @override
  bool updateShouldNotify(GenUiStateScope old) => old.state != state;
}

/// Mixin for a stateful GenUI renderer that persists a single value, keyed by
/// the block's `id`, into the surrounding [GenUiStateScope].
///
/// In a Live App the scope is present, so the widget restores its value on first
/// build and writes changes back (the app keeps its state offline). In normal
/// chat there is no scope, so [restorePersisted] is never called and [persist]
/// is a no-op — i.e. today's ephemeral behaviour, unchanged.
///
/// Implement [persistId] (usually `widget.spec['id']?.toString()`) and
/// [restorePersisted] (apply [stored] to local state), and call [persist] on
/// every change. Any [initState] defaults run first; restore only overrides them
/// when a stored value actually exists.
mixin GenUiPersistedState<T extends StatefulWidget> on State<T> {
  String? get persistId;

  /// Apply a previously-persisted value to local state. Called at most once,
  /// only when a non-null value exists in the scope.
  void restorePersisted(Object? stored);

  bool _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    final stored = GenUiStateScope.maybeOf(context)?.valueFor(persistId);
    if (stored != null) restorePersisted(stored);
  }

  /// Persist [value] under [persistId] (no-op outside a [GenUiStateScope]).
  void persist(Object? value) =>
      GenUiStateScope.maybeOf(context)?.setValue(persistId, value);
}
