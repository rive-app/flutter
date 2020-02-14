import '../field_type.dart';

class BoolFieldType extends FieldType {
  BoolFieldType() : super("bool");

  @override
  String encode(String writerName, String varName) {
    return '$writerName.writeInt8($varName ? 1 : 0);';
  }

  @override
  String decode(String readerName, String varName) {
    return 'var $varName = $readerName.readInt8() == 1;';
  }

  @override
  int get encodingAlignment => 1;
}
