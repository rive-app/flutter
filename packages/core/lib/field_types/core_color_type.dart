import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreColorType extends CoreFieldType<int> {
  @override
  int deserialize(BinaryReader reader) => reader.readVarUint();

  @override
  int lerp(int from, int to, double f) => (from + (to - from) * f).round();

  @override
  Uint8List serialize(int value) {
    var writer = BinaryWriter(alignment: 4);
    writer.writeVarUint(value);
    return writer.uint8Buffer;
  }

  @override
  int runtimeDeserialize(BinaryReader reader) => reader.readUint32();

  @override
  void runtimeSerialize(BinaryWriter writer, int value) {
    writer.writeUint32(value);
  }
}
