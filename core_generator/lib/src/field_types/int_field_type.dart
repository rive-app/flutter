import '../field_type.dart';

class IntFieldType extends FieldType {
  IntFieldType({String name = 'int'}) : super(name, dartName: 'int');

  @override
  String encode(String writerName, String varName) {
    return '$writerName.writeVarInt($varName);';
  }

  @override
  String decode(String readerName, String varName) {
    return 'var $varName = $readerName.readVarInt();';
  }

  @override
  int get encodingAlignment => 4;
}
