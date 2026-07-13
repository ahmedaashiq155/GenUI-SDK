import 'dart:convert';

import 'package:flutter/material.dart';

enum GenUiDebugEventType { render, dispatch, validation, error, patch, input }

@immutable
class GenUiDebugEvent {
  const GenUiDebugEvent({
    required this.type,
    required this.timestamp,
    this.blockType,
    this.message,
    this.data = const <String, Object?>{},
  });

  final GenUiDebugEventType type;
  final DateTime timestamp;
  final String? blockType;
  final String? message;
  final Map<String, Object?> data;

  Map<String, Object?> toJson() => {
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    if (blockType != null) 'blockType': blockType,
    if (message != null) 'message': message,
    if (data.isNotEmpty) 'data': data,
  };
}

/// Observable, bounded event recorder used by the in-app DevTools overlay.
/// Specs/messages are omitted by default to avoid leaking sensitive content.
class GenUiDebugController extends ChangeNotifier {
  GenUiDebugController({this.capacity = 250, this.capturePayloads = false});

  final int capacity;
  final bool capturePayloads;
  final List<GenUiDebugEvent> _events = [];

  List<GenUiDebugEvent> get events => List.unmodifiable(_events);

  void record(
    GenUiDebugEventType type, {
    String? blockType,
    String? message,
    Map<String, Object?> data = const <String, Object?>{},
  }) {
    if (capacity <= 0) return;
    _events.add(
      GenUiDebugEvent(
        type: type,
        timestamp: DateTime.now().toUtc(),
        blockType: blockType,
        message: capturePayloads ? message : null,
        data: capturePayloads ? data : const <String, Object?>{},
      ),
    );
    final overflow = _events.length - capacity;
    if (overflow > 0) _events.removeRange(0, overflow);
    notifyListeners();
  }

  void clear() {
    _events.clear();
    notifyListeners();
  }

  String exportJson() =>
      jsonEncode(events.map((event) => event.toJson()).toList());
}

class GenUiDebugScope extends InheritedWidget {
  const GenUiDebugScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final GenUiDebugController controller;

  static GenUiDebugController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GenUiDebugScope>()?.controller;

  @override
  bool updateShouldNotify(GenUiDebugScope oldWidget) =>
      controller != oldWidget.controller;
}

/// An opt-in in-app inspector for development builds and profile captures.
class GenUiDevToolsOverlay extends StatefulWidget {
  const GenUiDevToolsOverlay({
    super.key,
    required this.controller,
    required this.child,
    this.initiallyOpen = false,
  });

  final GenUiDebugController controller;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<GenUiDevToolsOverlay> createState() => _GenUiDevToolsOverlayState();
}

class _GenUiDevToolsOverlayState extends State<GenUiDevToolsOverlay> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) => GenUiDebugScope(
    controller: widget.controller,
    child: Stack(
      textDirection: Directionality.of(context),
      children: [
        widget.child,
        PositionedDirectional(
          end: 12,
          bottom: 12,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_open)
                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: 340,
                      height: 360,
                      child: AnimatedBuilder(
                        animation: widget.controller,
                        builder: (context, _) {
                          final events = widget.controller.events.reversed
                              .toList();
                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                title: const Text('GenUI Inspector'),
                                trailing: IconButton(
                                  tooltip: 'Clear events',
                                  onPressed: widget.controller.clear,
                                  icon: const Icon(Icons.delete_sweep_outlined),
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: events.length,
                                  itemBuilder: (context, index) {
                                    final event = events[index];
                                    return ListTile(
                                      dense: true,
                                      leading: Text(event.type.name),
                                      title: Text(
                                        event.blockType ??
                                            event.message ??
                                            'GenUI',
                                      ),
                                      subtitle: Text(
                                        event.timestamp.toIso8601String(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  tooltip: _open
                      ? 'Close GenUI Inspector'
                      : 'Open GenUI Inspector',
                  onPressed: () => setState(() => _open = !_open),
                  child: Icon(_open ? Icons.close : Icons.developer_mode),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
