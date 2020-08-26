import 'package:core/core.dart';

import 'package:flutter/material.dart';
import 'package:rive_editor/frame_debounce.dart';
import 'package:utilities/list_equality.dart';

class PropertiesBuilder<T, K> extends StatefulWidget {
  final Iterable<K> objects;

  final T Function(K) getValue;
  final ValueWidgetBuilder<T> builder;
  final void Function(K, bool, void Function(dynamic, dynamic)) listen;

  /// It's possible that we only want to use certain objects in our list, use
  /// this filter to filter them.
  final bool Function(K) filter;
  final Widget child;
  final bool frozen;

  const PropertiesBuilder({
    @required this.objects,
    @required this.getValue,
    @required this.builder,
    @required this.listen,
    this.filter,
    this.child,
    this.frozen = false,
    Key key,
  })  : assert(objects != null),
        assert(getValue != null),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _PropertiesBuilderState<T, K>();
}

class _PropertiesBuilderState<T, K> extends State<PropertiesBuilder<T, K>> {
  T previous;
  T value;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }

  @override
  void didUpdateWidget(PropertiesBuilder<T, K> oldWidget) {
    if (!iterableEquals(oldWidget.objects, widget.objects)) {
      _unbindListener(oldWidget.objects);

      _bindListener();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _unbindListener(Iterable<K> objects) {
    cancelFrameDebounce(_rebuild);
    for (final object in objects) {
      widget.listen(object, false, _valueChanged);
    }
  }

  /// Bind the [_valueChanged] function to each of the objects that are part
  /// of this PropertiesBuilder. Then extract the value by validating
  /// it.
  void _bindListener() {
    for (final object in widget.objects) {
      widget.listen(object, true, _valueChanged);
    }

    value = _validateValue();
  }

  /// Validates the values by this list of objects.
  /// Either all the values coincide, or we return [null].
  T _validateValue() {
    var objects = widget.filter != null
        ? widget.objects.where(widget.filter)
        : widget.objects;
    ;
    if (objects.isEmpty) {
      return null;
    }
    var value = widget.getValue(objects.first);

    for (final object in objects.skip(1)) {
      if (value != widget.getValue(object)) {
        return null;
      }
    }
    return value;
  }

  @override
  void dispose() {
    _unbindListener(
      widget.objects,
    );
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bindListener();
  }

  void _rebuild() {
    if (!mounted || widget.frozen) {
      return;
    }
    (context as StatefulElement).markNeedsBuild();
  }

  void _valueChanged(dynamic from, dynamic to) {
    value = _validateValue();
    frameDebounce(_rebuild);
  }
}
