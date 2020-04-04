import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_widgets/listenable_builder.dart';

/// Convenience ValueListeneableBuilder for use when valueListenable can be
/// null.
class NullableValueListenableBuilder<T> extends StatelessWidget {
  final ValueListenable<T> valueListenable;
  final ValueWidgetBuilder<T> builder;
  final Widget child;

  const NullableValueListenableBuilder({
    @required this.valueListenable,
    @required this.builder,
    Key key,
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

/// Convenience ListeneableBuilder for use when Listenable can be null.
class NullableListenableBuilder<T extends Listenable> extends StatelessWidget {
  final T listenable;
  final ValueWidgetBuilder<T> builder;
  final Widget child;

  const NullableListenableBuilder({
    @required this.listenable,
    @required this.builder,
    Key key,
    this.child,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return listenable == null
        ? builder(context, null, child)
        : ListenableBuilder<T>(
            listenable: listenable, builder: builder, child: child);
  }
}
