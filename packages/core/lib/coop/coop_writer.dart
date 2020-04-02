import 'dart:math';
import 'dart:typed_data';

import 'package:utilities/binary_buffer/binary_writer.dart';

import 'change.dart';
import 'coop_command.dart';
import 'coop_server_client.dart';

typedef Write = void Function(Uint8List buffer);

class CoopWriter {
  final Write write;
  CoopWriter(this.write);

  void writeHello(int clientId) {
    var writer = BinaryWriter(alignment: 4);
    writer.writeVarUint(CoopCommand.hello);
    writer.writeVarUint(clientId);
    write(writer.uint8Buffer);
  }

  void writeReady() {
    var writer = BinaryWriter();
    writer.writeVarUint(CoopCommand.ready);
    write(writer.uint8Buffer);
  }

  void writeCursor(double x, double y) {
    var writer = BinaryWriter();
    writer.writeVarUint(CoopCommand.cursor);
    writer.writeFloat32(x);
    writer.writeFloat32(y);
    write(writer.uint8Buffer);
  }

  void writePing() {
    var writer = BinaryWriter();
    writer.writeVarUint(CoopCommand.ping);
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

  void writeSync(List<ChangeSet> changes) {
    var writer = BinaryWriter(alignment: max(1, changes.length * 16));
    writer.writeVarUint(CoopCommand.synchronize);
    for (final change in changes) {
      change.serialize(writer);
    }
    write(writer.uint8Buffer);
  }

  void writeAccept(int changeId) {
    var writer = BinaryWriter(alignment: 8);
    writer.writeVarUint(CoopCommand.accept);
    writer.writeVarUint(changeId);
    write(writer.uint8Buffer);
  }

  void writeReject(int changeId) {
    var writer = BinaryWriter(alignment: 8);
    writer.writeVarUint(CoopCommand.reject);
    writer.writeVarUint(changeId);
    write(writer.uint8Buffer);
  }

  void writePlayers(Iterable<CoopServerClient> clients) {
    // TODO: nicer way to optimize alignment?
    var writer = BinaryWriter(alignment: 4 + 8 * clients.length);
    writer.writeVarUint(CoopCommand.players);
    writer.writeVarUint(clients.length);
    for (final client in clients) {
      client.serialize(writer);
    }
    write(writer.uint8Buffer);
  }

  void writeCursors(Iterable<CoopServerClient> clientCursors) {
    var writer = BinaryWriter(alignment: 4 + 8 * clientCursors.length);
    writer.writeVarUint(CoopCommand.cursors);
    writer.writeVarUint(clientCursors.length);
    for (final client in clientCursors) {
      writer.writeVarUint(client.clientId);
      client.cursor.serialize(writer);
    }
    write(writer.uint8Buffer);
  }
}
