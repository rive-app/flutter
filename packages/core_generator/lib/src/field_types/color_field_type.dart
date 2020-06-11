import '../field_type.dart';

class ColorFieldType extends FieldType {
  ColorFieldType()
      : super(
          'Color',
          'CoreColorType',
          dartName: 'int',
        );

  @override
  String get defaultValue => '0';
}
