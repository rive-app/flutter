import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:core/coop/player.dart';
import 'package:core/coop/player_cursor.dart';

import 'change.dart';
import 'coop_command.dart';

abstract class CoopReader {
  void read(Uint8List data) {
    var reader = BinaryReader(
        ByteData.view(data.buffer, data.offsetInBytes, data.length));
    int command = reader.readVarUint();
    switch (command) {
      case CoopCommand.hello:
        recvHello(reader.readVarUint());
        break;
      case CoopCommand.accept:
        var changeId = reader.readVarUint();
        recvAccept(changeId);
        break;
      case CoopCommand.reject:
        var changeId = reader.readVarUint();
        recvReject(changeId);
        break;
      case CoopCommand.wipe:
        recvWipe();
        break;
      case CoopCommand.synchronize:
        var changes = <ChangeSet>[];
        while (!reader.isEOF) {
          changes.add(ChangeSet()..deserialize(reader));
        }
        recvSync(changes);
        break;
      case CoopCommand.goodbye:
        recvGoodbye();
        break;
      case CoopCommand.cursor:
        recvCursor(reader.readFloat32(), reader.readFloat32());
        break;
      case CoopCommand.cursors:
        int length = reader.readVarUint();

        Map<int, PlayerCursor> cursors = {};
        for (int i = 0; i < length; i++) {
          int clientId = reader.readVarUint();
          cursors[clientId] = PlayerCursor.deserialize(reader);
        }
        recvCursors(cursors);
        break;
      case CoopCommand.ids:
        var min = reader.readVarUint();
        var max = reader.readVarUint();
        recvIds(min, max);
        break;
      case CoopCommand.ready:
        recvReady();
        break;
      case CoopCommand.players:
        int length = reader.readVarUint();
        List<Player> players = List<Player>(length);
        for (int i = 0; i < length; i++) {
          players[i] = Player.deserialize(reader);
        }
        recvPlayers(players);

        break;
      default:
        recvChange(ChangeSet()..deserialize(reader, command));
        break;
    }
  }

  Future<void> recvAccept(int changeId);
  Future<void> recvReject(int changeId);
  void recvChange(ChangeSet changes);
  Future<void> recvReady();
  Future<void> recvHello(int clientId);
  Future<void> recvGoodbye();
  Future<void> recvSync(List<ChangeSet> changes);
  Future<void> recvWipe();
  Future<void> recvIds(int min, int max);
  Future<void> recvPlayers(List<Player> players);
  Future<void> recvCursor(double x, double y);
  Future<void> recvCursors(Map<int, PlayerCursor> cursors);
}
