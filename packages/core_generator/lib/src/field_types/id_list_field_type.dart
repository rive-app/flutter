import '../field_type.dart';

class IdListFieldType extends FieldType {
  IdListFieldType()
      : super(
          'List<Id>',
          'CoreListIdType',
        );

  @override
  String equalityCheck(String varAName, String varBName) {
    return 'listEquals($varAName, $varBName)';
  }
}
