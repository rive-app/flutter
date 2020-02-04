import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';

import 'change.dart';
import 'coop_command.dart';
import 'goodbye_reason.dart';

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
      case CoopCommand.hand:
        var token = reader.readString();
        recvHand(token);
        break;
      case CoopCommand.synchronize:
        recvSync();
        break;
      case CoopCommand.shake:
        recvShake();
        break;
      case CoopCommand.goodbye:
        recvGoodbye(GoodbyeReason.values[reader.readVarUint()]);
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
  Future<void> recvChange(ChangeSet changes);
  Future<void> recvReady();
  Future<void> recvHello();
  Future<void> recvGoodbye(GoodbyeReason reason);
  Future<void> recvHand(String token);
  Future<void> recvSync();
  Future<void> recvShake();
  Future<void> recvChangeId(int from, int to);
}
