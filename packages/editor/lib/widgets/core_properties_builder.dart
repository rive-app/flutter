import 'package:core/core.dart';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/properties_builder.dart';

/// Stateful widget that manages a list of [Core] elements.
///
/// The list of elements will register listeners for the property with value
/// [propertyKey], and it'll have a [builder] function which, upon change of
/// the State value, will be rebuilt.
class CorePropertiesBuilder<T, K extends Core> extends StatelessWidget {
  final Iterable<K> objects;

  final int propertyKey;
  final ValueWidgetBuilder<T> builder;
  final Widget child;
  final bool frozen;

  const CorePropertiesBuilder({
    @required this.objects,
    @required this.propertyKey,
    @required this.builder,
    this.child,
    this.frozen = false,
    Key key,
  })  : assert(objects != null),
        assert(propertyKey != null),
        assert(builder != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertiesBuilder<T, K>(
      objects: objects,
      builder: builder,
      getValue: (object) => object.getProperty<T>(propertyKey),
      listenCore: (object, enable, callback) {
        var eventDelegate = object.eventDelegateFor(propertyKey);
        if (enable) {
          eventDelegate.addListener(propertyKey, callback);
        } else {
          eventDelegate.removeListener(propertyKey, callback);
        }
      },
      child: child,
      frozen: frozen,
    );
  }
}
