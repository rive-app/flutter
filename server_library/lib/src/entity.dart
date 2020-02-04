
import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';


/// An item in the file that has a pre-known (on client) key to resolve it.
/// Entities are stored with the session id that owns it and the server change
/// id associated with creation/change.
class Entity {
  /// Represents the kind of entity this is.
  int key;

  /// The client's session id.
  int userId;

  /// The serverside change id that created or changed this entity.
  int serverChangeId;

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(key);
    writer.writeVarUint(userId);
    writer.writeVarUint(serverChangeId);
  }

  void deserialize(BinaryReader reader) {
    key = reader.readVarUint();
    userId = reader.readVarUint();
    serverChangeId = reader.readVarUint();
  }

  void copy(Entity other) {
    key = other.key;
    userId = other.userId;
    serverChangeId = other.serverChangeId;
  }
}
