import 'dart:collection';
import 'package:rive/rive_core/animation/animation.dart';

// TODO: figure out how to make this cleaner.
class AnimationList extends ListBase<Animation> {
  final List<Animation> _values = [];
  List<Animation> get values => _values;

  @override
  int get length => _values.length;

  @override
  set length(int value) => _values.length = value;

  @override
  Animation operator [](int index) => _values[index];

  @override
  void operator []=(int index, Animation value) => _values[index] = value;
}
