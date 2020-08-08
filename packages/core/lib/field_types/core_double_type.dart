import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

// TODO: murder once all files are converter
int _readVarInt(BinaryReader reader) {
  var buffer = reader.buffer;
  int result = 0;
  int shift = 0;
  while (true) {
    int byte = buffer.getUint8(reader.readIndex);
    result |= (byte & 0x7f) << shift;
    shift += 7;
    if ((byte & 0x80) == 0) {
      break;
    } else {
      reader.readIndex++;
    }
  }
  if ((shift < 64) && (buffer.getUint8(reader.readIndex) & 0x40) != 0) {
    result |= ~0 << shift;
  }
  reader.readIndex += 1;
  return result;
}

class CoreDoubleType extends CoreFieldType<double> {
  static bool max32Bit = false;

  @override
  double deserialize(BinaryReader reader) {
    var length = reader.buffer.lengthInBytes;
    if (length < 4) {
      // TODO: catch this and force re-save this field.
      // Error condition where we were writing <3 bytes as varint, which isn't
      // compatible with flutter web. If we encounter this, don't crash but
      // return a 0 value.
      return _readVarInt(reader) / 10;
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
