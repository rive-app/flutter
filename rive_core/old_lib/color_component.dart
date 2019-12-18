import 'dart:typed_data';
import 'dart:ui';

import 'component.dart';
import 'src/metadata.dart';

part 'color_component.g.dart';

/// abstract type that different components can implement
@CoreType(ComponentBase)
abstract class ColorComponentBase extends Component {
  @CoreProperty()
  int _colorValue;

  @CoreProperty()
  Float32List _myArray;
  Color get color => Color(_colorValue);
  set color(Color value) => colorValue = value.value;
  int get colorValue;

  set colorValue(int value);
}
