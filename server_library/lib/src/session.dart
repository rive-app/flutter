import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';


/// Repesents a unique client session. Sessions are longer lived than
/// connections and can be resumed. Users can have multiple sessions.
class Session {
  /// Unique session id.
  int id;

  /// Last received change id.
  int changeId;

  /// User id from the database.
  int userId;


  void serialize(BinaryWriter writer) {
    writer.writeVarUint(id);
    writer.writeVarUint(changeId);
    writer.writeVarUint(userId);
  }

  void deserialize(BinaryReader reader) {
    id = reader.readVarUint();
    changeId = reader.readVarUint();
    userId = reader.readVarUint();
  }
}