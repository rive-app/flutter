import '../field_type.dart';

class DoubleFieldType extends FieldType {
  DoubleFieldType() : super("double");

  @override
  String encode(String writerName, String varName) {
    return '$writerName.writeFloat64($varName)';
  }

  @override
  String decode(String readerName) {
    return '$readerName.readFloat64()';
  }

  @override
  int get encodingAlignment => 8;
}
