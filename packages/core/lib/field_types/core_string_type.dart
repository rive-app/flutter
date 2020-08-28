import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreStringType extends CoreFieldType<String> {
  @override
  String deserialize(BinaryReader reader) {
    return reader.readString(explicitLength: false);
  }

  @override
  String lerp(String from, String to, double f) => from;

  @override
  Uint8List serialize(String value) {
    var writer = BinaryWriter(alignment: value.length * 2);
    writer.writeString(value, explicitLength: false);
    return writer.uint8Buffer;
  }

  @override
  String runtimeDeserialize(BinaryReader reader) =>
      reader.readString(explicitLength: true);

  @override
  void runtimeSerialize(BinaryWriter writer, String value) =>
      writer.writeString(value, explicitLength: true);
}
