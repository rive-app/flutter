import '../field_type.dart';

class FractionalIndexFieldType extends FieldType {
  FractionalIndexFieldType() : super("FractionalIndex");

  @override
  String encode(String writerName, String varName) {
    return '''$writerName.writeVarInt($varName.numerator);
              $writerName.writeVarInt($varName.denominator);''';
  }

  @override
  String decode(String readerName, String varName) {
    return '''var numerator = $readerName.readVarInt();
              var denominator = $readerName.readVarInt();
              $varName = FractionalIndex(numerator, denominator);''';
  }

  @override
  int get encodingAlignment => 8;
}
