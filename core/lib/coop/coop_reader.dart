import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';

import 'change.dart';
import 'coop_command.dart';

abstract class CoopReader {
  void read(Uint8List data) {
    print("GOT READER DATA $data");
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
      case CoopCommand.hand:
        var session = reader.readVarUint();
        var fileId = reader.readString();
        var token = reader.readString();
        var lastServerChangeId = reader.readVarUint();
        recvHand(session, fileId, token, lastServerChangeId);
        break;
      case CoopCommand.shake:
        var session = reader.readVarUint();
        var lastSeenChangeId = reader.readVarUint();
        recvShake(session, lastSeenChangeId);
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
      default:
        recvChange(ChangeSet()..deserialize(reader, command));
        break;
    }
  }

  Future<void> recvAccept(int changeId, int serverChangeId);
  Future<void> recvReject(int changeId);
  Future<void> recvChange(ChangeSet changes);
  Future<void> recvHello();
  Future<void> recvGoodbye();
  Future<void> recvHand(
      int session, String fileId, String token, int lastServerChangeId);
  Future<void> recvShake(int session, int lastSeenChangeId);
  Future<void> recvChangeId(int from, int to);
}
