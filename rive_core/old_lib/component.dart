import 'src/metadata.dart';

part 'component.g.dart';

@CoreType()
abstract class ComponentBase extends ConcreteCore {
  @CoreProperty()
  String _name;

  void _nameChanged(String from, String to) {
    print("Name changed $from $to");
  }
}
