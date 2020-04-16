import 'package:core_generator/src/field_type.dart';

class FractionalIndexFieldType extends FieldType {
  FractionalIndexFieldType()
      : super(
          "FractionalIndex",
          'CoreFractionalIndexType',
          imports: [
            "package:fractional/fractional.dart",
          ],
        );
}
