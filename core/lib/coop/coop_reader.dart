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
    switch (command) {
      case CoopCommand.hello:
        recvHello();
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
      default:
        recvChange(ChangeSet()..deserialize(reader, command));
        break;
    }
  }

  Future<void> recvChange(ChangeSet changes);
  Future<void> recvHello();
  Future<void> recvGoodbye();
  Future<void> recvHand(
      int session, String fileId, String token, int lastServerChangeId);
  Future<void> recvShake(int session, int lastSeenChangeId);
}
