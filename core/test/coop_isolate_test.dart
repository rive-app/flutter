import 'package:core/coop/coop_isolate.dart';
import "package:test/test.dart";

void main() {
  test('isolate', () async {
    var isolate = CoopIsolate();
    // expect(await isolate.spawn(), true);
    // var writer = BinaryWriter();
    // writer.writeFloat32(1.5);
    // writer.writeFloat32(3.1449999809265137);

    // var reader = BinaryReader(writer.buffer);
    // expect(reader.readFloat32(), 1.5);
    // expect(reader.readFloat32(), 3.1449999809265137);
  });
}
