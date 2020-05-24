import 'dart:typed_data';

import 'package:core/field_types/core_field_type.dart';
import 'package:core/id.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreListIdType extends CoreFieldType<List<Id>> {
  @override
  List<Id> deserialize(BinaryReader reader) {
    var value = List<Id>(reader.readVarUint());
    for (int i = 0; i < value.length; i++) {
      int client = reader.readVarUint();
      int object = reader.readVarUint();
      value[i] = Id(client, object);
    }
    return value;
  }

  @override
  List<Id> lerp(List<Id> from, List<Id> to, double f) => from;

  @override
  Uint8List serialize(List<Id> value) {
    var writer = BinaryWriter(alignment: 8 * value.length);
    write(writer, value);
    return writer.uint8Buffer;
  }

  @override
  void write(BinaryWriter writer, List<Id> value) {
    writer.writeVarUint(value.length);
    for (final id in value) {
      writer.writeVarUint(id.client);
      writer.writeVarUint(id.object);
    }
  }
}
