import '../serdes.dart';

class DoubleSerDes extends SerDes<double> {
  @override
  double deserializeJson(Object value) {
    return 0;
  }

  @override
  Object deserializeMemory(double value) {
    return value;
  }

  @override
  String serializeJson(double value) {
    return value.toString();
  }

  @override
  Object serializeMemory(double value) {
    return value;
  }
}