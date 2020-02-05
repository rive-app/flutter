import 'dart:typed_data';

import 'package:binary_buffer/binary_writer.dart';

import 'change.dart';
import 'coop_command.dart';

typedef Write = void Function(Uint8List buffer);

class CoopWriter {
  final Write write;
  CoopWriter(this.write);

  void writeHello() {
    var writer = BinaryWriter(alignment: 1);
    writer.writeVarUint(CoopCommand.hello);
    write(writer.uint8Buffer);
  }

  void writeReady() {
    var writer = BinaryWriter();
    writer.writeVarUint(CoopCommand.ready);
    write(writer.uint8Buffer);
  }

  void writeCursor(int x, int y) {
    var writer = BinaryWriter();
    writer.writeVarUint(CoopCommand.cursor);
    writer.writeVarInt(x);
    writer.writeVarInt(y);
    write(writer.uint8Buffer);
  }

  void writeGoodbye() {
    var writer = BinaryWriter(alignment: 1);
    writer.writeVarUint(CoopCommand.goodbye);
    write(writer.uint8Buffer);
  }

  void writeWipe() {
    var writer = BinaryWriter(alignment: 1);
    writer.writeVarUint(CoopCommand.wipe);
    write(writer.uint8Buffer);
  }

  void writeChanges(ChangeSet changes) {
    var writer = BinaryWriter();
    changes.serialize(writer);
    write(writer.uint8Buffer);
  }

  void writeSync() {
    var writer = BinaryWriter(alignment: 1);
    writer.writeVarUint(CoopCommand.synchronize);
    write(writer.uint8Buffer);
  }

  void writeAccept(int changeId, int serverChangeId) {
    var writer = BinaryWriter(alignment: 8);
    writer.writeVarUint(CoopCommand.accept);
    writer.writeVarUint(changeId);
    writer.writeVarUint(serverChangeId);
    write(writer.uint8Buffer);
  }

  void writeReject(int changeId) {
    var writer = BinaryWriter(alignment: 8);
    writer.writeVarUint(CoopCommand.reject);
    writer.writeVarUint(changeId);
    write(writer.uint8Buffer);
  }

  /// Upgrade an object id from a signed (local) to an unsigned (server) one.
  void writeChangeId(int fromId, int toId) {
    var writer = BinaryWriter(alignment: 8);
    writer.writeVarUint(CoopCommand.changeId);
    writer.writeVarInt(fromId);
    writer.writeVarUint(toId);
    write(writer.uint8Buffer);
  }
}
