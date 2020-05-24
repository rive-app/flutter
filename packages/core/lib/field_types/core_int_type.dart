import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreIntType extends CoreFieldType<int> {
  @override
  int deserialize(BinaryReader reader) => reader.readVarInt();

  @override
  int lerp(int from, int to, double f) => (from + (to - from) * f).round();

  @override
  Uint8List serialize(int value) {
    var writer = BinaryWriter(alignment: 4);
    write(writer, value);
    return writer.uint8Buffer;
  }

  @override
  void write(BinaryWriter writer, int value) {
    writer.writeVarInt(value);
  }
}
