import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

/// Lightweight wrapper around StreamBuilder that automatically wires up the
/// initial data to prevent flickering. Use this when your Stream is a
/// ValueStream.
class ValueStreamBuilder<T> extends StatelessWidget {
  final ValueStream<T> stream;
  final AsyncWidgetBuilder<T> builder;

  const ValueStreamBuilder({
    @required this.stream,
    @required this.builder,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      initialData: stream.value,
      builder: builder,
    );
  }
}
