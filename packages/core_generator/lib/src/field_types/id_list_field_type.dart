import '../field_type.dart';

class IdListFieldType extends FieldType {
  IdListFieldType()
      : super(
          'List<Id>',
          'CoreListIdType',
          imports: [
            'package:core/id.dart',
            'package:utilities/list_equality.dart',
          ],
        );

  @override
  String equalityCheck(String varAName, String varBName) {
    return 'listEquals($varAName, $varBName)';
  }
}
