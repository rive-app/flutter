import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Copy of ValueListenableBuilder with frozen property.
class FrozenValueListenableBuilder<T> extends StatefulWidget {
  /// Prevents the widget from updating when this is set to true.
  final bool frozen;

  /// Creates a [FrozenValueListenableBuilder].
  ///
  /// The [valueListenable] and [builder] arguments must not be null.
  /// The [child] is optional but is good practice to use if part of the widget
  /// subtree does not depend on the value of the [valueListenable].
  const FrozenValueListenableBuilder({
    @required this.valueListenable,
    @required this.builder,
    Key key,
    this.child,
    this.frozen = false,
  })  : assert(valueListenable != null),
        assert(builder != null),
        super(key: key);

  /// The [ValueListenable] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [ValueListenable]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  ///
  /// This [ValueListenable] itself must not be null.
  final ValueListenable<T> valueListenable;

  /// A [ValueWidgetBuilder] which builds a widget depending on the
  /// [valueListenable]'s value.
  ///
  /// Can incorporate a [valueListenable] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  ///
  /// Must not be null.
  final ValueWidgetBuilder<T> builder;

  /// A [valueListenable]-independent widget which is passed back to the
  /// [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree the
  /// [builder] builds depends on the value of the [valueListenable]. For
  /// example, if the [valueListenable] is a [String] and the [builder] simply
  /// returns a [Text] widget with the [String] value.
  final Widget child;

  @override
  State<StatefulWidget> createState() =>
      _FrozenValueListenableBuilderState<T>();
}

class _FrozenValueListenableBuilderState<T>
    extends State<FrozenValueListenableBuilder<T>> {
  T value;

  @override
  void initState() {
    super.initState();
    value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(FrozenValueListenableBuilder<T> oldWidget) {
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
    }
    if (widget.frozen != oldWidget.frozen) {
      _valueChanged();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    if (widget.frozen) {
      return;
    }
    setState(() {
      value = widget.valueListenable.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}
