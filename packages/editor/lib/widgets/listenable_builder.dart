// Mostly copied from Flutter's value_listenable_builder.dart

import 'package:flutter/widgets.dart';

/// Builds a [Widget] when given a concrete value of a [Listenable].
///
/// If the `child` parameter provided to the [ListenableBuilder] is not null,
/// the same `child` widget is passed back to this [ListenableWidgetBuilder] and
/// should typically be incorporated in the returned widget tree.
///
/// See also:
///
///  * [ListenableBuilder], a widget which invokes this builder each time a
///    [Listenable] changes value.
typedef ListenableWidgetBuilder<T> = Widget Function(
    BuildContext context, T value, Widget child);

class ListenableBuilder<T extends Listenable> extends StatefulWidget {
  const ListenableBuilder({
    @required this.listenable,
    @required this.builder,
    Key key,
    this.child,
  })  : assert(listenable != null),
        assert(builder != null),
        super(key: key);

  /// The [Listenable] who you depend on in order to build.
  ///
  /// This [Listenable] itself must not be null.
  final T listenable;

  /// A [WidgetBuilder] which builds a widget depending on the
  /// [listenable]'s value.
  ///
  /// Can incorporate a [listenable] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  final ListenableWidgetBuilder<T> builder;

  /// A [listenable]-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree the
  /// [builder] builds depends on the value of the [listenable].
  final Widget child;

  @override
  State<StatefulWidget> createState() => _ListenableBuilderState<T>();
}

class _ListenableBuilderState<T extends Listenable>
    extends State<ListenableBuilder<T>> {
  T value;

  @override
  void initState() {
    super.initState();
    value = widget.listenable;
    widget.listenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ListenableBuilder<T> oldWidget) {
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_valueChanged);
      value = widget.listenable;
      widget.listenable.addListener(_valueChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    setState(() {
      value = widget.listenable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}
