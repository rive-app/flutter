import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreStringType extends CoreFieldType<String> {
  @override
  String deserialize(BinaryReader reader) => reader.readString();

  @override
  String lerp(String from, String to, double f) => from;

  @override
  Uint8List serialize(String value) {
    var writer = BinaryWriter(alignment: 32);
    write(writer, value);
    return writer.uint8Buffer;
  }

  @override
  void write(BinaryWriter writer, String value) {
    writer.writeString(value);
  }
}
