import '../field_type.dart';

class StringFieldType extends FieldType {
  StringFieldType() : super("String");

  @override
  String encode(String writerName, String varName) {
    return '$writerName.writeString($varName);';
  }

  @override
  String decode(String readerName, String varName) {
    return 'var $varName = $readerName.readString();';
  }

  @override
  int get encodingAlignment => 32;
}
