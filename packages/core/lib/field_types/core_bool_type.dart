import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreBoolType extends CoreFieldType<bool> {
  @override
  bool deserialize(BinaryReader reader) => reader.readInt8() == 1;

  @override
  bool lerp(bool from, bool to, double f) => from;

  @override
  Uint8List serialize(bool value) {
    var writer = BinaryWriter(alignment: 1);
    writer.writeInt8(value ? 1 : 0);
    return writer.uint8Buffer;
  }
}
