import 'package:core_generator/src/field_type.dart';

class IdFieldType extends FieldType {
  IdFieldType() : super('Id', import: 'package:core/id.dart');

  @override
  String encode(String writerName, String varName) {
    return '$varName.serialize($writerName);';
  }

  @override
  String decode(String readerName, String varName) {
    return 'var $varName = Id.deserialize($readerName);';
  }

  @override
  int get encodingAlignment => 4;
}
