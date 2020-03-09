import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:core/coop/player.dart';
import 'package:core/coop/player_cursor.dart';

import 'change.dart';
import 'coop_command.dart';

abstract class CoopReader {
  Future<void> read(Uint8List data) async {
    var reader = BinaryReader(
        ByteData.view(data.buffer, data.offsetInBytes, data.length));
    int command = reader.readVarUint();
    switch (command) {
      case CoopCommand.hello:
        await recvHello(reader.readVarUint());
        break;
      case CoopCommand.accept:
        var changeId = reader.readVarUint();
        await recvAccept(changeId);
        break;
      case CoopCommand.reject:
        var changeId = reader.readVarUint();
        await recvReject(changeId);
        break;
      case CoopCommand.wipe:
        await recvWipe();
        break;
      case CoopCommand.synchronize:
        var changes = <ChangeSet>[];
        while (!reader.isEOF) {
          changes.add(ChangeSet()..deserialize(reader));
        }
        await recvSync(changes);
        break;
      case CoopCommand.goodbye:
        await recvGoodbye();
        break;
      case CoopCommand.cursor:
        await recvCursor(reader.readFloat32(), reader.readFloat32());
        break;
      case CoopCommand.cursors:
        int length = reader.readVarUint();

        Map<int, PlayerCursor> cursors = {};
        for (int i = 0; i < length; i++) {
          int clientId = reader.readVarUint();
          cursors[clientId] = PlayerCursor.deserialize(reader);
        }
        await recvCursors(cursors);
        break;
      case CoopCommand.ready:
        await recvReady();
        break;
      case CoopCommand.players:
        int length = reader.readVarUint();
        List<Player> players = List<Player>(length);
        for (int i = 0; i < length; i++) {
          players[i] = Player.deserialize(reader);
        }
        await recvPlayers(players);

        break;
      case CoopCommand.ping:
        // do nothing with ping...
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
  Future<void> recvPlayers(List<Player> players);
  Future<void> recvCursor(double x, double y);
  Future<void> recvCursors(Map<int, PlayerCursor> cursors);
}
