import 'dart:typed_data';
import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';

import 'package:coop_server_library/src/coop_file.dart';
import 'package:coop_server_library/src/session.dart';
import "package:test/test.dart";

void main() {
  test('serialize file', () {
    var file = CoopFile()
      ..ownerId = 19
      ..fileId = 82
      ..objects = {
        7: CoopFileObject()
          ..key = 3
          ..sessionId = 20
          ..serverChangeId = 1
          ..localId = 343
          ..properties = {
            12: ObjectProperty()
              ..key = 12
              ..sessionId = 653
              ..serverChangeId = 453
              ..data = Uint8List.fromList([1, 1, 1760]),
          },
        31: CoopFileObject()
          ..key = 6
          ..sessionId = 30
          ..serverChangeId = 2
          ..localId = 22
          ..properties = {},
      };

    var writer = BinaryWriter();
    file.serialize(writer);

    var reader = BinaryReader(writer.buffer);
    var check = CoopFile()..deserialize(reader);

    expect(file.ownerId, check.ownerId);
    expect(file.fileId, check.fileId);
    expect(file.objects.length, check.objects.length);
    expect(file.objects[7] != null, true);
    expect(file.objects[7].key, 3);
    expect(file.objects[7].sessionId, 20);
    expect(file.objects[7].serverChangeId, 1);
    expect(file.objects[7].localId, 343);
    expect(file.objects[7].properties.length, 1);
    expect(file.objects[7].properties[12].key, 12);
    expect(file.objects[7].properties[12].sessionId, 653);
    expect(file.objects[7].properties[12].serverChangeId, 453);
    expect(
        file.objects[7].properties[12].data, Uint8List.fromList([1, 1, 1760]));
    expect(file.objects[31] != null, true);
    expect(file.objects[31].key, 6);
    expect(file.objects[31].sessionId, 30);
    expect(file.objects[31].serverChangeId, 2);
    expect(file.objects[31].localId, 22);
    expect(file.objects[31].properties.length, 0);
  });

  test('serialize server data', () {
    var serverData = CoopFileServerData()
      ..sessions = [
        Session()
          ..changeId = 30
          ..id = 40
          ..userId = 666,
        Session()
          ..changeId = 32
          ..id = 42
          ..userId = 669
      ]
      ..nextChangeId = 2221
      ..nextObjectId = 1238293;
    var writer = BinaryWriter();
    serverData.serialize(writer);

    var reader = BinaryReader(writer.buffer);
    var check = CoopFileServerData()..deserialize(reader);
    expect(check.nextChangeId, serverData.nextChangeId);
    expect(check.nextObjectId, serverData.nextObjectId);
    expect(check.sessions.length, 2);
    expect(check.sessions[0].changeId, 30);
    expect(check.sessions[0].id, 40);
    expect(check.sessions[0].userId, 666);
    expect(check.sessions[1].changeId, 32);
    expect(check.sessions[1].id, 42);
    expect(check.sessions[1].userId, 669);
  });

  test('perf test file serialize/deserialize', () {
    var file = CoopFile()
      ..ownerId = 19
      ..fileId = 82
      ..objects = {};

    // simulate a complex file with 10,000 objects.
    for (int i = 0; i < 10000; i++) {
      var obj = CoopFileObject()
        ..key = i
        ..sessionId = 20
        ..serverChangeId = 1
        ..localId = 343;
      file.objects[i] = obj;
      for (int j = 0; j < 30; j++) {
        obj.addProperty(
          ObjectProperty()
            ..key = 12
            ..sessionId = 653
            ..serverChangeId = 453
            ..data = Uint8List.fromList(
                [1, 1, 1760, 1, 1, 1760, 1, 1, 1760, 1, 1, 1760]),
        );
      }
    }

    var watch = Stopwatch();
    watch.start();
    var writer = BinaryWriter(alignment: file.objects.length * 256);
    file.serialize(writer);
    // expect serialization to complete in less than 1/20th of a second
    print("Serialized in ${watch.elapsedMicroseconds * 1e-6}s");
    // expect(watch.elapsedMicroseconds * 1e-6 < 0.2, true);

    watch.reset();

    var reader = BinaryReader(writer.buffer);
    var check = CoopFile()..deserialize(reader);
    // expect deserialization to complete in less than 1/10th of a second
    // expect(watch.elapsedMicroseconds * 1e-6 < 0.1, true);
    print("Deserialized in ${watch.elapsedMicroseconds * 1e-6}s");

    watch.reset();
    var clone = file.clone();
    print("Cloned in ${watch.elapsedMicroseconds * 1e-6}s");
  });
}
