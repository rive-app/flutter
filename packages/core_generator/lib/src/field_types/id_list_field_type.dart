import '../field_type.dart';

class IdListFieldType extends FieldType {
  IdListFieldType()
      : super('List<Id>', imports: [
          'package:core/id.dart',
          'package:utilities/list_equality.dart',
        ]);

  @override
  String encode(String writerName, String varName) {
    return '''$writerName.writeVarUint($varName.length);
      for(final id in $varName) { id.serialize($writerName); }''';
  }

  // TODO: do we really want these to be growable?
  @override
  String decode(String readerName, String varName) {
    return '''var $varName = List<Id>($readerName.readVarUint());
      for(int i = 0; i < $varName.length; i++) {
        $varName[i] = Id.deserialize($readerName);
      }''';
  }

  @override
  int get encodingAlignment => 8;

  @override
  String equalityCheck(String varAName, String varBName) {
    return 'listEquals($varAName, $varBName)';
  }
}
