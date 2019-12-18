import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/rive_file.dart';

void main() {
  test('node properties change', () {
    final file = RiveFile();
    var node = file.add(Node());
    node.name = "hi!";
    file.remove(node);
    expect(node.name, "hi!");
  });
}
