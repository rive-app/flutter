import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/frame_debounce.dart';

/// TODO: determine if we can commit murder
class CorePropertyBuilder<T> extends StatefulWidget {
  final Core object;

  final int propertyKey;
  final ValueWidgetBuilder<T> builder;

  final Widget child;
  final bool frozen;

  const CorePropertyBuilder({
    @required this.object,
    @required this.propertyKey,
    @required this.builder,
    this.frozen = false,
    this.child,
    Key key,
  })  : assert(object != null),
        assert(propertyKey != null),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _CorePropertyBuilderState<T>();
}

class _CorePropertyBuilderState<T> extends State<CorePropertyBuilder<T>> {
  T previous;
  T value;

  Core<CoreContext> _eventDelegate;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }

  @override
  void didUpdateWidget(CorePropertyBuilder<T> oldWidget) {
    if (oldWidget.object != widget.object ||
        oldWidget.propertyKey != widget.propertyKey) {
      oldWidget.object.removeListener(oldWidget.propertyKey, _valueChanged);

      _bindListener();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _bindListener() {
    var object = widget.object;
    var propertyKey = widget.propertyKey;

    var currentPropertyValue =
        object.context.getObjectProperty(object, propertyKey);

    assert(currentPropertyValue == null || currentPropertyValue is T,
        'expected $currentPropertyValue to be of type $T');
    value = currentPropertyValue as T;
    _eventDelegate = object.eventDelegateFor(propertyKey);
    _eventDelegate?.addListener(propertyKey, _valueChanged);
  }

  @override
  void dispose() {
    _eventDelegate?.removeListener(widget.propertyKey, _valueChanged);
    cancelFrameDebounce(_rebuild);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bindListener();
  }

  void _rebuild() {
    if (widget.frozen) {
      return;
    }
    (context as StatefulElement).markNeedsBuild();
  }

  void _valueChanged(dynamic from, dynamic to) {
    assert(to == null || to is T);

    // We debounce here to ensure that the update doesn't occur during a build
    // (this can happen if animations/changes get applied in response to some
    // other change that occurs during the build cycle).

    value = to as T;
    frameDebounce(_rebuild);
  }
}
