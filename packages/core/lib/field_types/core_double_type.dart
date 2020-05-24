import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreDoubleType extends CoreFieldType<double> {
  @override
  double deserialize(BinaryReader reader) => reader.readFloat64();

  @override
  double lerp(double from, double to, double f) => from + (to - from) * f;

  @override
  Uint8List serialize(double value) {
    var writer = BinaryWriter(alignment: 8);
    write(writer, value);
    return writer.uint8Buffer;
  }

  @override
  void write(BinaryWriter writer, double value) {
    writer.writeFloat64(value);
  }
}
