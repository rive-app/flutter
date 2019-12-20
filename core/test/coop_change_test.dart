import 'dart:typed_data';

import 'package:binary_buffer/binary_reader.dart';
import 'package:binary_buffer/binary_writer.dart';
import 'package:core/coop/change.dart';
import "package:test/test.dart";

void main() {
  test('change', () {
    var writer = BinaryWriter();
    {
      var changeSet = ChangeSet()
        ..id = 42
        ..changes = [
          Change()
            ..op = 10
            ..objectId = 222
            ..value = Uint8List.fromList([7, 31, 1982]),
          Change()
            ..op = 1
            ..objectId = -1
            ..value = Uint8List.fromList([10])
        ];
      changeSet.serialize(writer);
    }

    var reader = BinaryReader(writer.buffer);
    {
      var changeSet = ChangeSet()..deserialize(reader);
      expect(changeSet.id, 42);
      expect(changeSet.changes.length, 2);
      expect(changeSet.changes[0].op, 10);
      expect(changeSet.changes[0].objectId, 222);
      expect(changeSet.changes[0].value, Uint8List.fromList([7, 31, 1982]));
      expect(changeSet.changes[1].op, 1);
      expect(changeSet.changes[1].objectId, -1);
      expect(changeSet.changes[1].value, Uint8List.fromList([10]));
    }
  });
}
