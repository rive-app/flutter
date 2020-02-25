import 'package:flutter/material.dart';

class ComboBox<T> extends StatelessWidget {
  final T value;
  final List<T> options;

  const ComboBox({
    Key key,
    this.value,
    this.options,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(value.toString());
  }
}
