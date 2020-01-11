import '../field_type.dart';

class IntFieldType extends FieldType {
  IntFieldType() : super("int");

  @override
  String encode(String writerName, String varName) {
    return '$writerName.writeVarInt($varName);';
  }

  @override
  String decode(String readerName, String varName) {
    return '$varName = $readerName.readVarInt();';
  }

  @override
  int get encodingAlignment => 4;
}
