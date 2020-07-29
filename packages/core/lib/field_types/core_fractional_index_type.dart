import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/field_types/core_field_type.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

class CoreFractionalIndexType extends CoreFieldType<FractionalIndex> {
  @override
  FractionalIndex deserialize(BinaryReader reader) {
    var numerator = reader.readVarInt();
    var denominator = reader.readVarInt();
    return FractionalIndex(numerator, denominator);
  }

  @override
  FractionalIndex lerp(FractionalIndex from, FractionalIndex to, double f) =>
      from;

  @override
  Uint8List serialize(FractionalIndex value) {
    var writer = BinaryWriter(alignment: 8);
    writer.writeVarInt(value.numerator);
    writer.writeVarInt(value.denominator);
    return writer.uint8Buffer;
  }

  @override
  FractionalIndex runtimeDeserialize(BinaryReader reader) =>
      throw UnimplementedError();

  @override
  void runtimeSerialize(BinaryWriter writer, FractionalIndex value) {
    throw UnimplementedError();
  }
}
