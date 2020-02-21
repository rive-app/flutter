import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';

/// This is a server and client abstraction of a player. A player represents a
/// client connected to the coop server which has been authenticated to
/// represent a specific user in the Rive backend. Because each user can have
/// multiple sessions, we disambiguate which session to target (for operations
/// like cursor movement) via the clientId.
class Player {
  /// Id representing the client session on the server.
  final int clientId;

  /// Id representing the owner in the Rive API.
  final int ownerId;

  Player(this.clientId, this.ownerId);

  void serialize(BinaryWriter writer) {
    writer.writeVarUint(clientId);
    writer.writeVarUint(ownerId);
  }

  factory Player.deserialize(BinaryReader reader) {
    int clientId = reader.readVarUint();
    int ownerId = reader.readVarUint();
    return Player(clientId, ownerId);
  }
}
