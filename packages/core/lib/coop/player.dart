import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:core/coop/player_cursor.dart';
import 'package:meta/meta.dart';

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

  /// The player's cursor in world space.
  PlayerCursor _cursor;
  PlayerCursor get cursor => _cursor;
  set cursor(PlayerCursor value) {
    ;
    if (_cursor == value) {
      return;
    }
    _cursor = value;
    cursorChanged();
  }

  @protected
  void cursorChanged() {}

  Player(this.clientId, this.ownerId, {PlayerCursor cursor})
      : _cursor = cursor ?? PlayerCursor(0, 0);

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
