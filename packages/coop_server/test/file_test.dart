import 'dart:typed_data';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

import 'package:core/coop/coop_file.dart';
import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  test('ObjectProperties can be created', () {
    final prop = ObjectProperty()
      ..key = 1
      ..data = Uint8List.fromList([1, 2, 3]);
    expect(prop.key, 1);
    expect(prop.data, Uint8List.fromList([1, 2, 3]));
  });

  test('CoopFileObjects can be created', () {
    final obj = CoopFileObject()
      ..key = 1
      ..objectId = const Id(3, 4)
      ..properties = {
        5: ObjectProperty()
          ..key = 1
          ..data = Uint8List.fromList(
            [1, 2, 3],
          ),
      };
    expect(obj.key, 1);
    expect(obj.objectId, const Id(3, 4));
    expect(obj.properties.keys, [5]);
  });

  test('CoopFiles can be created', () {
    final file = CoopFile()
      ..fileId = 10
      ..serverChangeId = 0
      ..objects = {
        const Id(1, 12): CoopFileObject()
          ..key = 1
          ..objectId = const Id(3, 4)
          ..properties = {
            5: ObjectProperty()
              ..key = 1
              ..data = Uint8List.fromList(
                [1, 2, 3],
              ),
          }
      };
    expect(file.fileId, 10);
    expect(file.objects.length, 1);
    expect(file.objects.keys, [const Id(1, 12)]);
  });

  test('serialize file', () {
    var file = CoopFile()
      ..fileId = 82
      ..serverChangeId = 31
      ..objects = {
        const Id(1, 7): CoopFileObject()
          ..key = 3
          ..objectId = const Id(1, 7)
          ..properties = {
            12: ObjectProperty()
              ..key = 12
              ..data = Uint8List.fromList([1, 1, 1760]),
          },
        const Id(1, 31): CoopFileObject()
          ..key = 6
          ..objectId = const Id(1, 31)
          ..properties = {},
      };

    final writer = BinaryWriter();
    file.serialize(writer);

    var reader = BinaryReader(writer.buffer);
    var check = CoopFile()..deserialize(reader);

    expect(file.fileId, check.fileId);
    expect(file.serverChangeId, 31);
    expect(file.objects.length, check.objects.length);
    expect(file.objects[const Id(1, 7)] != null, true);
    expect(file.objects[const Id(1, 7)].key, 3);
    expect(file.objects[const Id(1, 7)].objectId, const Id(1, 7));
    expect(file.objects[const Id(1, 7)].properties.length, 1);
    expect(file.objects[const Id(1, 7)].properties[12].key, 12);
    expect(
      file.objects[const Id(1, 7)].properties[12].data,
      Uint8List.fromList([1, 1, 1760]),
    );
    expect(file.objects[const Id(1, 31)] != null, true);
    expect(file.objects[const Id(1, 31)].key, 6);
    expect(file.objects[const Id(1, 31)].objectId, const Id(1, 31));
    expect(file.objects[const Id(1, 31)].properties.length, 0);
  });

  /*
  test('File serialize/deserialize is performant', () {
    var file = CoopFile()
      ..ownerId = 19
      ..fileId = 82
      ..serverChangeId = 0
      ..objects = {};

    // simulate a complex file with 10,000 objects.
    for (int i = 0; i < 10000; i++) {
      var obj = CoopFileObject()
        ..key = i
        ..objectId = const Id(1, 343);
      file.objects[Id(1, i)] = obj;
      for (int j = 0; j < 30; j++) {
        obj.addProperty(
          ObjectProperty()
            ..key = 12
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
    expect(watch.elapsedMicroseconds * 1e-6 < 0.2, true);
    watch.reset();

    var reader = BinaryReader(writer.buffer);
    CoopFile().deserialize(reader);
    // expect deserialization to complete in less than 1/10th of a second
    expect(watch.elapsedMicroseconds * 1e-6 < 0.1, true);
    watch.reset();

    file.clone();
    expect(watch.elapsedMicroseconds * 1e-6 < 0.1, true);
  });
  */
}
