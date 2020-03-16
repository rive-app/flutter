import 'package:core/core.dart';

import 'package:flutter/material.dart';

/// Stateful widget that manages a list of [Core] elements.
///
/// The list of elements will register listeners for the property with value
/// [propertyKey], and it'll have a [builder] function which, upon change of
/// the State value, will be rebuilt.
class CorePropertiesBuilder<T, K extends Core> extends StatefulWidget {
  final Iterable<K> objects;

  final int propertyKey;
  final ValueWidgetBuilder<T> builder;

  final Widget child;

  const CorePropertiesBuilder({
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
  State<StatefulWidget> createState() => _CorePropertiesBuilderState<T, K>();
}

class _CorePropertiesBuilderState<T, K extends Core>
    extends State<CorePropertiesBuilder<T, K>> {
  T previous;
  T value;

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }

  @override
  void didUpdateWidget(CorePropertiesBuilder<T, K> oldWidget) {
    if (oldWidget.propertyKey != widget.propertyKey ||
        !iterableEquals(oldWidget.objects, widget.objects)) {
      _unbindListener(oldWidget.objects);

      _bindListener();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _unbindListener(Iterable<K> objects) {
    var propertyKey = widget.propertyKey;
    for (final object in objects) {
      object.removeListener(propertyKey, _valueChanged);
    }
  }

  /// Bind the [_valueChanged] function to each of the objects that are part
  /// of this CorePropertiesBuilder. Then extract the value by validating
  /// it.
  void _bindListener() {
    var propertyKey = widget.propertyKey;
    for (final object in widget.objects) {
      object.addListener(propertyKey, _valueChanged);
    }

    value = _validateValue();
  }

  /// Validates the values by this list of objects.
  /// Either all the values coincide, or we return [null].
  T _validateValue() {
    var objects = widget.objects;
    if (objects.isEmpty) {
      return null;
    }
    var propertyKey = widget.propertyKey;
    var value = objects.first.getProperty<T>(propertyKey);

    for (final object in objects.skip(1)) {
      if (value != object.getProperty<T>(propertyKey)) {
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
      value = _validateValue();
    });
  }
}
