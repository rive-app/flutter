import 'package:core/annotations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/node.dart';
import 'package:core/serializer.dart';

class SerializeTest extends Serializer {
  @override
  void closeObject() {}

  @override
  void openObject(String name) {
    print("OPEN OBJECT $name");
  }

  @override
  void writeValue<T>(String name, T value) {
    print("WRITE PROPERTY $name: $value");
  }
}

void main() {
  test('node properties change', () {
    final node = Node();

    //core.add(Node());

    node.name = "hi!";

    // SerializeTest test = SerializeTest();
    // node.serialize(test);
    expect(node.name, "hi!");
  });
}
