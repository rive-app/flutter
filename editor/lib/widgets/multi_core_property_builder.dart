import 'package:core/core.dart';

import 'package:flutter/material.dart';

class MultiCorePropertyBuilder<T> extends StatefulWidget {
  final List<Core> objects;

  final int propertyKey;
  final ValueWidgetBuilder<T> builder;

  final Widget child;

  const MultiCorePropertyBuilder({
    @required this.objects,
    @required this.propertyKey,
    @required this.builder,
    this.child,
    Key key,
  })  : assert(objects != null),
        assert(propertyKey != null),
        assert(builder != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() => _MultiCorePropertyBuilderState<T>();
}

class _MultiCorePropertyBuilderState<T>
    extends State<MultiCorePropertyBuilder<T>> {
  T previous;
  T value;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }

  @override
  void didUpdateWidget(MultiCorePropertyBuilder<T> oldWidget) {
    if (oldWidget.propertyKey != widget.propertyKey ||
        !listEquals(oldWidget.objects, widget.objects)) {
      _unbindListener(oldWidget.objects);

      _bindListener();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _unbindListener(List<Core> objects) {
    var propertyKey = widget.propertyKey;
    for (final object in objects) {
      object.removeListener(propertyKey, _valueChanged);
    }
  }

  void _bindListener() {
    var propertyKey = widget.propertyKey;
    for (final object in widget.objects) {
      object.addListener(propertyKey, _valueChanged);
    }

    value = validateValue(widget.objects);
  }

  T validateValue(List<Core> objects) {
    if (objects.isEmpty) {
      return null;
    }
    var propertyKey = widget.propertyKey;
    var value = objects.first.getProperty<T>(propertyKey);

    for (int i = 1; i < widget.objects.length; i++) {
      if (value != widget.objects[i].getProperty<T>(propertyKey)) {
        return null;
      }
    }
    return value;
  }

  @override
  void dispose() {
    _unbindListener(widget.objects);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bindListener();
  }

  void _valueChanged(dynamic from, dynamic to) {
    setState(() {
      value = validateValue(widget.objects);
    });
  }
}
