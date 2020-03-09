import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import 'package:core/id.dart';
import "package:test/test.dart";

void main() {
  test('change', () {
    var writer = BinaryWriter();
    {
      var changeSet = ChangeSet()
        ..id = 42
        ..objects = [
          ObjectChanges()
            ..objectId = const Id(1, 222)
            ..changes = [
              Change()
                ..op = 10
                ..value = Uint8List.fromList([7, 31, 1982]),
            ],
          ObjectChanges()
            ..objectId = const Id(1, 1)
            ..changes = [
              Change()
                ..op = 1
                ..value = Uint8List.fromList([10]),
            ],
        ];
      changeSet.serialize(writer);
    }

    var reader = BinaryReader(writer.buffer);
    {
      var changeSet = ChangeSet()..deserialize(reader);
      expect(changeSet.id, 42);
      expect(changeSet.objects.length, 2);

      expect(changeSet.objects[0].objectId, const Id(1, 222));
      expect(changeSet.objects[0].changes[0].op, 10);
      expect(changeSet.objects[0].changes[0].value,
          Uint8List.fromList([7, 31, 1982]));

      expect(changeSet.objects[1].objectId, const Id(1, 1));
      expect(changeSet.objects[1].changes[0].op, 1);
      expect(changeSet.objects[1].changes[0].value, Uint8List.fromList([10]));
    }
  });

  test('valid change ids', () {
    var changeSet = ChangeSet();
    expect(() => changeSet.id = 0, throwsA(isA<AssertionError>()));
    changeSet.id = 1982;
    expect(changeSet.id, 1982);
  });
}
