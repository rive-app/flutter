import 'dart:async';

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

/// Wrapper around StreamBuilder that debounces values coming through
/// the stream by the given duration
class ValueStreamDebounceBuilder<T> extends StatefulWidget {
  const ValueStreamDebounceBuilder({
    @required this.stream,
    @required this.builder,
    @required this.duration,
    Key key,
  })  : assert(duration != null),
        super(key: key);

  final Duration duration;
  final ValueStream<T> stream;
  final AsyncWidgetBuilder<T> builder;

  @override
  _ValueStreamDebounceBuilderState<T> createState() =>
      _ValueStreamDebounceBuilderState<T>();
}

class _ValueStreamDebounceBuilderState<T>
    extends State<ValueStreamDebounceBuilder<T>> {
  Timer _debouncer;
  T value;
  BehaviorSubject<T> _controller;

  @override
  void initState() {
    super.initState();
    _controller = BehaviorSubject<T>();
    widget.stream.listen((v) {
      value = v;
      _debouncer ??= Timer(widget.duration, () {
        _controller.add(value);
        _debouncer = null;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _debouncer?.cancel();
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: _controller.stream,
      initialData: widget.stream.value,
      builder: widget.builder,
    );
  }
}
