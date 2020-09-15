import 'dart:collection';
import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class CoreFieldType<T> {
  T deserialize(BinaryReader reader);
  Uint8List serialize(T value);

  T runtimeDeserialize(BinaryReader reader);
  void runtimeSerialize(BinaryWriter writer, T value);
  void writeRuntimeProperty(int propertyKey, BinaryWriter writer, T value,
      HashMap<int, CoreFieldType> propertyToField) {
    propertyToField[propertyKey] = this;
    writer.writeVarUint(propertyKey);
    runtimeSerialize(writer, value);
  }

  T lerp(T from, T to, double f);
}
