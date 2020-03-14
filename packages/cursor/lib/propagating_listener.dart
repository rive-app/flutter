import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Thoughts and research about why this was necessary is in this Notion
/// article:
/// https://www.notion.so/Flutter-Hit-Testing-28b9b3ec188d482e92ac6ceccbb3f5e9
///
/// Represents a Propagating event. Currently only tracks whether something
/// lower in the hierarchy has already handled this event but could be extended
/// to provide further event details (like context of what handled it which
/// could be important for other events to still process some part of their
/// operation in response to another event's handling of it).
class PropagatingEvent<T> {
  PropagatingEvent(this.pointerEvent);

  /// Set to true when another handler has processed this event.
  bool _isHandled = false;

  bool get isHandled => _isHandled;

  void stopPropagation() => _isHandled = true;
  T pointerEvent;
}

/// Signature for listening to Propagating [PointerDownEvent] events.
///
/// Used by [PropagatingListener]
typedef PropagatingPointerDownEventListener = void Function(
    PropagatingEvent<PointerDownEvent> event);

/// Signature for listening to [PointerUpEvent] events.
///
/// Used by [PropagatingListener]
typedef PropagatingPointerUpEventListener = void Function(
    PropagatingEvent<PointerUpEvent> event);

/// Signature for listening to [PointerCancelEvent] events.
///
/// Used by [PropagatingListener]
typedef PropagatingPointerCancelEventListener = void Function(
    PropagatingEvent<PointerCancelEvent> event);

/// Signature for listening to [PointerSignalEvent] events.
///
/// Used by [PropagatingListener]
typedef PropagatingPointerSignalEventListener = void Function(
    PropagatingEvent<PointerSignalEvent> event);

/// Signature for listening to [PointerMoveEvent] events.
///
/// Used by [PropagatingListener]
typedef PropagatingPointerMoveEventListener = void Function(
    PropagatingEvent<PointerMoveEvent> event);

/// A [PropagatingListenerRoot] must be placed at the top of the Propagating
/// listener hierarchy in order for Propagating listener to share common data.
/// We need this to be a stateful widget so that it can keep the event data
/// around between rebuilds.
class PropagatingListenerRoot extends StatefulWidget {
  final Widget child;

  const PropagatingListenerRoot({Key key, this.child}) : super(key: key);

  @override
  _PropagatingListenerRootState createState() =>
      _PropagatingListenerRootState();
}

class _PropagatingListenerRootState extends State<PropagatingListenerRoot> {
  final Map<PointerEvent, PropagatingEvent> _events =
      HashMap<PointerEvent, PropagatingEvent>();
  @override
  Widget build(BuildContext context) {
    return _InheritedPropagatingEvents(
      child: widget.child,
      events: _events,
    );
  }
}

/// We use a private inherited widget to pass the inherited event data around
/// the hierarchy. We wrap it in the stateful widget defined above so that the
/// event data persists between rebuilds.
class _InheritedPropagatingEvents extends InheritedWidget {
  _InheritedPropagatingEvents({
    @required Widget child,
    @required this.events,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);
  final Map<PointerEvent, PropagatingEvent> events;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;

  static Map<PointerEvent, PropagatingEvent> of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedPropagatingEvents>()
      .events;
}

/// A listener that'll only continue propagating the event if some other
/// Propagating listener doesn't hanlde it.
class PropagatingListener extends StatelessWidget {
  final Widget child;
  final HitTestBehavior behavior;
  final PropagatingPointerDownEventListener onPointerDown;
  final PropagatingPointerUpEventListener onPointerUp;
  final PropagatingPointerMoveEventListener onPointerMove;
  final PropagatingPointerCancelEventListener onPointerCancel;
  final PropagatingPointerSignalEventListener onPointerSignal;

  const PropagatingListener({
    Key key,
    this.child,
    this.behavior,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerMove,
    this.onPointerCancel,
    this.onPointerSignal,
  }) : super(key: key);

  PropagatingEvent<T> _prepEvent<T extends PointerEvent>(
      Map<PointerEvent, PropagatingEvent> events, T pointerEvent) {
    var original = pointerEvent.original ?? pointerEvent;
    PropagatingEvent<T> event = events[original] as PropagatingEvent<T>;
    if (event == null) {
      events[original] = event = PropagatingEvent<T>(pointerEvent);
      // Clear the event on the next frame. There should be a better way to
      // hanlde this, but for now this works.
      Future<void>.delayed(const Duration(microseconds: 1)).then((_) {
        events[original] = null;
      });
    }
    return event;
  }

  @override
  Widget build(BuildContext context) {
    var events = _InheritedPropagatingEvents.of(context);
    return Listener(
      behavior: behavior,
      onPointerDown: (details) {
        var event = _prepEvent(events, details);
        if (!event.isHandled) {
          onPointerDown?.call(event);
        }
      },
      onPointerMove: (details) {
        var event = _prepEvent(events, details);
        if (!event.isHandled) {
          onPointerMove?.call(event);
        }
      },
      onPointerUp: (details) {
        var event = _prepEvent(events, details);
        if (!event.isHandled) {
          onPointerUp?.call(event);
        }
      },
      onPointerCancel: (details) {
        var event = _prepEvent(events, details);
        if (!event.isHandled) {
          onPointerCancel?.call(event);
        }
      },
      onPointerSignal: (details) {
        var event = _prepEvent(events, details);
        if (!event.isHandled) {
          onPointerSignal?.call(event);
        }
      },
      child: child,
    );
  }
}
