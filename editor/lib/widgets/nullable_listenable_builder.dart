import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Convenience ValueListeneableBuilder for use when valueListenable can be
/// null.
class NullableListenableBuilder<T> extends StatelessWidget {
  final ValueListenable<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final Widget child;

  const NullableListenableBuilder({
    Key key,
    @required this.valueListenable,
    @required this.builder,
    this.child,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return valueListenable == null
        ? builder(context, null, child)
        : ValueListenableBuilder<T>(
            valueListenable: valueListenable, builder: builder, child: child);
  }
}
