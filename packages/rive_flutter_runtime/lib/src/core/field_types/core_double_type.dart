import 'package:rive/src/core/field_types/core_field_type.dart';
import 'package:rive/src/utilities/binary_buffer/binary_reader.dart';

class CoreDoubleType extends CoreFieldType<double> {
  @override
  double deserialize(BinaryReader reader) => reader.readFloat64();

  @override
  double lerp(double from, double to, double f) => from + (to - from) * f;
}
