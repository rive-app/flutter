import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreDoubleType extends CoreFieldType<double> {
  @override
  double deserialize(BinaryReader reader) => reader.buffer.lengthInBytes == 4
      ? reader.readFloat32()
      : reader.readFloat64();

  @override
  double lerp(double from, double to, double f) => from + (to - from) * f;

  @override
  Uint8List serialize(double value) {
    var check = Float32List(1);
    check[0] = value;
    BinaryWriter writer;
    if (check[0] == value) {
      // 32 bits is sufficient
      writer = BinaryWriter(alignment: 4);
      writer.writeFloat32(value);
    } else {
      writer = BinaryWriter(alignment: 8);
      writer.writeFloat64(value);
    }
    return writer.uint8Buffer;
  }
}
