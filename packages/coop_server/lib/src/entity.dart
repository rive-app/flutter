import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';

/// An item in the file that has a pre-known (on client) key to resolve it.
class Entity {
  /// Represents the kind of entity this is.
  int key;

  void serialize(BinaryWriter writer) => writer.writeVarUint(key);

  void deserialize(BinaryReader reader) => key = reader.readVarUint();

  void copy(Entity other) => key = other.key;
}
