import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';

import 'change.dart';
import 'coop_command.dart';

abstract class CoopReader {
  void read(Uint8List data) {
    var reader = BinaryReader(
        ByteData.view(data.buffer, data.offsetInBytes, data.length));
    int command = reader.readVarUint();
    print("COMMAND IS $command");
    switch (command) {
      case CoopCommand.hello:
        recvHello();
        break;
      case CoopCommand.accept:
        var changeId = reader.readVarUint();
        var serverChangeId = reader.readVarUint();
        recvAccept(changeId, serverChangeId);
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
        break;
      case CoopCommand.changeId:
        var fromId = reader.readVarInt();
        var toId = reader.readVarUint();
        recvChangeId(fromId, toId);
        break;
      case CoopCommand.ready:
        recvReady();
        break;
      default:
        recvChange(ChangeSet()..deserialize(reader, command));
        break;
    }
  }

  Future<void> recvAccept(int changeId, int serverChangeId);
  Future<void> recvReject(int changeId);
  void recvChange(ChangeSet changes);
  Future<void> recvReady();
  Future<void> recvHello();
  Future<void> recvGoodbye();
  Future<void> recvSync(List<ChangeSet> changes);
  Future<void> recvWipe();
  Future<void> recvChangeId(int from, int to);
}
