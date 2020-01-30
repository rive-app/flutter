import '../field_type.dart';

class IntListFieldType extends FieldType {
  IntListFieldType() : super("List<int>");

  @override
  String encode(String writerName, String varName) {
    return '$writerName.writeIntList($varName);';
  }

  @override
  String decode(String readerName, String varName) {
    return 'var $varName = $readerName.readIntList();';
  }

  @override
  int get encodingAlignment => 8;

  @override
  String equalityCheck(String varAName, String varBName) {
    return "listEquals($varAName, $varBName)";
  }
}
