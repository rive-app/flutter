import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreDoubleType extends CoreFieldType<double> {
  static bool max32Bit = false;

  @override
  double deserialize(BinaryReader reader) {
    var length = reader.buffer.lengthInBytes;
    if (length < 4) {
      return reader.readVarInt() / 10;
    } else if (length == 4) {
      return reader.readFloat32();
    } else {
      return reader.readFloat64();
    }
  }

  @override
  double lerp(double from, double to, double f) => from + (to - from) * f;

  @override
  Uint8List serialize(double value) {
    if (((value * 10).roundToDouble() - (value * 10)).abs() == 0) {
      var w = BinaryWriter(alignment: 4);
      w.writeVarInt((value * 10).round());
      if (w.uint8Buffer.length < 4) {
        return w.uint8Buffer;
      }
    }
    BinaryWriter writer;
    if (max32Bit) {
      writer = BinaryWriter(alignment: 4);
      writer.writeFloat32(value);
      return writer.uint8Buffer;
    }
    var check = Float32List(1);
    check[0] = value;

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

  @override
  double runtimeDeserialize(BinaryReader reader) => reader.readFloat32();

  @override
  void runtimeSerialize(BinaryWriter writer, double value) {
    writer.writeFloat32(value);
  }
}
